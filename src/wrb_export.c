#define WIN32_LEAN_AND_MEAN  // Exclude rarely-used stuff from Windows headers
#include <windows.h>
#include <stdlib.h>
#include <stdio.h>
#include <gsl/gsl_math.h>
#include "wrb_struct.h"
#include "candle.h"
#include "wrb_analysis.h"
#include "wrb_management.h"
#include "wrb_zone.h"
#include "wrb_confirmation.h"
#include "wrb_ajctr.h"
#include "wrb_apaor.h"
#include "wrb_vsa.h"
#include "wrb_fvb.h"
#include "wrb_vtr.h"
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


WRBFUNC unsigned int __stdcall _time(ohlc *candle, int i) {
    return candle[i].timestamp;
}


WRBFUNC int __stdcall _test_int(int x) {
    return x+x;
}


WRBFUNC int __stdcall _test_int_array(int *x) {
    return x[0];
}


WRBFUNC double __stdcall _test_ohlc(ohlc x) {
    return x.close;
}


WRBFUNC double __stdcall _test_ohlc_array(ohlc *x) {
    return x[0].close;
}

WRBFUNC void __stdcall _dir(ohlc *candle, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] = dir(candle, i);
    }
}

WRBFUNC void __stdcall _consecutive_dir(ohlc *candle, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] = consecutive_dir(candle, i);
    }
}

WRBFUNC void __stdcall _body_size(ohlc *candle, size_t n, double *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] = body_size(candle, i);
    }
}

WRBFUNC void __stdcall _broke_body_size(ohlc *candle, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] = broke_body_size(candle, i, 3);
    }
}


WRBFUNC void __stdcall _broke_bars(ohlc *candle, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] = broke_body_size(candle, i, 3);
    }
}


WRBFUNC void __stdcall _wrb(ohlc *candle, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] = wrb(candle, i).dir;
    }
}


WRBFUNC void __stdcall _wrb_hg(ohlc *candle, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  wrb_hg(candle, i, n).dir;
    }
}


WRBFUNC void __stdcall _dcm(ohlc *candle, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  dcm(candle, i, n);
    }
}


WRBFUNC void __stdcall _swing_point_1(ohlc *candle, size_t contraction, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  swing_point_1(candle, i, contraction, n).v1.dir;
    }

    // if (n > 0 && i < n) {
    //     zone r = swing_point_1(candle, i, contraction, n);
    //     if (r.v1.nr > 0) {
    //         arr[0] = n - r.v1.nr - 1;
    //     }
    //     if (r.v2.nr > 0) {
    //         arr[1] = n - r.v2.nr - 1;
    //     }
    //     arr[3] = r.v1.dir;
    //     return r.v1.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _swing_point_2(ohlc *candle, size_t contraction, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  swing_point_2(candle, i, contraction, n).v1.dir;
    }

    // if (n > 0 && i < n) {
    //     zone r = swing_point_2(candle, i, contraction, n);
    //     if (r.v1.nr > 0) {
    //         arr[0] = n - r.v1.nr - 1;;
    //     }
    //     if (r.v2.nr > 0) {
    //         arr[1] = n - r.v2.nr - 1;
    //     }
    //     arr[3] = r.v1.dir;
    //     return r.v1.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _swing_point_3(ohlc *candle, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  swing_point_3(candle, i, n).v1.dir;
    }
    // if (n > 0 && i < n) {
    //     zone r = swing_point_3(candle, i, n);
    //     if (r.v1.nr > 0) {
    //         arr[0] = n - r.v1.nr - 1;;
    //     }
    //     if (r.v2.nr > 0) {
    //         arr[1] = n - r.v2.nr - 1;
    //     }
    //     arr[3] = r.v1.dir;
    //     return r.v1.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _strong_continuation_1(ohlc *candle, size_t contraction, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  strong_continuation_1(candle, i, contraction, n).v1.dir;
    }
    // if (n > 0 && i < n) {
    //     zone r = strong_continuation_1(candle, i, contraction, n);
    //     if (r.v1.nr > 0) {
    //         arr[0] = n - r.v1.nr - 1;;
    //     }
    //     if (r.v2.nr > 0) {
    //         arr[1] = n - r.v2.nr - 1;
    //     }
    //     arr[3] = r.v1.dir;
    //     return r.v1.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _strong_continuation_2(ohlc *candle, size_t contraction, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  strong_continuation_2(candle, i, contraction, n).v1.dir;
    }
    // if (n > 0 && i < n) {
    //     zone r = strong_continuation_2(candle, i, contraction, n);
    //     if (r.v1.nr > 0) {
    //         arr[0] = n - r.v1.nr - 1;;
    //     }
    //     if (r.v2.nr > 0) {
    //         arr[1] = n - r.v2.nr - 1;
    //     }
    //     arr[3] = r.v1.dir;
    //     return r.v1.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _strong_continuation_3(ohlc *candle, size_t contraction, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  strong_continuation_3(candle, i, contraction, n).v1.dir;
    }
    // if (n > 0 && i < n) {
    //     zone r = strong_continuation_3(candle, i, contraction, n);
    //     if (r.v1.nr > 0) {
    //         arr[0] = n - r.v1.nr - 1;;
    //     }
    //     if (r.v2.nr > 0) {
    //         arr[1] = n - r.v2.nr - 1;
    //     }
    //     arr[3] = r.v1.dir;
    //     return r.v1.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _strong_continuation_4(ohlc *candle, size_t contraction, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  strong_continuation_4(candle, i, contraction, n).v1.dir;
    }
    // if (n > 0 && i < n) {
    //     zone r = strong_continuation_4(candle, i, contraction, n);
    //     if (r.v1.nr > 0) {
    //         arr[0] = n - r.v1.nr - 1;;
    //     }
    //     if (r.v2.nr > 0) {
    //         arr[1] = n - r.v2.nr - 1;
    //     }
    //     arr[3] = r.v1.dir;
    //     return r.v1.dir;
    // }
    // return 0;
}



