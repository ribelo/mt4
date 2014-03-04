
#include "wrb_vsa.h"
#include <gsl/gsl_math.h>
#include <float.h>
#include "wrb_struct.h"
#include "candle.h"
#include "wrb_analysis.h"
#include "wrb_zone.h"
#include <stdio.h>


static inline double avg_volume(ohlc *candle, size_t i, size_t lenght) {
    int end_loop = GSL_MIN_INT(lenght, i);
    double avg_vol = 0.0;
    for (int j = 1; j <= end_loop; j++) {
        avg_vol += candle[i - j].volume;
    }
    return avg_vol;
}


signal sd_a(ohlc *candle, size_t i, size_t n) {
    signal r = {};
    if (i < 2 || i > n - 1) {
        return r;
    }

    if (gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) >= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].high, candle[i + 1].high, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = -1;
    } else if (gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) <= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].low, candle[i + 1].low, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = 1;
    }
    return r;
}


signal sd_b(ohlc *candle, size_t i, size_t n) {
    signal r = {};
    if (i < 2 || i > n - 1) {
        return r;
    }
    if (gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) >= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) > 0 &&
            (gsl_fcmp(candle[i].close, candle[i].open, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].high, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].low, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, bar_mid_point(candle, i), FLT_EPSILON) == 0) &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].high, candle[i + 1].high, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = -1;
    } else if (gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) <= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) > 0 &&
            (gsl_fcmp(candle[i].close, candle[i].open, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].high, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].low, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, bar_mid_point(candle, i), FLT_EPSILON) == 0) &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].low, candle[i + 1].low, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = 1;
    }
    return r;
}


signal sd_c(ohlc *candle, size_t i, size_t n) {
    signal r = {};
    if (i < 2 || i > n - 1) {
        return r;
    }
    if (candle[i].close > candle[i - 1].close &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].high, candle[i + 1].high, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = -1;
    } else if (candle[i].close < candle[i - 1].close &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].low, candle[i + 1].low, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = 1;
    }
    return r;
}


signal sd_d(ohlc *candle, size_t i, size_t n) {
    signal r = {};
    if (i < 2 || i > n - 1) {
        return r;
    }
    if (candle[i].close > candle[i - 1].close &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) > 0 &&
            (gsl_fcmp(candle[i].close, candle[i].open, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].high, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].low, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, bar_mid_point(candle, i), FLT_EPSILON) == 0) &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].high, candle[i + 1].high, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = -1;
    } else if (candle[i].close < candle[i - 1].close &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) > 0 &&
            (gsl_fcmp(candle[i].close, candle[i].open, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].high, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].low, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, bar_mid_point(candle, i), FLT_EPSILON) == 0) &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].low, candle[i + 1].low, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = 1;
    }
    return r;
}


signal sd_e(ohlc *candle, size_t i, size_t n) {
    signal r = {};
    if (i < 2 || i > n - 1) {
        return r;
    }
    if (gsl_fcmp(candle[i].close, candle[i - 1].close , FLT_EPSILON) == 0&&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) > 0 &&
            (gsl_fcmp(candle[i].close, candle[i].open, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].high, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].low, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, bar_mid_point(candle, i), FLT_EPSILON) == 0) &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].high, candle[i + 1].high, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = -1;
    } else if (gsl_fcmp(candle[i].close, candle[i - 1].close , FLT_EPSILON) == 0&&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) > 0 &&
            (gsl_fcmp(candle[i].close, candle[i].open, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].high, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].low, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, bar_mid_point(candle, i), FLT_EPSILON) == 0) &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].low, candle[i + 1].low, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = 1;
    }
    return r;
}


signal sd_f(ohlc *candle, size_t i, size_t n) {
    signal r = {};
    if (i < 2 || i > n - 2) {
        return r;
    }
    if (gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) >= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i - 1].close, FLT_EPSILON) >= 0 &&
            (gsl_fcmp(candle[i].close, candle[i].open, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].high, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].low, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, bar_mid_point(candle, i), FLT_EPSILON) == 0) &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) == 0 &&
            gsl_fcmp(candle[i].close, candle[i + 2].close, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].high, candle[i + 1].high, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].high, candle[i + 2].high, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = -1;
    } else if (gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) <= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i - 1].close, FLT_EPSILON) <= 0 &&
            (gsl_fcmp(candle[i].close, candle[i].open, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].high, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].low, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, bar_mid_point(candle, i), FLT_EPSILON) == 0) &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) == 0 &&
            gsl_fcmp(candle[i].close, candle[i + 2].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].low, candle[i + 1].low, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].low, candle[i + 2].low, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = 1;
    }
    return r;
}


