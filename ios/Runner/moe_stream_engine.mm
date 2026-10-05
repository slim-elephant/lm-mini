// Optional BigMoeOnEdge adapter. Compiles as a stub unless
// `ios/scripts/fetch_and_build_bmoe.sh` wrote Flutter/bmoe.xcconfig
// (defines LM_MINI_HAS_BMOE and links libbmoe_core).
#import "moe_stream_c_api.h"
#import <TargetConditionals.h>
#if TARGET_OS_SIMULATOR
#undef LM_MINI_HAS_BMOE
#endif

#include <algorithm>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>

#if defined(LM_MINI_HAS_BMOE)
#include "bmoe/config.h"
#include "bmoe/session.h"
#include "ggml-blas.h"
#include "llama.h"

#include <cerrno>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#endif

namespace {

std::mutex g_mu;

#if defined(LM_MINI_HAS_BMOE)
std::unique_ptr<bmoe::Session> g_session;
#endif

void set_err(char *err, int err_len, const std::string &msg) {
  if (err == nullptr || err_len <= 0) return;
  const auto n = std::min(static_cast<int>(msg.size()), err_len - 1);
  memcpy(err, msg.data(), static_cast<size_t>(n));
  err[n] = '\0';
}

#if defined(LM_MINI_HAS_BMOE)
struct LlamaLogBuf {
  std::string acc;
  void append(const char *text) {
    if (text == nullptr || text[0] == '\0') return;
    acc.append(text);
    if (acc.size() > 3500) acc.erase(0, acc.size() - 2500);
  }
};

void llama_log_cb(enum ggml_log_level level, const char *text, void *user) {
  auto *buf = static_cast<LlamaLogBuf *>(user);
  if (buf != nullptr &&
      (level == GGML_LOG_LEVEL_ERROR || level == GGML_LOG_LEVEL_WARN)) {
    buf->append(text);
  }
  if (text != nullptr) fputs(text, stderr);
}

std::string trim_copy(std::string s) {
  while (!s.empty() && (s.back() == '\n' || s.back() == '\r' || s.back() == ' ')) {
    s.pop_back();
  }
  return s;
}

// Reject HTML/LFS-pointer downloads and prove iOS can MAP_SHARED the file
// before llama.cpp tries (its error is only "failed to load model: <path>").
bool preflight_gguf(const char *path, std::string &error) {
  struct stat st {};
  if (stat(path, &st) != 0) {
    error = std::string("Cannot stat GGUF: ") + strerror(errno);
    return false;
  }
  if (!S_ISREG(st.st_mode)) {
    error = "Model path is not a regular file.";
    return false;
  }
  const auto bytes = static_cast<uint64_t>(st.st_size);
  if (bytes < 64) {
    error = "GGUF is only " + std::to_string(bytes) +
            " bytes — download looks empty or was an LFS pointer.";
    return false;
  }

  const int fd = open(path, O_RDONLY);
  if (fd < 0) {
    error = std::string("Cannot open GGUF: ") + strerror(errno);
    return false;
  }
  char magic[4] = {};
  const ssize_t nread = read(fd, magic, 4);
  if (nread != 4 || std::memcmp(magic, "GGUF", 4) != 0) {
    close(fd);
    error = "File is not a GGUF (missing magic). Re-download the stream model.";
    return false;
  }

  // Map one page only. Mapping the full ~18 GB here can jetsam the process
  // before llama.cpp runs; llama.cpp still maps the whole file at load.
  const size_t probe = 4096;
  void *mapped = mmap(nullptr, probe, PROT_READ, MAP_SHARED, fd, 0);
  close(fd);
  if (mapped == MAP_FAILED) {
    error = std::string("iOS refused to memory-map the GGUF (") + strerror(errno) + ").";
    return false;
  }
  munmap(mapped, probe);

  // Catalog target is ~18.5 GB. Anything under ~8 GB is almost certainly truncated.
  if (bytes < 8ull * 1024ull * 1024ull * 1024ull) {
    error = "GGUF is only " + std::to_string(bytes / (1024ull * 1024ull)) +
            " MB; Qwen3-30B-A3B Q4_K_M should be ~18 GB. Re-download it.";
    return false;
  }
  return true;
}

void ensure_cpu_backend() {
  llama_backend_init();
  if (ggml_backend_reg_count() > 0) return;
  ggml_backend_register(ggml_backend_cpu_reg());
  ggml_backend_register(ggml_backend_blas_reg());
}
#endif

} // namespace

extern "C" bool moe_stream_available(void) {
#if defined(LM_MINI_HAS_BMOE)
  return true;
#else
  return false;
#endif
}

