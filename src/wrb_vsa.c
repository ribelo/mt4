
#include "wrb_vsa.h"
#include <gsl/gsl_math.h>
#include <float.h>
#include "wrb_struct.h"
#include "candle.h"
#include "wrb_zone.h"
#include <stdio.h>

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


signal vsa(ohlc *candle, size_t i, size_t look_for_zone, size_t n) {
    signal r = {};
    if (r.dir == 0) {
        r = sd_a(candle, i, n);
    } else if (r.dir == 0) {
        r = sd_b(candle, i, n);
    } else if (r.dir == 0) {
        r = sd_c(candle, i, n);
    } else if (r.dir == 0) {
        r = sd_d(candle, i, n);
    } else if (r.dir == 0) {
        r = sd_e(candle, i, n);
    } else if (r.dir == 0) {
        r = sd_f(candle, i, n);
    } else if (r.dir == 0) {
        r = sd_g(candle, i, n);
    } else if (r.dir == 0) {
        r = sd_h(candle, i, n);
    }
    return r;
}