
#include "wrb_ajctr.h"
#include <gsl/gsl_math.h>
#include <float.h>
#include "wrb_struct.h"
#include "candle.h"
#include "wrb_toolbox.h"


int deep_shadow_upper(ohlc *candle, size_t i) {
    int j = 0, k = 0;
    while (1) {
        j++, k++;
        if (j >= i  ||
                gsl_fcmp(shadow_upper(candle, i), shadow_upper(candle, i - j), FLT_EPSILON) <= 0 ||
                gsl_fcmp(shadow_upper(candle, i), body_size(candle, i - j), FLT_EPSILON) <= 0) {
            return 0;
        }
        if (wrb(candle, i - j).dir == -1) {
            k = 0;
            continue;
        }
        if (k >= 3) {
            return 1;
        }
    }
    return 0;
}


int deep_shadow_bottom(ohlc *candle, size_t i) {
    int j = 0, k = 0;
    while (1) {
        j++, k++;
        if (j >= i  ||
                gsl_fcmp(shadow_bottom(candle, i), shadow_bottom(candle, i - j), FLT_EPSILON) <= 0 ||
                gsl_fcmp(shadow_bottom(candle, i), body_size(candle, i - j), FLT_EPSILON) <= 0) {
            return 0;
        }
        if (wrb(candle, i - j).dir == 1) {
            k = 0;
            continue;
        }
        if (k >= 3) {
            return 1;
        }
    }
    return 0;
}


int big_body_bull(ohlc *candle, size_t i) {
    int j = 0, k = 0;
    while (1) {
        j++, k++;
        if ((int)i - j < 0) {
            return 1;
        }
        if (wrb(candle, i - j).dir == -1) {
            k = 0;
            continue;
        }
        if (gsl_fcmp(body_size(candle, i), body_size(candle, i - j), FLT_EPSILON) > 0) {
            k++;
        } else {
            return 0;
        }
        if (k >= 3) {
            return 1;
        }
    }
    return 0;
}


int big_body_bear(ohlc *candle, size_t i) {
    int j = 0, k = 0;
    while (1) {
        j++, k++;
        if ((int)i - j < 0) {
            return 1;
        }
        if (wrb(candle, i - j).dir == 1) {
            k = 0;
            continue;
        }
        if (gsl_fcmp(body_size(candle, i), body_size(candle, i - j), FLT_EPSILON) > 0) {
            k++;
        } else {
            return 0;
        }
        if (k >= 3) {
            return 1;
        }
    }
    return 0;
}


signal hammer(ohlc *candle, size_t i) {
    signal r = {};
    if (dir(candle, i) == 1 &&
            gsl_fcmp(body_size(candle, i),
                     shadow_upper(candle, i),
                     FLT_EPSILON) > 0 &&
            gsl_fcmp(shadow_bottom(candle, i),
                     (body_size(candle, i) + shadow_upper(candle, i)),
                     FLT_EPSILON) > 0 &&
            deep_shadow_bottom(candle, i) &&
            gsl_fcmp(candle[i].low,
                     lowest_low(candle, i - 3, i),
                     FLT_EPSILON) < 0 &&
            gsl_fcmp(highest_low(candle, i - 3, i),
                     candle[i].open, FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].close, highest_high(candle, i - 2, i),
                     FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].close,
                     GSL_MIN_DBL(candle[i - 1].open, candle[i - 1].close),
                     FLT_EPSILON) > 0) {
        r.c1.nr = i;
        r.c1.dir = 1;
        r.dir = 1;
    } else if (dir(candle, i) == -1 &&
               gsl_fcmp(body_size(candle, i),
                        shadow_bottom(candle, i),
                        FLT_EPSILON) > 0 &&
               gsl_fcmp(shadow_upper(candle, i),
                        (body_size(candle, i) + shadow_bottom(candle, i)),
                        FLT_EPSILON) > 0 &&
               deep_shadow_upper(candle, i) &&
               gsl_fcmp(candle[i].high,
                        highest_high(candle, i - 3, i), FLT_EPSILON) > 0 &&
               gsl_fcmp(lowest_high(candle, i - 3, i),
                        candle[i].open,
                        FLT_EPSILON) < 0 &&
               gsl_fcmp(candle[i].close,
                        lowest_low(candle, i - 2, i),
                        FLT_EPSILON) >= 0 &&
               gsl_fcmp(candle[i].close,
                        GSL_MAX_DBL(candle[i - 1].open, candle[i - 1].close),
                        FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = -1;
        r.dir = -1;
    }
    return r;
}