extern "C" int moe_stream_open(const char *model_path,
                               int n_ctx,
                               int n_threads,
                               int cache_mb,
                               char *err,
                               int err_len) {
#if !defined(LM_MINI_HAS_BMOE)
  set_err(err, err_len,
          "MoE stream engine is not linked. On a Mac with Xcode, run "
          "ios/scripts/fetch_and_build_bmoe.sh then rebuild the iOS app.");
  return 1;
#else
  if (model_path == nullptr || model_path[0] == '\0') {
    set_err(err, err_len, "Missing GGUF path.");
    return 1;
  }

  std::string preflight_error;
  if (!preflight_gguf(model_path, preflight_error)) {
    set_err(err, err_len, preflight_error);
    return 1;
  }

  std::lock_guard<std::mutex> lock(g_mu);
  g_session.reset();

  LlamaLogBuf logs;
  llama_log_set(llama_log_cb, &logs);
  ensure_cpu_backend();
  if (ggml_backend_reg_count() == 0) {
    llama_log_set(nullptr, nullptr);
    set_err(err, err_len,
            "llama.cpp CPU backend did not register. Rebuild after "
            "ios/scripts/fetch_and_build_bmoe.sh.");
    return 1;
  }

  bmoe::SessionConfig cfg;
  cfg.model_path = model_path;
  cfg.n_threads = n_threads > 0 ? n_threads : 4;
  // Keep compute buffers small: they compete with the expert cache on 8 GB phones.
  cfg.n_ctx = n_ctx > 0 ? std::min(n_ctx, 2048) : 2048;
  cfg.n_batch = 512;
  cfg.n_ubatch = 256;
  cfg.chatml = false;
  cfg.moe.enabled = true;
  cfg.moe.o_direct = false; // iOS/APFS does not support O_DIRECT
  cfg.moe.overlap = false;
  cfg.moe.io_threads = 2;
  // Warmed page-faults the dense set at load and can jetsam an 8 GB iPhone.
  cfg.moe.dense_weights = bmoe::DenseWeightsMode::Mmap;
  if (cache_mb > 0) {
    cfg.moe.cache_mb = cache_mb;
  } else {
    cfg.moe.cache_auto = true;
    cfg.moe.cache_floor_mb = 2048;
    cfg.moe.cache_ceil_mb = 1536;
  }

  std::string error;
  g_session = bmoe::Session::open(cfg, error);
  llama_log_set(nullptr, nullptr);
  if (!g_session) {
    std::string msg = error.empty() ? "Failed to open MoE stream session." : error;
    const std::string llama = trim_copy(logs.acc);
    if (!llama.empty()) {
      msg.append(" | ");
      msg.append(llama);
    }
    set_err(err, err_len, msg);
    return 1;
  }
  return 0;
#endif
}

extern "C" int moe_stream_generate(const char *prompt,
                                   int max_tokens,
                                   float temperature,
                                   float top_p,
                                   MoeStreamTokenCb on_token,
                                   void *user,
                                   char *err,
                                   int err_len) {
#if !defined(LM_MINI_HAS_BMOE)
  set_err(err, err_len, "MoE stream engine is not linked.");
  return 1;
#else
  bmoe::Session *session = nullptr;
  {
    std::lock_guard<std::mutex> lock(g_mu);
    session = g_session.get();
  }
  if (session == nullptr) {
    set_err(err, err_len, "Call load() before generate().");
    return 1;
  }

  bmoe::GenerateRequest req;
  req.prompt = prompt ? prompt : "";
  req.n_predict = max_tokens > 0 ? max_tokens : 128;
  req.think = true;
  req.clear_kv = true;
  req.render_text = false;

  // Sampling is fixed at Session::open. Temperature from Mini is best-effort
  // for this spike (session was opened greedy). Non-zero temp still generates.
  (void)temperature;
  (void)top_p;

  const auto result = session->generate(
      req, [on_token, user](const bmoe::TokenMetrics &tm) {
        if (on_token == nullptr) return;
        if (!tm.piece.empty()) {
          on_token(tm.piece.c_str(), user);
        }
      });
  if (!result.ok) {
    set_err(err, err_len,
            result.error.empty() ? "MoE generate failed." : result.error);
    return 1;
  }
  return 0;
#endif
}

extern "C" void moe_stream_cancel(void) {
#if defined(LM_MINI_HAS_BMOE)
  std::lock_guard<std::mutex> lock(g_mu);
  if (g_session) g_session->cancel();
#endif
}

extern "C" void moe_stream_close(void) {
#if defined(LM_MINI_HAS_BMOE)
  std::lock_guard<std::mutex> lock(g_mu);
  g_session.reset();
#endif
}