WRBFUNC void __stdcall _reaction_zone(ohlc *candle, size_t look_forward,
                                     size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  reaction_zone(candle, i, look_forward, n).v1.dir;
    }
    // if (n > 0 && i < n) {
    //     zone r = reaction_zone(candle, i, look_forward, n);
    //     if (r.v1.nr > 0) {
    //         arr[0] = n - r.v1.nr - 1;;
    //     }
    //     arr[3] = r.v1.dir;
    //     return r.v1.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _wrb_zone(ohlc *candle, size_t contraction,
                                size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  wrb_zone(candle, i, contraction, n).v1.dir;
    }
    // if (n > 0 && i < n) {
    //     zone r = wrb_zone(candle, i, contraction, n);
    //     if (r.v1.nr > 0) {
    //         arr[0] = n - r.v1.nr - 1;;
    //     }
    //     if (r.v2.nr > 0) {
    //         arr[1] = n - r.v2.nr - 1;
    //     }
    //     arr[3] = r.v1.dir;
    //     return r.v1.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _conf_a(ohlc *candle, size_t i, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  conf_a(candle, i).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = conf_a(candle, i);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _conf_b(ohlc *candle, size_t i, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  conf_b(candle, i).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = conf_b(candle, i);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _conf_c(ohlc *candle, size_t i, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  conf_c(candle, i).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = conf_c(candle, i);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _conf_d(ohlc *candle, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  conf_d(candle, i).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = conf_d(candle, i);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _conf_e(ohlc *candle, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  conf_e(candle, i).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = conf_e(candle, i);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _conf_h1(ohlc *candle, size_t i, size_t n,
                               size_t contraction, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  conf_h1(candle, i, contraction, n).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = conf_h1(candle, i, contraction, n);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _conf_h2(ohlc *candle, size_t i, size_t n,
                               size_t contraction, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  conf_h2(candle, i, contraction, n).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = conf_h2(candle, i, contraction, n);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _conf_h3(ohlc *candle, size_t contraction, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  conf_h3(candle, i, contraction, n).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = conf_h3(candle, i, contraction, n);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _conf_h4(ohlc *candle, size_t i, size_t n,
                               size_t contraction, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  conf_h4(candle, i, contraction, n).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = conf_h4(candle, i, contraction, n);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _conf_h(ohlc *candle, size_t i, size_t n,
                              size_t contraction, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  conf_h4(candle, i, contraction, n).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = conf_h(candle, i, contraction, n);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _hammer(ohlc *candle, size_t i, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  hammer(candle, i).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = hammer(candle, i);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _harami(ohlc *candle, size_t i, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  harami(candle, i).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = harami(candle, i);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


WRBFUNC void __stdcall _engulfing(ohlc *candle, size_t i, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  engulfing(candle, i).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = engulfing(candle, i);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


// WRBFUNC void __stdcall _soldiers(ohlc *candle, size_t i, size_t n, int *arr) {
//     if (n > 0 && i < n) {
//         signal r = soldiers(candle, i, n);
//         if (r.c1.nr > 0) {
//             arr[0] = n - r.c1.nr - 1;;
//         }
//         if (r.c2.nr > 0) {
//             arr[1] = n - r.c2.nr - 1;
//         }
//         arr[3] = r.dir;
//         return r.dir;
//     }
//     return 0;
// }


// WRBFUNC void __stdcall _apaor(ohlc *main, ohlc *sister, size_t i,
//                                  size_t pa_l, size_t pb_l, int invert,
//                                  size_t look_back, size_t main_bars,
//                                  size_t sister_bars, int *arr) {
//     size_t n = GSL_MIN(main_bars, sister_bars);
//     if (n > 0 && i < n) {
//         ohlc tmp_arr[n];
//         int j;
//         if (i > n) {
//             return 0;
//         }
//         if (main_bars > sister_bars) {
//             for (j = 0; j < n; j++) {
//                 tmp_arr[n - j - 1].timestamp = main[main_bars - j - 1].timestamp;
//                 tmp_arr[n - j - 1].open = main[main_bars - j - 1].open;
//                 tmp_arr[n - j - 1].high = main[main_bars - j - 1].high;
//                 tmp_arr[n - j - 1].low = main[main_bars - j - 1].low;
//                 tmp_arr[n - j - 1].close = main[main_bars - j - 1].close;
//                 tmp_arr[n - j - 1].volume = main[main_bars - j - 1].volume;
//             }
//             main = tmp_arr;
//         } else if (main_bars < sister_bars) {
//             for (j = 0; j < n; j++) {
//                 tmp_arr[n - j - 1].timestamp = sister[sister_bars - j - 1].timestamp;
//                 tmp_arr[n - j - 1].open = sister[sister_bars - j - 1].open;
//                 tmp_arr[n - j - 1].high = sister[sister_bars - j - 1].high;
//                 tmp_arr[n - j - 1].low = sister[sister_bars - j - 1].low;
//                 tmp_arr[n - j - 1].close = sister[sister_bars - j - 1].close;
//                 tmp_arr[n - j - 1].volume = sister[sister_bars - j - 1].volume;
//             }
//             sister = tmp_arr;
//         }
//         signal r = apaor(main, sister, i, pa_l, pb_l,
//                          invert, look_back, n);
//         if (r.c1.nr > 0) {
//             arr[0] = n - r.c1.nr - 1;
//         }
//         if (r.c2.nr > 0) {
//             arr[1] = n - r.c2.nr - 1;
//         }
//         arr[3] = r.dir;
//         return r.dir;
//     }
//     return 0;
// }


// WRBFUNC void __stdcall _vsa(ohlc *candle, size_t i, size_t look_for_zone,
//                            int nd_ns, int effort, size_t n, int *arr) {
//     if (n > 0 && i < n) {
//         signal r = vsa(candle, i, look_for_zone, nd_ns, effort, n);
//         if (r.c1.nr > 0) {
//             arr[0] = n - r.c1.nr - 1;;
//         }
//         if (r.zone.v1.nr > 0) {
//             arr[2] = n - r.zone.v1.nr - 1;
//         }
//         arr[3] = r.dir;
//         return r.dir;
//     }
//     return 0;
// }


WRBFUNC void __stdcall _fvb(ohlc *candle, size_t look_back, size_t n, int *result) {
    for (size_t i=0; i<n; i++) {
        result[n - i - 1] =  fvb(candle, i, look_back, n).dir;
    }
    // if (n > 0 && i < n) {
    //     signal r = fvb(candle, i, look_back, n);
    //     if (r.c1.nr > 0) {
    //         arr[0] = n - r.c1.nr - 1;;
    //     }
    //     if (r.c2.nr > 0) {
    //         arr[1] = n - r.c2.nr - 1;
    //     }
    //     if (r.zone.v1.nr > 0) {
    //         arr[2] = n - r.zone.v1.nr - 1;
    //     }
    //     arr[3] = r.dir;
    //     return r.dir;
    // }
    // return 0;
}


// WRBFUNC void __stdcall _vtr(ohlc *main, ohlc *sister, size_t i,
//                            int invert, size_t look_back, size_t main_bars,
//                            size_t sister_bars, int *arr) {

//     size_t n = GSL_MIN(main_bars, sister_bars);
//     if (n > 0 && i < n) {
//         ohlc tmp_arr[n];
//         int j;
//         if (i > n) {
//             return 0;
//         }
//         if (main_bars > sister_bars) {
//             for (j = 0; j < n; j++) {
//                 tmp_arr[n - j - 1].timestamp = main[main_bars - j - 1].timestamp;
//                 tmp_arr[n - j - 1].open = main[main_bars - j - 1].open;
//                 tmp_arr[n - j - 1].high = main[main_bars - j - 1].high;
//                 tmp_arr[n - j - 1].low = main[main_bars - j - 1].low;
//                 tmp_arr[n - j - 1].close = main[main_bars - j - 1].close;
//                 tmp_arr[n - j - 1].volume = main[main_bars - j - 1].volume;
//             }
//             main = tmp_arr;
//         } else if (main_bars < sister_bars) {
//             for (j = 0; j < n; j++) {
//                 tmp_arr[n - j - 1].timestamp = sister[sister_bars - j - 1].timestamp;
//                 tmp_arr[n - j - 1].open = sister[sister_bars - j - 1].open;
//                 tmp_arr[n - j - 1].high = sister[sister_bars - j - 1].high;
//                 tmp_arr[n - j - 1].low = sister[sister_bars - j - 1].low;
//                 tmp_arr[n - j - 1].close = sister[sister_bars - j - 1].close;
//                 tmp_arr[n - j - 1].volume = sister[sister_bars - j - 1].volume;
//             }
//             sister = tmp_arr;
//         }
//         signal r = vtr(main, sister, i, invert, look_back, n);
//         if (r.c1.nr > 0) {
//             arr[0] = n - r.c1.nr - 1;;
//         }
//         if (r.c2.nr > 0) {
//             arr[1] = n - r.c2.nr - 1;
//         }
//         if (r.zone.v1.nr > 0) {
//             arr[2] = n - r.zone.v1.nr - 1;
//         }
//         arr[3] = r.dir;
//         return r.dir;
//     }
//     return 0;
// }