signal harami(ohlc *candle, size_t i) {
    signal r = {};
    if (wrb_hg(candle, i - 2, i).dir == -1 &&
            gsl_fcmp(GSL_MAX_DBL(candle[i - 1].high, candle[i].high),
                     candle[i - 2].open,
                     FLT_EPSILON) < 0 &&
            (gsl_fcmp(candle[i].close,
                      candle[i - 1].high,
                      FLT_EPSILON) > 0 ||
             gsl_fcmp(candle[i].close,
                      body_mid_point(candle, i - 2),
                      FLT_EPSILON)) == 1 &&
            gsl_fcmp(candle[i].close,
                     candle[i - 2].open,
                     FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].open,
                     candle[i - 1].close,
                     FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].low,
                     candle[i - 1].low,
                     FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].high,
                     body_mid_point(candle, i - 2),
                     FLT_EPSILON) > 0 &&
            gsl_fcmp(body_size(candle, i),
                     smalest_body(candle, i - 3, i),
                     FLT_EPSILON) < 0 &&
            gsl_fcmp(lowest_high(candle, i - 5, i - 2),
                     candle[i - 2].open,
                     FLT_EPSILON) > 0 &&
            gsl_fcmp(lowest_body(candle, i - 5, i - 2),
                     body_mid_point(candle, i - 2),
                     FLT_EPSILON) >= 0 &&
            gsl_fcmp(lowest_low(candle, i - 5, i - 2),
                     candle[i - 2].close,
                     FLT_EPSILON) > 0) {
        r.c1.nr = i;
        r.c1.dir = 1;
        r.c2.nr = i - 2;
        r.dir = 1;
    } else if (wrb_hg(candle, i - 2, i).dir == 1 &&
               gsl_fcmp(GSL_MIN_DBL(candle[i - 1].low, candle[i].low),
                        candle[i - 2].open,
                        FLT_EPSILON) > 0 &&
               (gsl_fcmp(candle[i].close,
                         candle[i - 1].low,
                         FLT_EPSILON) < 0 ||
                gsl_fcmp(candle[i].close,
                         body_mid_point(candle, i - 2),
                         FLT_EPSILON)) == -1 &&
               gsl_fcmp(candle[i].close,
                        candle[i - 2].open,
                        FLT_EPSILON) > 0 &&
               gsl_fcmp(candle[i].open,
                        candle[i - 1].close,
                        FLT_EPSILON) <= 0 &&
               gsl_fcmp(candle[i].high,
                        candle[i - 1].high,
                        FLT_EPSILON) <= 0 &&
               gsl_fcmp(candle[i].low,
                        body_mid_point(candle, i - 2),
                        FLT_EPSILON) < 0 &&
               gsl_fcmp(body_size(candle, i),
                        smalest_body(candle, i - 3, i),
                        FLT_EPSILON) < 0 &&
               gsl_fcmp(highest_low(candle, i - 5, i - 2),
                        candle[i - 2].open,
                        FLT_EPSILON) < 0 &&
               gsl_fcmp(highest_body(candle, i - 5, i - 2),
                        body_mid_point(candle, i - 2),
                        FLT_EPSILON) <= 0 &&
               gsl_fcmp(highest_high(candle, i - 5, i - 2),
                        candle[i - 2].close,
                        FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = -1;
        r.c2.nr = i - 2;
        r.dir = -1;
    }
    return r;
}


signal engulfing(ohlc *candle, size_t i) {
    signal r = {};
    if (dir(candle, i) == 1 &&
            dir(candle, i - 2) == -1 &&
            gsl_fcmp(shadow_bottom(candle, i - 1),
                     (body_size(candle, i - 1) + shadow_upper(candle, i - 1)),
                     FLT_EPSILON) > 0 &&
            deep_shadow_bottom(candle, i - 1) == 1  &&
            gsl_fcmp(candle[i - 1].low,
                     lowest_low(candle, i - 4, i -1),
                     FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].close,
                     candle[i - 2].open,
                     FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].open,
                     candle[i - 2].close,
                     FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i - 2].close,
                     candle[i - 1].open,
                     FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i - 2].open,
                     candle[i - 1].high,
                     FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].low,
                     candle[i - 1].low,
                     FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].close,
                     highest_high(candle, i - 3, i),
                     FLT_EPSILON) <= 0 &&
            big_body_bull(candle, i)) {
        r.c1.nr = i;
        r.c1.dir = 1;
        r.c2.nr = i - 4;
        r.dir = 1;
    } else if (dir(candle, i) == -1 &&
               dir(candle, i - 2) == 1 &&
               gsl_fcmp(shadow_upper(candle, i - 1),
                        (body_size(candle, i - 1) + shadow_bottom(candle, i - 1)),
                        FLT_EPSILON) > 0 &&
               deep_shadow_upper(candle, i - 1) == 1 &&
               gsl_fcmp(candle[i - 1].high,
                     highest_high(candle, i - 4, i -1),
                     FLT_EPSILON) > 0 &&
               gsl_fcmp(candle[i].close,
                        candle[i - 2].open,
                        FLT_EPSILON) < 0 &&
               gsl_fcmp(candle[i].open,
                        candle[i - 2].close,
                        FLT_EPSILON) > 0 &&
               gsl_fcmp(candle[i - 2].close,
                        candle[i - 1].open,
                        FLT_EPSILON) <= 0 &&
               gsl_fcmp(candle[i - 2].open,
                        candle[i - 1].low,
                        FLT_EPSILON) < 0 &&
               gsl_fcmp(candle[i].high,
                        candle[i - 1].high,
                        FLT_EPSILON) < 0 &&
               gsl_fcmp(candle[i].close,
                        lowest_low(candle, i - 3, i),
                        FLT_EPSILON) >= 0 &&
               big_body_bear(candle, i)) {
        r.c1.nr = i;
        r.c1.dir = -1;
        r.c2.nr = i - 4;
        r.dir = -1;
    }
    return r;
}