signal sd_g(ohlc *candle, size_t i, size_t n) {
    signal r = {};
    if (i < 2 || i > n - 1) {
        return r;
    }
    if (gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) >= 0 &&
            (gsl_fcmp(candle[i].close, candle[i].open, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].high, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].low, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, bar_mid_point(candle, i), FLT_EPSILON) == 0) &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].high, candle[i + 1].high, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) <= 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = -1;
    } else if (gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) <= 0 &&
            (gsl_fcmp(candle[i].close, candle[i].open, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].high, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].low, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, bar_mid_point(candle, i), FLT_EPSILON) == 0) &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].low, candle[i + 1].low, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) <= 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = 1;
    }
    return r;
}


signal sd_h(ohlc *candle, size_t i, size_t n) {
    signal r = {};
    if (i < 2 || i > n - 1) {
        return r;
    }
    if (gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) >= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) <= 0 &&
            (gsl_fcmp(candle[i].close, candle[i].high, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].low, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, bar_mid_point(candle, i), FLT_EPSILON) == 0) &&
            gsl_fcmp(candle[i].close, candle[i].open, FLT_EPSILON) != 0 &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].high, candle[i + 1].high, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) == 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) == 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = -1;
    } else if (gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) <= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) <= 0 &&
            (gsl_fcmp(candle[i].close, candle[i].high, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, candle[i].low, FLT_EPSILON) == 0 ||
             gsl_fcmp(candle[i].close, bar_mid_point(candle, i), FLT_EPSILON) == 0) &&
            gsl_fcmp(candle[i].close, candle[i].open, FLT_EPSILON) != 0 &&
            gsl_fcmp(candle[i].close, candle[i + 1].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].low, candle[i + 1].low, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) == 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) == 0) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = 1;
    }
    return r;
}


signal effort_a(ohlc *candle, size_t i, size_t n) {
    signal r = {};
    if (i < 1) {
        return r;
    }
    if (gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) >= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) == 0 &&
            gsl_fcmp(candle[i].open, candle[i].low + bar_size(candle, i) * 0.1, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i].high - bar_size(candle, i) * 0.1, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].close, candle[i - 1].close, FLT_EPSILON) > 0 &&
            gsl_fcmp(bar_mid_point(candle, i), candle[i - 1].high, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, avg_volume(candle, i, 14), FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, 2 * avg_volume(candle, i, 14), FLT_EPSILON) <= 0 &&
            wrb(candle, i).dir == 1) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = 1;
    } else if (gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) <= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) == 0 &&
            gsl_fcmp(candle[i].open, candle[i].high - bar_size(candle, i) * 0.1, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].close, candle[i].low + bar_size(candle, i) * 0.1, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i - 1].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(bar_mid_point(candle, i), candle[i - 1].low, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, avg_volume(candle, i, 14), FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, 2 * avg_volume(candle, i, 14), FLT_EPSILON) <= 0 &&
            wrb(candle, i).dir == -1) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = -1;
    }
    return r;
}


signal effort_b(ohlc *candle, size_t i, size_t n) {
    signal r = {};
    if (i < 1 || i > n - 1) {
        return r;
    }
    if (gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) >= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].open, candle[i].low + bar_size(candle, i) * 0.2, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i].high - bar_size(candle, i) * 0.2, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].close, candle[i - 1].close, FLT_EPSILON) > 0 &&
            gsl_fcmp(bar_mid_point(candle, i), candle[i - 1].high, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, 2 * avg_volume(candle, i, 14), FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, 4 * avg_volume(candle, i, 14), FLT_EPSILON) <= 0 &&
            wrb(candle, i).dir == 1 &&
            candle[i].close < candle[i + 1].close) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = 1;
    } else if (gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) <= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].open, candle[i].high - bar_size(candle, i) * 0.2, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].close, candle[i].low + bar_size(candle, i) * 0.2, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i - 1].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(bar_mid_point(candle, i), candle[i - 1].low, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, 2 * avg_volume(candle, i, 14), FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, 4 * avg_volume(candle, i, 14), FLT_EPSILON) <= 0 &&
            wrb(candle, i).dir == -1 &&
            candle[i].close > candle[i + 1].close) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = -1;
    }
    return r;
}


