#define WIN32_LEAN_AND_MEAN  // Exclude rarely-used stuff from Windows headers
#include <windows.h>
#include <stdlib.h>
#include <stdio.h>
#include <gsl/gsl_math.h>
#include "wrb_struct.h"
#include "candle.h"
#include "wrb_analysis.h"
#include "wrb_zone.h"
#include "wrb_confirmation.h"
#include "wrb_ajctr.h"
#include "wrb_apaor.h"
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


WRBFUNC double __stdcall _Time(ohlc *candle, size_t i, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return candle[n - i - 1].timestamp;
    }
    return 0;
}


WRBFUNC double __stdcall _Open(ohlc *candle, size_t i, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return candle[n - i - 1].open;
    }
    return 0;
}

WRBFUNC double __stdcall _High(ohlc *candle, size_t i, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return candle[n - i - 1].high;
    }
    return 0;
}

WRBFUNC double __stdcall _Low(ohlc *candle, size_t i, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return candle[n - i - 1].low;
    }
    return 0;
}

WRBFUNC double __stdcall _Close(ohlc *candle, size_t i, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return candle[n - i - 1].close;
    }
    return 0;
}

WRBFUNC int __stdcall _dir(ohlc *candle, size_t i, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return dir(candle, n - i - 1);
    }
    return 0;
}

WRBFUNC double __stdcall _body_size(ohlc *candle, size_t i, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return body_size(candle, n - i - 1);
    }
    return 0;
}

WRBFUNC double __stdcall _gap(ohlc *candle, size_t i, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return gap(candle, n - i - 1);
    }
    return 0;
}

WRBFUNC int __stdcall _body_size_break(ohlc *candle, size_t i, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return body_size_break(candle, n - i - 1);
    }
    return 0;
}

WRBFUNC int __stdcall _bars_broken_by_body(ohlc *candle, size_t i, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return bars_broken_by_body(candle, n - i - 1);
    }
    return 0;
}

WRBFUNC int __stdcall _filled_by(ohlc *candle, size_t i, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return filled_by(candle, n - i - 1, n);
    }
    return 0;
}

WRBFUNC int __stdcall _unfilled(ohlc *candle, size_t i, size_t j, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return unfilled(candle, n - i - 1, j);
    }
    return 0;
}


WRBFUNC int __stdcall _fractal(ohlc *candle, size_t i, size_t n, size_t l) {
    if (n > 0 && i > 0 && i < n) {
        return fractal(candle, n - i - 1, n, l);
    }
    return 0;
}


WRBFUNC int __stdcall _fractal_break(ohlc *candle, size_t i, size_t n,
                                     size_t l, size_t look_back) {
    if (n > 0 && i > 0 && i < n) {
        int brk = fractal_break(candle, n - i - 1, n, l, look_back);
        if (brk > 0) {
            return n - brk;
        } else if (brk < 0) {
            return n - (-brk);
        }
    }
    return 0;
}


WRBFUNC int __stdcall _wrb(ohlc *candle, size_t i, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return wrb(candle, n - i - 1).dir;
    }
    return 0;
}


WRBFUNC int __stdcall _wrb_unfilled(ohlc *candle, size_t i, int type, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        for (size_t j = 1; j < n; j++) {
            if (wrb(candle, n - i - 1 - j).dir == type &&
                    unfilled(candle, n - i - 1 - j, j)) {
                return i + j;
            }
        }
    }
    return -1;
}


WRBFUNC int __stdcall _wrb_hg(ohlc *candle, size_t i, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        return wrb_hg(candle, n - i - 1).dir;
    }
    return 0;
}


WRBFUNC int __stdcall _wrb_hg_unfilled(ohlc *candle, size_t i, int type, size_t n) {
    if (n > 0 && i > 0 && i < n) {
        for (size_t j = 1; j < n; j++) {
            if (wrb_hg(candle, n - i - 1 - j).dir == type &&
                    unfilled(candle, n - i - 1 - j, j)) {
                return i + j;
            }
        }
    }
    return -1;
}


WRBFUNC int __stdcall _dcm(ohlc *candle, size_t i,
                           size_t n, size_t look_back) {
    if (n > 0 && i > 0 && i < n) {
        return dcm(candle, n - i - 1, n, look_back);
    }
    return 0;
}