signal soldiers(ohlc *candle, size_t i, size_t n) {
    size_t j, end_loop = GSL_MIN(i, 16);
    signal r = {};
    if (wrb(candle, i).dir == 1 && dir(candle, i - 1) == 1) {
        for (j = 3; j < end_loop; j++) {
            if (wrb_hg(candle, i - j, i).dir == -1 &&
                    dir(candle, i - j + 1) == -1 &&
                    unfilled(candle, i - j, j) &&
                    gsl_fcmp(candle[i - j + 1].close,
                             candle[i - j].close,
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(body_mid_point(candle, i),
                             lowest_body(candle, i - j - 3, i - j),
                             FLT_EPSILON) <= 0 &&
                    gsl_fcmp(GSL_MIN_DBL(candle[i - j].low, candle[i - j + 1].low),
                             lowest_body(candle, i - j + 2, i),
                             FLT_EPSILON) < 0 &&
                    gsl_fcmp(GSL_MIN_DBL(shadow_bottom(candle, i - j),
                                         shadow_bottom(candle, i - j + 1)),
                             biggest_body(candle, i - j + 2, i),
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(highest_body(candle, i - j + 1, i),
                             body_mid_point(candle, i - j),
                             FLT_EPSILON) <= 0 &&
                    gsl_fcmp(lowest_low(candle, i - j + 2, i),
                             GSL_MAX_DBL(candle[i - j].close,
                                         candle[i - j + 1].close),
                             FLT_EPSILON) < 0 &&
                    gsl_fcmp(body_size(candle, i),
                             biggest_shadow_upper(candle, i - j + 1, i),
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(candle[i].close,
                             candle[i - 1].close,
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(highest_body(candle, i - j + 1, i),
                             body_mid_point(candle, i),
                             FLT_EPSILON) <= 0 &&
                    gsl_fcmp(candle[i].open,
                             body_mid_point(candle, i - j),
                             FLT_EPSILON) < 0 &&
                    gsl_fcmp(shadow_upper(candle, i),
                             shadow_bottom(candle, i),
                             FLT_EPSILON) < 0) {
                r.c1.nr = i;
                r.c1.dir = 1;
                r.c2.nr = i - j;
                r.dir = 1;
            }
        }
    } else if (wrb(candle, i).dir == -1 && dir(candle, i - 1) == -1) {
        for (j = 3; j < end_loop; j++) {
            if (wrb_hg(candle, i - j, i).dir == 1 &&
                    dir(candle, i - j + 1) == 1 &&
                    unfilled(candle, i - j, j) &&
                    gsl_fcmp(candle[i - j + 1].close,
                             candle[i - j].close,
                             FLT_EPSILON) < 0 &&
                    gsl_fcmp(body_mid_point(candle, i),
                             highest_body(candle, i - j - 3, i - j),
                             FLT_EPSILON) >= 0 &&
                    gsl_fcmp(GSL_MIN_DBL(candle[i - j].low, candle[i - j + 1].low),
                             highest_body(candle, i - j + 2, i),
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(GSL_MIN_DBL(shadow_upper(candle, i - j),
                                         shadow_upper(candle, i - j + 1)),
                             biggest_body(candle, i - j + 2, i),
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(lowest_body(candle, i - j + 1, i),
                             body_mid_point(candle, i - j),
                             FLT_EPSILON) >= 0 &&
                    gsl_fcmp(highest_high(candle, i - j + 2, i),
                             GSL_MAX_DBL(candle[i - j].close,
                                         candle[i - j + 1].close),
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(body_size(candle, i),
                             biggest_shadow_bottom(candle, i - j + 1, i),
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(candle[i].close,
                             candle[i - 1].close,
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(lowest_body(candle, i - j + 1, i),
                             body_mid_point(candle, i),
                             FLT_EPSILON) >= 0 &&
                    gsl_fcmp(candle[i].open,
                             body_mid_point(candle, i - j),
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(shadow_bottom(candle, i),
                             shadow_upper(candle, i),
                             FLT_EPSILON) < 0) {
                r.c1.nr = i;
                r.c1.dir = 1;
                r.c2.nr = i - j;
                r.dir = -1;
            }
        }
    }
    return r;
}
