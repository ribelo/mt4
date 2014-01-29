#define WIN32_LEAN_AND_MEAN  // Exclude rarely-used stuff from Windows headers
#include <windows.h>
#include <gsl/gsl_math.h>
//---
#define WRBFUNC __declspec(dllexport)


BOOL APIENTRY DllMain(HANDLE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {
    switch (ul_reason_for_call) {
    case DLL_PROCESS_ATTACH:
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }
    return (TRUE);
}


WRBFUNC double __stdcall _abs(double x) {
    return fabs(x);
}


WRBFUNC double __stdcall _fmax(double a, double b) {
    return GSL_MAX_DBL(a, b);
}


WRBFUNC double __stdcall _fmin(double a, double b) {
    return GSL_MIN_DBL(a, b);
}


WRBFUNC double __stdcall _imax(double a, double b) {
    return GSL_MAX_INT(a, b);
}


WRBFUNC double __stdcall _imin(double a, double b) {
    return GSL_MIN_INT(a, b);
}


WRBFUNC double __stdcall _fcmp(double x1, double x2) {
    return gsl_fcmp(x1, x2, FLT_EPSILON);
}

WRBFUNC double __stdcall _roundp(double x, int precise) {
    return floor(x * pow(10, precise) + 0.5) / pow(10, precise);
}

