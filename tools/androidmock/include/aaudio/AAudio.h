/* minimal aaudio/AAudio.h (NDK ABI, libaaudio.so, API 26+) */
#pragma once
#include <stdint.h>
#include <sys/cdefs.h>
__BEGIN_DECLS
typedef int32_t aaudio_result_t;
typedef int32_t aaudio_format_t;
typedef int32_t aaudio_direction_t;
typedef int32_t aaudio_sharing_mode_t;
typedef int32_t aaudio_performance_mode_t;
typedef int32_t aaudio_stream_state_t;
typedef int32_t aaudio_data_callback_result_t;
typedef int32_t aaudio_usage_t;
typedef int32_t aaudio_content_type_t;
enum { AAUDIO_OK = 0 };
enum { AAUDIO_DIRECTION_OUTPUT = 0, AAUDIO_DIRECTION_INPUT = 1 };
enum { AAUDIO_FORMAT_UNSPECIFIED = 0, AAUDIO_FORMAT_PCM_I16 = 1, AAUDIO_FORMAT_PCM_FLOAT = 2 };
enum { AAUDIO_SHARING_MODE_EXCLUSIVE = 0, AAUDIO_SHARING_MODE_SHARED = 1 };
enum { AAUDIO_PERFORMANCE_MODE_NONE = 10, AAUDIO_PERFORMANCE_MODE_POWER_SAVING = 11, AAUDIO_PERFORMANCE_MODE_LOW_LATENCY = 12 };
enum { AAUDIO_CALLBACK_RESULT_CONTINUE = 0, AAUDIO_CALLBACK_RESULT_STOP = 1 };
enum { AAUDIO_USAGE_GAME = 14 };                         /* API 28 */
enum { AAUDIO_CONTENT_TYPE_MUSIC = 2, AAUDIO_CONTENT_TYPE_SONIFICATION = 4 };
typedef struct AAudioStreamStruct AAudioStream;
typedef struct AAudioStreamBuilderStruct AAudioStreamBuilder;
typedef aaudio_data_callback_result_t (*AAudioStream_dataCallback)(AAudioStream* stream, void* userData, void* audioData, int32_t numFrames);
typedef void (*AAudioStream_errorCallback)(AAudioStream* stream, void* userData, aaudio_result_t error);
aaudio_result_t AAudio_createStreamBuilder(AAudioStreamBuilder** builder);
void AAudioStreamBuilder_setDirection(AAudioStreamBuilder* builder, aaudio_direction_t direction);
void AAudioStreamBuilder_setSampleRate(AAudioStreamBuilder* builder, int32_t sampleRate);
void AAudioStreamBuilder_setChannelCount(AAudioStreamBuilder* builder, int32_t channelCount);
void AAudioStreamBuilder_setFormat(AAudioStreamBuilder* builder, aaudio_format_t format);
void AAudioStreamBuilder_setSharingMode(AAudioStreamBuilder* builder, aaudio_sharing_mode_t sharingMode);
void AAudioStreamBuilder_setPerformanceMode(AAudioStreamBuilder* builder, aaudio_performance_mode_t mode);
void AAudioStreamBuilder_setBufferCapacityInFrames(AAudioStreamBuilder* builder, int32_t numFrames);
void AAudioStreamBuilder_setDataCallback(AAudioStreamBuilder* builder, AAudioStream_dataCallback callback, void* userData);
void AAudioStreamBuilder_setErrorCallback(AAudioStreamBuilder* builder, AAudioStream_errorCallback callback, void* userData);
aaudio_result_t AAudioStreamBuilder_openStream(AAudioStreamBuilder* builder, AAudioStream** stream);
aaudio_result_t AAudioStreamBuilder_delete(AAudioStreamBuilder* builder);
aaudio_result_t AAudioStream_close(AAudioStream* stream);
aaudio_result_t AAudioStream_requestStart(AAudioStream* stream);
aaudio_result_t AAudioStream_requestPause(AAudioStream* stream);
aaudio_result_t AAudioStream_requestStop(AAudioStream* stream);
int32_t AAudioStream_getSampleRate(AAudioStream* stream);
int32_t AAudioStream_getChannelCount(AAudioStream* stream);
int32_t AAudioStream_getFramesPerBurst(AAudioStream* stream);
aaudio_result_t AAudioStream_setBufferSizeInFrames(AAudioStream* stream, int32_t numFrames);
aaudio_stream_state_t AAudioStream_getState(AAudioStream* stream);
__END_DECLS