WRBFUNC int __stdcall _swing_point_1(ohlc *candle, size_t i, size_t n,
                                     size_t contraction, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        zone r = swing_point_1(candle, n - i - 1, n, contraction);
        if (r.v1.nr > 0) {
            arr[0] = n - r.v1.nr - 1;
        }
        if (r.v2.nr > 0) {
            arr[1] = n - r.v2.nr - 1;
        }
        arr[3] = r.v1.dir;
        return r.v1.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _swing_point_2(ohlc *candle, size_t i, size_t n,
                                     size_t contraction, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        zone r = swing_point_2(candle, n - i - 1, n, contraction);
        if (r.v1.nr > 0) {
            arr[0] = n - r.v1.nr - 1;;
        }
        if (r.v2.nr > 0) {
            arr[1] = n - r.v2.nr - 1;
        }
        arr[3] = r.v1.dir;
        return r.v1.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _swing_point_3(ohlc *candle, size_t i, size_t n, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        zone r = swing_point_3(candle, n - i - 1, n);
        if (r.v1.nr > 0) {
            arr[0] = n - r.v1.nr - 1;;
        }
        if (r.v2.nr > 0) {
            arr[1] = n - r.v2.nr - 1;
        }
        arr[3] = r.v1.dir;
        return r.v1.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _strong_continuation_1(ohlc *candle, size_t i, size_t n,
        size_t contraction, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        zone r = strong_continuation_1(candle, n - i - 1, n, contraction);
        if (r.v1.nr > 0) {
            arr[0] = n - r.v1.nr - 1;;
        }
        if (r.v2.nr > 0) {
            arr[1] = n - r.v2.nr - 1;
        }
        arr[3] = r.v1.dir;
        return r.v1.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _strong_continuation_2(ohlc *candle, size_t i, size_t n,
        size_t contraction, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        zone r = strong_continuation_2(candle, n - i - 1, n, contraction);
        if (r.v1.nr > 0) {
            arr[0] = n - r.v1.nr - 1;;
        }
        if (r.v2.nr > 0) {
            arr[1] = n - r.v2.nr - 1;
        }
        arr[3] = r.v1.dir;
        return r.v1.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _strong_continuation_3(ohlc *candle, size_t i, size_t n,
        size_t contraction, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        zone r = strong_continuation_3(candle, n - i - 1, n, contraction);
        if (r.v1.nr > 0) {
            arr[0] = n - r.v1.nr - 1;;
        }
        if (r.v2.nr > 0) {
            arr[1] = n - r.v2.nr - 1;
        }
        arr[3] = r.v1.dir;
        return r.v1.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _strong_continuation_4(ohlc *candle, size_t i, size_t n,
        size_t contraction, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        zone r = strong_continuation_4(candle, n - i - 1, n, contraction);
        if (r.v1.nr > 0) {
            arr[0] = n - r.v1.nr - 1;;
        }
        if (r.v2.nr > 0) {
            arr[1] = n - r.v2.nr - 1;
        }
        arr[3] = r.v1.dir;
        return r.v1.dir;
    }
    return 0;
}



WRBFUNC int __stdcall _reaction_zone(ohlc *candle, size_t i, size_t n,
                                     size_t look_forward, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        zone r = reaction_zone(candle, n - i - 1, n, look_forward);
        if (r.v1.nr > 0) {
            arr[0] = n - r.v1.nr - 1;;
        }
        arr[3] = r.v1.dir;
        return r.v1.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _wrb_zone(ohlc *candle, size_t i, size_t n,
                                size_t contraction, int h_zone, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        zone r = wrb_zone(candle, n - i - 1, n, contraction, h_zone);
        if (r.v1.nr > 0) {
            arr[0] = n - r.v1.nr - 1;;
        }
        if (r.v2.nr > 0) {
            arr[1] = n - r.v2.nr - 1;
        }
        arr[3] = r.v1.dir;
        return r.v1.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _conf_a(ohlc *candle, size_t i, size_t n, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = conf_a(candle, n - i - 1);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _conf_b(ohlc *candle, size_t i, size_t n, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = conf_b(candle, n - i - 1);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _conf_c(ohlc *candle, size_t i, size_t n, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = conf_c(candle, n - i - 1);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _conf_d(ohlc *candle, size_t i, size_t n, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = conf_d(candle, n - i - 1);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _conf_e(ohlc *candle, size_t i, size_t n, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = conf_e(candle, n - i - 1);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _conf_h1(ohlc *candle, size_t i, size_t n,
                               size_t contraction, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = conf_h1(candle, n - i - 1, n, contraction);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _conf_h2(ohlc *candle, size_t i, size_t n,
                               size_t contraction, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = conf_h2(candle, n - i - 1, n, contraction);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _conf_h3(ohlc *candle, size_t i, size_t n,
                               size_t contraction, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = conf_h3(candle, n - i - 1, n, contraction);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _conf_h4(ohlc *candle, size_t i, size_t n,
                               size_t contraction, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = conf_h4(candle, n - i - 1, n, contraction);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _conf_h(ohlc *candle, size_t i, size_t n,
                              size_t contraction, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = conf_h(candle, n - i - 1, n, contraction);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _hammer(ohlc *candle, size_t i, size_t n, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = hammer(candle, n - i - 1);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _harami(ohlc *candle, size_t i, size_t n, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = harami(candle, n - i - 1);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _engulfing(ohlc *candle, size_t i, size_t n, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = engulfing(candle, n - i - 1);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _soldiers(ohlc *candle, size_t i, size_t n, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = soldiers(candle, n - i - 1);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _apaor(ohlc *main, ohlc *sister, size_t i,
                                 size_t main_bars, size_t sister_bars,
                                 size_t pa_l, size_t pb_l, int invert,
                                 size_t look_back, int *arr) {

    size_t n = GSL_MIN(main_bars, sister_bars);
    if (n > 0 && i > 0 && i < n) {
        ohlc tmp_arr[n];
        int j;
        if (i > n) {
            return 0;
        }
        if (main_bars > sister_bars) {
            for (j = 0; j < n; j++) {
                tmp_arr[n - j - 1].timestamp = main[main_bars - j - 1].timestamp;
                tmp_arr[n - j - 1].open = main[main_bars - j - 1].open;
                tmp_arr[n - j - 1].high = main[main_bars - j - 1].high;
                tmp_arr[n - j - 1].low = main[main_bars - j - 1].low;
                tmp_arr[n - j - 1].close = main[main_bars - j - 1].close;
                tmp_arr[n - j - 1].volume = main[main_bars - j - 1].volume;
            }
            main = tmp_arr;
        } else if (main_bars < sister_bars) {
            for (j = 0; j < n; j++) {
                tmp_arr[n - j - 1].timestamp = sister[sister_bars - j - 1].timestamp;
                tmp_arr[n - j - 1].open = sister[sister_bars - j - 1].open;
                tmp_arr[n - j - 1].high = sister[sister_bars - j - 1].high;
                tmp_arr[n - j - 1].low = sister[sister_bars - j - 1].low;
                tmp_arr[n - j - 1].close = sister[sister_bars - j - 1].close;
                tmp_arr[n - j - 1].volume = sister[sister_bars - j - 1].volume;
            }
            sister = tmp_arr;
        }
        signal r = apaor(main, sister, n - i - 1, n,
                         pa_l, pb_l , invert, look_back);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _fvb(ohlc *candle, size_t i, size_t n,
                           size_t look_back, int h_zone, int *arr) {
    if (n > 0 && i > 0 && i < n) {
        signal r = fvb(candle, n - i - 1, n, look_back, h_zone);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        if (r.zone.v1.nr > 0) {
            arr[2] = n - r.zone.v1.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}


WRBFUNC int __stdcall _vtr(ohlc *main, ohlc *sister, size_t i,
                           size_t main_bars, size_t sister_bars,
                           int invert, size_t look_back,
                           int h_zone, int *arr) {

    size_t n = GSL_MIN(main_bars, sister_bars);
    if (n > 0 && i > 0 && i < n) {
        ohlc tmp_arr[n];
        int j;
        if (i > n) {
            return 0;
        }
        if (main_bars > sister_bars) {
            for (j = 0; j < n; j++) {
                tmp_arr[n - j - 1].timestamp = main[main_bars - j - 1].timestamp;
                tmp_arr[n - j - 1].open = main[main_bars - j - 1].open;
                tmp_arr[n - j - 1].high = main[main_bars - j - 1].high;
                tmp_arr[n - j - 1].low = main[main_bars - j - 1].low;
                tmp_arr[n - j - 1].close = main[main_bars - j - 1].close;
                tmp_arr[n - j - 1].volume = main[main_bars - j - 1].volume;
            }
            main = tmp_arr;
        } else if (main_bars < sister_bars) {
            for (j = 0; j < n; j++) {
                tmp_arr[n - j - 1].timestamp = sister[sister_bars - j - 1].timestamp;
                tmp_arr[n - j - 1].open = sister[sister_bars - j - 1].open;
                tmp_arr[n - j - 1].high = sister[sister_bars - j - 1].high;
                tmp_arr[n - j - 1].low = sister[sister_bars - j - 1].low;
                tmp_arr[n - j - 1].close = sister[sister_bars - j - 1].close;
                tmp_arr[n - j - 1].volume = sister[sister_bars - j - 1].volume;
            }
            sister = tmp_arr;
        }
        signal r = vtr(main, sister, n - i - 1, n, invert, look_back, h_zone);
        if (r.c1.nr > 0) {
            arr[0] = n - r.c1.nr - 1;;
        }
        if (r.c2.nr > 0) {
            arr[1] = n - r.c2.nr - 1;
        }
        if (r.zone.v1.nr > 0) {
            arr[2] = n - r.zone.v1.nr - 1;
        }
        arr[3] = r.dir;
        return r.dir;
    }
    return 0;
}
