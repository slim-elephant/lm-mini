// C ABI for the iOS MoE expert-stream engine (BigMoeOnEdge).
// Swift talks only to this header. Implementation is in moe_stream_engine.mm.
#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*MoeStreamTokenCb)(const char *piece, void *user);

/// 1 if this binary was linked with BigMoeOnEdge (`LM_MINI_HAS_BMOE`).
bool moe_stream_available(void);

/// Load (or reload) a GGUF MoE. Returns 0 on success; writes a message to
/// `err` on failure. `cache_mb` 0 means auto-size with a 2048 MiB ceiling.
int moe_stream_open(const char *model_path,
                    int n_ctx,
                    int n_threads,
                    int cache_mb,
                    char *err,
                    int err_len);

/// Greedy-or-sampled generate. `prompt` is already chat-formatted.
/// Invokes `on_token` on the calling thread for each piece. Returns 0 on
/// success (including user cancel).
int moe_stream_generate(const char *prompt,
                        int max_tokens,
                        float temperature,
                        float top_p,
                        MoeStreamTokenCb on_token,
                        void *user,
                        char *err,
                        int err_len);

void moe_stream_cancel(void);
void moe_stream_close(void);

#ifdef __cplusplus
}
#endif
