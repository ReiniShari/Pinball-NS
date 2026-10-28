/* mini SDK (see ../README.md): math of iOS (Darwin, arm64) */
#ifndef PNS_MATH_H
#define PNS_MATH_H

#define HUGE_VAL  __builtin_huge_val()
#define HUGE_VALF __builtin_huge_valf()
#define INFINITY  __builtin_inff()
#define NAN       __builtin_nanf("")
#define M_PI      3.14159265358979323846
#define M_SQRT2   1.41421356237309504880
#define isnan(x)    __builtin_isnan(x)
#define isinf(x)    __builtin_isinf(x)
#define isfinite(x) __builtin_isfinite(x)
#define signbit(x)  __builtin_signbit(x)

double sqrt(double x);       float sqrtf(float x);
double floor(double x);      float floorf(float x);
double ceil(double x);       float ceilf(float x);
double round(double x);      float roundf(float x);
double trunc(double x);      float truncf(float x);
double fabs(double x);       float fabsf(float x);
double fmod(double x, double y);  float fmodf(float x, float y);
double fmin(double x, double y);  float fminf(float x, float y);
double fmax(double x, double y);  float fmaxf(float x, float y);
double pow(double x, double y);   float powf(float x, float y);
double exp(double x);        float expf(float x);
double exp2(double x);       float exp2f(float x);
double log(double x);        float logf(float x);
double log2(double x);       float log2f(float x);
double log10(double x);      float log10f(float x);
double sin(double x);        float sinf(float x);
double cos(double x);        float cosf(float x);
double tan(double x);        float tanf(float x);
double atan(double x);       float atanf(float x);
double atan2(double y, double x); float atan2f(float y, float x);
double hypot(double x, double y); float hypotf(float x, float y);
double ldexp(double x, int e);
double frexp(double x, int *e);
double modf(double x, double *ip);
long lrint(double x);        long lrintf(float x);
long lround(double x);       long lroundf(float x);

#endif