signal effort_c(ohlc *candle, size_t i, size_t n) {
    signal r = {};
    if (i < 1 || i > n - 1) {
        return r;
    }
    if (gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) >= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) == 0 &&
            gsl_fcmp(candle[i].open, candle[i].low + bar_size(candle, i) * 0.1, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i].high - bar_size(candle, i) * 0.1, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].close, candle[i - 1].close, FLT_EPSILON) > 0 &&
            gsl_fcmp(bar_mid_point(candle, i), candle[i - 1].high, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, 2 * avg_volume(candle, i, 14), FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, 4 * avg_volume(candle, i, 14), FLT_EPSILON) <= 0 &&
            wrb(candle, i).dir == 1 &&
            candle[i].close < candle[i + 1].close) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = 1;
    } else if (gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) <= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) == 0 &&
            gsl_fcmp(candle[i].open, candle[i].high - bar_size(candle, i) * 0.1, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].close, candle[i].low + bar_size(candle, i) * 0.1, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i - 1].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(bar_mid_point(candle, i), candle[i - 1].low, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, 2 * avg_volume(candle, i, 14), FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, 4 * avg_volume(candle, i, 14), FLT_EPSILON) <= 0 &&
            wrb(candle, i).dir == -1 &&
            candle[i].close > candle[i + 1].close) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = -1;
    }
    return r;
}


signal effort_d(ohlc *candle, size_t i, size_t n) {
    signal r = {};
    if (i < 2) {
        return r;
    }
    if (gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) >= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].open, candle[i].low + bar_size(candle, i) * 0.2, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i].high - bar_size(candle, i) * 0.2, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].close, candle[i - 1].close, FLT_EPSILON) > 0 &&
            gsl_fcmp(bar_mid_point(candle, i), candle[i - 1].high, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, avg_volume(candle, i, 14), FLT_EPSILON) < 0 &&
            wrb(candle, i).dir == 1) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = 1;
    } else if (gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) <= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].open, candle[i].high - bar_size(candle, i) * 0.2, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].close, candle[i].low + bar_size(candle, i) * 0.2, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i - 1].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(bar_mid_point(candle, i), candle[i - 1].low, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, avg_volume(candle, i, 14), FLT_EPSILON) < 0 &&
            wrb(candle, i).dir == -1) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = -1;
    }
    return r;
}


signal effort_e(ohlc *candle, size_t i, size_t n) {
    signal r = {};
    if (i < 2) {
        return r;
    }
    if (gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) >= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) == 0 &&
            gsl_fcmp(candle[i].open, candle[i].low + bar_size(candle, i) * 0.2, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i].high - bar_size(candle, i) * 0.2, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].close, candle[i - 1].close, FLT_EPSILON) > 0 &&
            gsl_fcmp(bar_mid_point(candle, i), candle[i - 1].high, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, avg_volume(candle, i, 14), FLT_EPSILON) > 0 &&
            wrb(candle, i).dir == 1) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = 1;
    } else if (gsl_fcmp(candle[i].low, candle[i - 1].low, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].high, candle[i - 1].high, FLT_EPSILON) <= 0 &&
            gsl_fcmp(bar_size(candle, i), bar_size(candle, i - 1), FLT_EPSILON) == 0 &&
            gsl_fcmp(candle[i].open, candle[i].high - bar_size(candle, i) * 0.2, FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].close, candle[i].low + bar_size(candle, i) * 0.2, FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close, candle[i - 1].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(bar_mid_point(candle, i), candle[i - 1].low, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 1].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, candle[i - 2].volume, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].volume, avg_volume(candle, i, 14), FLT_EPSILON) > 0 &&
            wrb(candle, i).dir == -1) {
        r.c1.nr = i;
        r.c1.dir = dir(candle, i);
        r.dir = -1;
    }
    return r;
}


