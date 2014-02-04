
#include <gsl/gsl_math.h>
#include "wrb_struct.h"
#include "candle.h"
#include "wrb_analysis.h"


double support(ohlc *candle, size_t i, int hg_only, int use_fractal,
               size_t l, int n) {
    double last_wrb = GSL_NEGINF, last_fractal = GSL_NEGINF;
    for (size_t j = 1; j < i; j++) {
        if (!hg_only && last_wrb == GSL_NEGINF) {
            if (wrb(candle, i - j).dir == 1 &&
                    unfilled(candle, i - j, j, n)) {
                last_wrb = candle[i - j].open;
            }
        } else if (hg_only && last_wrb == GSL_NEGINF) {
            if (wrb_hg(candle, i - j).dir == 1 &&
                    unfilled(candle, i - j, j, n)) {
                last_wrb = candle[i - j].open;
            }
        }
        if (use_fractal && last_fractal == GSL_NEGINF) {
            if (fractal_low(candle, i - j, n, l) == 1 &&
                    candle[i - j].low <= lowest_low(candle, i - j + 1, i))
            last_fractal = candle[i - j].low;
        }
        if(last_wrb != GSL_NEGINF && (last_fractal != GSL_NEGINF || !use_fractal)) {
            break;
        }
    }
    return GSL_MAX_DBL(last_wrb, last_fractal);
}


double resistance(ohlc *candle, size_t i, int hg_only, int use_fractal,
               size_t l, int n) {
    double last_wrb = GSL_POSINF, last_fractal = GSL_POSINF;
    for (size_t j = 1; j < i; j++) {
        if (!hg_only && last_wrb == GSL_POSINF) {
            if (wrb(candle, i - j).dir == -1 &&
                    unfilled(candle, i - j, j, n)) {
                last_wrb = candle[i - j].open;
            }
        } else if (hg_only && last_wrb == GSL_POSINF) {
            if (wrb_hg(candle, i - j).dir == -1 &&
                    unfilled(candle, i - j, j, n)) {
                last_wrb = candle[i - j].open;
            }
        }
        if (use_fractal && last_fractal == GSL_POSINF) {
            if (fractal_high(candle, i - j, n, l) == 1 &&
                    candle[i - j].low <= lowest_high(candle, i - j + 1, i))
            last_fractal = candle[i - j].high;
        }
        if(last_wrb != GSL_POSINF && (last_fractal != GSL_POSINF || !use_fractal)) {
            break;
        }
    }
    return GSL_MIN_DBL(last_wrb, last_fractal);
}
