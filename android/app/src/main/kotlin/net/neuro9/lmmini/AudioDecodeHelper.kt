package net.neuro9.lmmini

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder

object AudioDecodeHelper {
    /**
     * Decodes any supported audio file to 16-bit PCM mono WAV at [targetSampleRate].
     */
    @Throws(IOException::class)
    fun convertToWav(sourcePath: String, outputPath: String, targetSampleRate: Int): String {
        val extractor = MediaExtractor()
        extractor.setDataSource(sourcePath)

        var audioTrack = -1
        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith("audio/")) {
                audioTrack = i
                break
            }
        }
        if (audioTrack < 0) {
            extractor.release()
            throw IOException("No audio track in $sourcePath")
        }

        extractor.selectTrack(audioTrack)
        val inputFormat = extractor.getTrackFormat(audioTrack)
        val mime = inputFormat.getString(MediaFormat.KEY_MIME)
            ?: throw IOException("Missing MIME type")

        val codec = MediaCodec.createDecoderByType(mime)
        codec.configure(inputFormat, null, null, 0)
        codec.start()

        val pcm = ArrayList<Short>()
        val bufferInfo = MediaCodec.BufferInfo()
        var inputDone = false

        while (true) {
            if (!inputDone) {
                val inputIndex = codec.dequeueInputBuffer(10_000)
                if (inputIndex >= 0) {
                    val inputBuffer = codec.getInputBuffer(inputIndex)!!
                    val sampleSize = extractor.readSampleData(inputBuffer, 0)
                    if (sampleSize < 0) {
                        codec.queueInputBuffer(
                            inputIndex,
                            0,
                            0,
                            0,
                            MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                        )
                        inputDone = true
                    } else {
                        codec.queueInputBuffer(
                            inputIndex,
                            0,
                            sampleSize,
                            extractor.sampleTime,
                            0,
                        )
                        extractor.advance()
                    }
                }
            }

            val outputIndex = codec.dequeueOutputBuffer(bufferInfo, 10_000)
            when {
                outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    // format updated — nothing to do
                }
                outputIndex >= 0 -> {
                    val outputBuffer = codec.getOutputBuffer(outputIndex)!!
                    appendPcm16(outputBuffer, bufferInfo, pcm)
                    codec.releaseOutputBuffer(outputIndex, false)
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        break
                    }
                }
            }
        }

        codec.stop()
        codec.release()
        extractor.release()

        if (pcm.isEmpty()) {
            throw IOException("Decoder produced no audio")
        }

        val sourceRate = inputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        val channelCount = inputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        val mono = downmixToMono(pcm, channelCount)
        val resampled = if (sourceRate != targetSampleRate) {
            resample(mono, sourceRate, targetSampleRate)
        } else {
            mono
        }

        writeWavFile(outputPath, resampled, targetSampleRate)
        return outputPath
    }

    private fun appendPcm16(
        buffer: ByteBuffer,
        info: MediaCodec.BufferInfo,
        out: ArrayList<Short>,
    ) {
        buffer.position(info.offset)
        buffer.limit(info.offset + info.size)
        buffer.order(ByteOrder.LITTLE_ENDIAN)
        while (buffer.remaining() >= 2) {
            out.add(buffer.short)
        }
    }

    private fun downmixToMono(samples: List<Short>, channels: Int): ShortArray {
        if (channels <= 1) return samples.toShortArray()
        val frames = samples.size / channels
        val mono = ShortArray(frames)
        for (i in 0 until frames) {
            var sum = 0
            for (c in 0 until channels) {
                sum += samples[i * channels + c]
            }
            mono[i] = (sum / channels).toShort()
        }
        return mono
    }

    private fun resample(input: ShortArray, fromRate: Int, toRate: Int): ShortArray {
        if (fromRate == toRate) return input
        val ratio = fromRate.toDouble() / toRate.toDouble()
        val outLen = (input.size / ratio).toInt().coerceAtLeast(1)
        val out = ShortArray(outLen)
        for (i in 0 until outLen) {
            val src = i * ratio
            val idx = src.toInt()
            val frac = src - idx
            val s0 = input[idx.coerceAtMost(input.size - 1)].toInt()
            val s1 = input[(idx + 1).coerceAtMost(input.size - 1)].toInt()
            out[i] = (s0 * (1 - frac) + s1 * frac).toInt().toShort()
        }
        return out
    }

    private fun writeWavFile(path: String, samples: ShortArray, sampleRate: Int) {
        val file = File(path)
        file.parentFile?.mkdirs()
        val dataSize = samples.size * 2
        FileOutputStream(file).use { fos ->
            val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
            header.put("RIFF".toByteArray())
            header.putInt(36 + dataSize)
            header.put("WAVE".toByteArray())
            header.put("fmt ".toByteArray())
            header.putInt(16)
            header.putShort(1) // PCM
            header.putShort(1) // mono
            header.putInt(sampleRate)
            header.putInt(sampleRate * 2)
            header.putShort(2)
            header.putShort(16)
            header.put("data".toByteArray())
            header.putInt(dataSize)
            fos.write(header.array())

            val pcmBytes = ByteBuffer.allocate(dataSize).order(ByteOrder.LITTLE_ENDIAN)
            for (s in samples) {
                pcmBytes.putShort(s)
            }
            fos.write(pcmBytes.array())
        }
    }
}