// signal vsa(ohlc *candle, size_t i, size_t look_for_zone, int nd_ns, int effort, size_t n) {
//     signal r = {};
//     if (nd_ns) {
//         if (r.dir == 0) {
//             r = sd_a(candle, i, n);
//         }
//         if (r.dir == 0) {
//             r = sd_b(candle, i, n);
//         }
//         if (r.dir == 0) {
//             r = sd_c(candle, i, n);
//         }
//         if (r.dir == 0) {
//             r = sd_d(candle, i, n);
//         }
//         if (r.dir == 0) {
//             r = sd_e(candle, i, n);
//         }
//         if (r.dir == 0) {
//             r = sd_f(candle, i, n);
//         }
//         if (r.dir == 0) {
//             r = sd_g(candle, i, n);
//         }
//         if (r.dir == 0) {
//             r = sd_h(candle, i, n);
//         }
//     }
//     if (effort) {
//         if (r.dir == 0) {
//             r = effort_a(candle, i, n);
//         }
//         if (r.dir == 0) {
//             r = effort_b(candle, i, n);
//         }
//         if (r.dir == 0) {
//             r = effort_c(candle, i, n);
//         }
//         if (r.dir == 0) {
//             r = effort_d(candle, i, n);
//         }
//         if (r.dir == 0) {
//             r = effort_e(candle, i, n);
//         }
//     }
//     return r;
// }


signal vsa(ohlc *candle, size_t i, size_t look_for_zone, int nd_ns, int effort, size_t n) {
    signal r = {}, tmp = {};
    if (nd_ns) {
        zone inside_bull = {};
        zone inside_bear = {};
        inside_bull = inside_bull_zone(candle, i, 16, look_for_zone, n);
        inside_bear = inside_bear_zone(candle, i, 16, look_for_zone, n);
        if (r.dir == 0) {
            tmp = sd_a(candle, i, n);
            if (tmp.dir == 1 && inside_bull.v1.dir == 1) {
                r = tmp;
            } else if (tmp.dir == -1 && inside_bear.v1.dir == -1) {
                r = tmp;
            }
        }
        if (r.dir == 0) {
            tmp = sd_a(candle, i, n);
            if (tmp.dir == 1 && inside_bull.v1.dir == 1) {
                r = tmp;
            } else if (tmp.dir == -1 && inside_bear.v1.dir == -1) {
                r = tmp;
            }
        }
        if (r.dir == 0) {
            tmp = sd_a(candle, i, n);
            if (tmp.dir == 1 && inside_bull.v1.dir == 1) {
                r = tmp;
            } else if (tmp.dir == -1 && inside_bear.v1.dir == -1) {
                r = tmp;
            }
        }
        if (r.dir == 0) {
            tmp = sd_a(candle, i, n);
            if (tmp.dir == 1 && inside_bull.v1.dir == 1) {
                r = tmp;
            } else if (tmp.dir == -1 && inside_bear.v1.dir == -1) {
                r = tmp;
            }
        }
        if (r.dir == 0) {
            tmp = sd_a(candle, i, n);
            if (tmp.dir == 1 && inside_bull.v1.dir == 1) {
                r = tmp;
            } else if (tmp.dir == -1 && inside_bear.v1.dir == -1) {
                r = tmp;
            }
        }
        if (r.dir == 0) {
            tmp = sd_a(candle, i, n);
            if (tmp.dir == 1 && inside_bull.v1.dir == 1) {
                r = tmp;
            } else if (tmp.dir == -1 && inside_bear.v1.dir == -1) {
                r = tmp;
            }
        }
        if (r.dir == 0) {
            tmp = sd_a(candle, i, n);
            if (tmp.dir == 1 && inside_bull.v1.dir == 1) {
                r = tmp;
            } else if (tmp.dir == -1 && inside_bear.v1.dir == -1) {
                r = tmp;
            }
        }
        if (r.dir == 0) {
            tmp = sd_a(candle, i, n);
            if (tmp.dir == 1 && inside_bull.v1.dir == 1) {
                r = tmp;
            } else if (tmp.dir == -1 && inside_bear.v1.dir == -1) {
                r = tmp;
            }
        }
    }
    if (effort) {
        if (r.dir == 0) {
            r = effort_a(candle, i, n);
        }
        if (r.dir == 0) {
            r = effort_b(candle, i, n);
        }
        if (r.dir == 0) {
            r = effort_c(candle, i, n);
        }
        if (r.dir == 0) {
            r = effort_d(candle, i, n);
        }
        if (r.dir == 0) {
            r = effort_e(candle, i, n);
        }
    }
    return r;
}
