
#include "wrb_zone.h"
#include <gsl/gsl_math.h>
#include <float.h>
#include "wrb_struct.h"
#include "candle.h"
#include "wrb_toolbox.h"
#include "wrb_confirmation.h"


zone swing_point_1(ohlc *candle, size_t i, size_t contraction, size_t n) {
    zone r = {};
    size_t j, end_loop = GSL_MIN_INT(i, contraction);
    int prior_wrb, swing_point;
    if (wrb_hg(candle, i, n).dir == 1 &&
            volatility_expand(candle, i, 2, 1)) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, n).dir != 0 &&
                    contraction_share(candle, i, i - j) &&
                    broke_bars(candle, i, j) &&
                    contraction_body_size_break(candle, i, i - j)) {
                prior_wrb = prior_bear_wrb_hg(candle, i - j, n);
                if (prior_wrb > 0 && fill_prior_wrb_hg(
                            candle, i, prior_wrb, n)) {
                    if (dir(candle, i - j) == -1) {
                        r.v1.dir = 1;
                        r.v1.open = candle[i].open;
                        r.v1.close = candle[i].close;
                        r.v1.nr = i;
                        r.v2.dir = -1;
                        r.v2.open = candle[i - j].open;
                        r.v2.close = candle[i - j].close;
                        r.v2.nr = i - j;
                        break;
                    } else if (dir(candle, i - j) == 1) {
                        if (gsl_fcmp(candle[i - j].low,
                                     candle[i - j - 1].low,
                                     FLT_EPSILON) < 0) {
                            swing_point = i - j;
                        } else {
                            swing_point = i - j - 1;
                        }
                        if (gsl_fcmp(candle[swing_point].low,
                                     lowest_low(candle, prior_wrb, swing_point),
                                     FLT_EPSILON) < 0) {
                            r.v1.dir = 1;
                            r.v1.open = candle[i].open;
                            r.v1.close = candle[i].close;
                            r.v1.nr = i;
                            r.v2.dir = 1;
                            r.v2.open = candle[i - j].open;
                            r.v2.close = candle[i - j].close;
                            r.v2.nr = i - j;
                            break;
                        }
                    }
                }
            }
        }
    } else if (wrb_hg(candle, i, n).dir == -1 &&
               volatility_expand(candle, i, -2, 1)) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, n).dir != 0 &&
                    contraction_share(candle, i, i - j) &&
                    broke_bars(candle, i, j) &&
                    contraction_body_size_break(candle, i, i - j)) {
                prior_wrb = prior_bull_wrb_hg(candle, i - j, n);
                if (prior_wrb > 0 && fill_prior_wrb_hg(
                            candle, i, prior_wrb, n)) {
                    if (dir(candle, i - j) == 1) {
                        r.v1.dir = -1;
                        r.v1.open = candle[i].open;
                        r.v1.close = candle[i].close;
                        r.v1.nr = i;
                        r.v2.dir = 1;
                        r.v2.open = candle[i - j].open;
                        r.v2.close = candle[i - j].close;
                        r.v2.nr = i - j;
                        break;
                    } else if (dir(candle, i - j) == -1) {
                        if (gsl_fcmp(candle[i - j].high,
                                     candle[i - j - 1].high,
                                     FLT_EPSILON) > 0) {
                            swing_point = i - j;
                        } else {
                            swing_point = i - j - 1;
                        }
                        if (gsl_fcmp(candle[swing_point].high,
                                     highest_high(candle, prior_wrb, swing_point),
                                     FLT_EPSILON) > 0) {
                            r.v1.dir = -1;
                            r.v1.open = candle[i].open;
                            r.v1.close = candle[i].close;
                            r.v1.nr = i;
                            r.v2.dir = -1;
                            r.v2.open = candle[i - j].open;
                            r.v2.close = candle[i - j].close;
                            r.v2.nr = i - j;
                            break;
                        }
                    }
                }
            }
        }
    }
    return r;
}


zone swing_point_2(ohlc *candle, size_t i, size_t contraction, size_t n) {
    zone r = {};
    size_t j, end_loop = GSL_MIN_INT(i, contraction);
    if (wrb_hg(candle, i, n).dir == 1 &&
            volatility_expand(candle, i, 3, 1)) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, n).dir == -1 &&
                    contraction_share(candle, i, i - j) &&
                    broke_bars(candle, i, j) &&
                    contraction_body_size_break(candle, i, i - j)) {
                r.v1.dir = 1;
                r.v1.open = candle[i].open;
                r.v1.close = candle[i].close;
                r.v1.nr = i;
                r.v2.dir = -1;
                r.v2.open = candle[i - j].open;
                r.v2.close = candle[i - j].close;
                r.v2.nr = i - j;
                break;
            }
        }
    } else if (wrb_hg(candle, i, n).dir == -1 &&
               volatility_expand(candle, i, -3, 1)) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, n).dir == 1 &&
                    contraction_share(candle, i, i - j) &&
                    broke_bars(candle, i, j) &&
                    contraction_body_size_break(candle, i, i - j)) {
                r.v1.dir = -1;
                r.v1.open = candle[i].open;
                r.v1.close = candle[i].close;
                r.v1.nr = i;
                r.v2.dir = 1;
                r.v2.open = candle[i - j].open;
                r.v2.close = candle[i - j].close;
                r.v2.nr = i - j;
                break;
            }
        }
    }
    return r;
}


zone swing_point_3(ohlc *candle, size_t i, size_t n) {

    zone r = {};
    int prior_wrb;
    if (gsl_fcmp(shadow_bottom(candle, i), (body_size(candle, i) + shadow_upper(candle, i)), FLT_EPSILON) > 0 &&
            gsl_fcmp(body_size(candle, i), shadow_upper(candle, i), FLT_EPSILON) > 0 &&
            gsl_fcmp(shadow_bottom(candle, i), biggest_shadow_bottom(candle, i - 3, i), FLT_EPSILON) > 0 &&
            gsl_fcmp(shadow_bottom(candle, i), biggest_body(candle, i - 3, i), FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].low, lowest_low(candle, i - 3, i), FLT_EPSILON) < 0) {
        prior_wrb = prior_bear_wrb_hg(candle, i, n);
        if ((prior_wrb > 0 &&
                fill_prior_wrb_hg(candle, i, prior_wrb, n) &&
                gsl_fcmp(candle[i].low, lowest_low(candle, i + 1, i + 17), FLT_EPSILON)) < 0 ||
                (dir(candle, i + 1) == 1 &&
                 dir(candle, i + 2) == 1 &&
                 dir(candle, i + 3) == 1 &&
                 any_wrb_hg_bull(candle, i, i + 3, n))) {
            r.v1.dir = 1;
            r.v1.open = candle[i].low;
            r.v1.close = GSL_MIN_DBL(candle[i].close, candle[i].open);
            r.v1.nr = i;
        }
    } else if (gsl_fcmp(shadow_upper(candle, i), (body_size(candle, i) + shadow_bottom(candle, i)), FLT_EPSILON) > 0 &&
               gsl_fcmp(body_size(candle, i), shadow_bottom(candle, i), FLT_EPSILON) > 0 &&
               gsl_fcmp(shadow_upper(candle, i), biggest_shadow_upper(candle, i - 3, i), FLT_EPSILON) > 0 &&
               gsl_fcmp(shadow_upper(candle, i), biggest_body(candle, i - 3, i), FLT_EPSILON) > 0 &&
               gsl_fcmp(candle[i].high, highest_high(candle, i - 3, i), FLT_EPSILON) > 0) {
        prior_wrb = prior_bull_wrb_hg(candle, i, n);
        if ((prior_wrb > 0 &&
                fill_prior_wrb_hg(candle, i, prior_wrb, n) &&
                gsl_fcmp(candle[i].high, highest_high(candle, i + 1, i + 17), FLT_EPSILON) > 0) ||
                (dir(candle, i + 1) == 1 &&
                 dir(candle, i + 2) == 1 &&
                 dir(candle, i + 3) == 1 &&
                 any_wrb_hg_bear(candle, i, i + 3, n))) {
            r.v1.dir = -1;
            r.v1.open = candle[i].high;
            r.v1.close = GSL_MAX_DBL(candle[i].close, candle[i].open);
            r.v1.nr = i;
        }
    }
    return r;
}


zone strong_continuation_1(ohlc *candle, size_t i, size_t contraction, size_t n) {
    zone r = {};
    size_t j, end_loop = GSL_MIN_INT(i, contraction);
    if (wrb_hg(candle, i, n).dir == 1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, n).dir == 1 &&
                    contraction_share(candle, i, i - j) &&
                    broke_bars(candle, i, j) &&
                    contraction_body_size_break(candle, i, i - j)) {
                if (fractal_break(candle, i, 5, 256, n) > 0) {
                    r.v1.dir = 1;
                    r.v1.open = candle[i].open;
                    r.v1.close = candle[i].close;
                    r.v1.nr = i;
                    r.v2.dir = 1;
                    r.v2.open = candle[i - j].open;
                    r.v2.close = candle[i - j].close;
                    r.v2.nr = i - j;
                    break;
                } else if (fractal_break(candle, i - j, 5, 256, n) > 0) {
                    r.v1.dir = 1;
                    r.v1.open = candle[i - j].open;
                    r.v1.close = candle[i - j].close;
                    r.v1.nr = i - j;
                    r.v2.dir = 1;
                    r.v2.open = candle[i].open;
                    r.v2.close = candle[i].close;
                    r.v2.nr = i;
                    break;
                }
            }
        }
    } else if (wrb_hg(candle, i, n).dir == -1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, n).dir == -1 &&
                    contraction_share(candle, i, i - j) &&
                    broke_bars(candle, i, j) &&
                    contraction_body_size_break(candle, i, i - j)) {
                if (fractal_break(candle, i, 5, 256, n) > 0) {
                    r.v1.dir = -1;
                    r.v1.open = candle[i].open;
                    r.v1.close = candle[i].close;
                    r.v1.nr = i;
                    r.v2.dir = -1;
                    r.v2.open = candle[i - j].open;
                    r.v2.close = candle[i - j].close;
                    r.v2.nr = i - j;
                    break;
                } else if (fractal_break(candle, i - j, 5, 256, n) > 0) {
                    r.v1.dir = -1;
                    r.v1.open = candle[i - j].open;
                    r.v1.close = candle[i - j].close;
                    r.v1.nr = i - j;
                    r.v2.dir = -1;
                    r.v2.open = candle[i].open;
                    r.v2.close = candle[i].close;
                    r.v2.nr = i;
                    break;
                }
            }
        }
    }
    return r;
}


zone strong_continuation_2(ohlc *candle, size_t i, size_t contraction, size_t n) {
    zone r = {};
    size_t j, end_loop = GSL_MIN_INT(i, contraction);
    if (wrb_hg(candle, i, n).dir == 1 &&
            volatility_expand(candle, i, 1, 1) &&
            volatility_expand(candle, i, 1, -1)) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, n).dir == 1 &&
                    gsl_fcmp(lowest_low(candle, i - j - 3, i - j),
                             lowest_low(candle, i - j, i), FLT_EPSILON) < 0 &&
                    contraction_share(candle, i, i - j) &&
                    broke_bars(candle, i, j) &&
                    contraction_body_size_break(candle, i, i - j)) {
                r.v1.dir = 1;
                r.v1.open = candle[i].open;
                r.v1.close = candle[i].close;
                r.v1.nr = i;
                r.v2.dir = 1;
                r.v2.open = candle[i - j].open;
                r.v2.close = candle[i - j].close;
                r.v2.nr = i - j;
                break;
            }
        }
    } else if (wrb_hg(candle, i, n).dir == -1 &&
               volatility_expand(candle, i, -1, 1) &&
               volatility_expand(candle, i, -1, -1)) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, n).dir == -1 &&
                    gsl_fcmp(highest_high(candle, i - j - 3, i - j),
                             highest_high(candle, i - j, i), FLT_EPSILON) > 0 &&
                    contraction_share(candle, i, i - j) &&
                    broke_bars(candle, i, j) &&
                    contraction_body_size_break(candle, i, i - j)) {
                r.v1.dir = -1;
                r.v1.open = candle[i].open;
                r.v1.close = candle[i].close;
                r.v1.nr = i;
                r.v2.dir = -1;
                r.v2.open = candle[i - j].open;
                r.v2.close = candle[i - j].close;
                r.v2.nr = i - j;
                break;
            }
        }
    }
    return r;
}


zone strong_continuation_3(ohlc *candle, size_t i, size_t contraction, size_t n) {
    zone r = {};
    size_t j, end_loop = GSL_MIN_INT(i, contraction);
    if (wrb_hg(candle, i, n).dir == 1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, n).dir == 1 &&
                    gsl_fcmp(body_mid_point(candle, i - j),
                             highest_close(candle, i - j - 3, i - j),
                             FLT_EPSILON) > 0 &&
                    contraction_share(candle, i, i - j) &&
                    broke_bars(candle, i, j) &&
                    contraction_body_size_break(candle, i, i - j)) {
                r.v1.dir = 1;
                r.v1.open = candle[i].open;
                r.v1.close = candle[i].close;
                r.v1.nr = i;
                r.v2.dir = 1;
                r.v2.open = candle[i - j].open;
                r.v2.close = candle[i - j].close;
                r.v2.nr = i - j;
                break;
            }
        }
    } else if (wrb_hg(candle, i, n).dir == -1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, n).dir == -1 &&
                    gsl_fcmp(body_mid_point(candle, i - j),
                             lowest_close(candle, i - j - 3, i - j),
                             FLT_EPSILON) < 0 &&
                    contraction_share(candle, i, i - j) &&
                    broke_bars(candle, i, j) &&
                    contraction_body_size_break(candle, i, i - j)) {
                r.v1.dir = -1;
                r.v1.open = candle[i].open;
                r.v1.close = candle[i].close;
                r.v1.nr = i;
                r.v2.dir = -1;
                r.v2.open = candle[i - j].open;
                r.v2.close = candle[i - j].close;
                r.v2.nr = i - j;
                break;
            }
        }
    }
    return r;
}


zone strong_continuation_4(ohlc *candle, size_t i, size_t contraction, size_t n) {
    zone r = {};
    size_t j, end_loop = GSL_MIN_INT(i, contraction);
    if (wrb_hg(candle, i, n).dir == 1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, n).dir == 1 &&
                    gsl_fcmp(body_size(candle, i),
                             body_size(candle, i - j),
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(candle[i].close,
                             candle[i - j].close,
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(body_mid_point(candle, i - j),
                             lowest_close(candle, i - j + 1, i),
                             FLT_EPSILON) < 0 &&
                    contraction_share(candle, i, i - j) &&
                    broke_bars(candle, i, j) &&
                    contraction_body_size_break(candle, i, i - j)) {
                r.v1.dir = 1;
                r.v1.open = candle[i].open;
                r.v1.close = candle[i].close;
                r.v1.nr = i;
                r.v2.dir = 1;
                r.v2.open = candle[i - j].open;
                r.v2.close = candle[i - j].close;
                r.v2.nr = i - j;
                break;
            }
        }
    } else if (wrb_hg(candle, i, n).dir == -1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, n).dir == -1 &&
                    gsl_fcmp(body_size(candle, i),
                             body_size(candle, i - j),
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(candle[i].close,
                             candle[i - j].close,
                             FLT_EPSILON) < 0 &&
                    gsl_fcmp(body_mid_point(candle, i - j),
                             highest_close(candle, i - j + 1, i),
                             FLT_EPSILON) > 0 &&
                    contraction_share(candle, i, i - j) &&
                    broke_bars(candle, i, j) &&
                    contraction_body_size_break(candle, i, i - j)) {
                r.v1.dir = -1;
                r.v1.open = candle[i].open;
                r.v1.close = candle[i].close;
                r.v1.nr = i;
                r.v2.dir = -1;
                r.v2.open = candle[i - j].open;
                r.v2.close = candle[i - j].close;
                r.v2.nr = i - j;
                break;
            }
        }
    }
    return r;
}



zone reaction_zone(ohlc *candle, size_t i, size_t look_forward, size_t n) {
    zone r = {};
    size_t j, end_loop = GSL_MIN_INT(i, look_forward);
    if (wrb_hg(candle, i, n).dir == 1) {
        for (j = 5; j < end_loop; j++) {
            if (gsl_fcmp(candle[i + j].low, candle[i].open, FLT_EPSILON) <= 0) {
                break;
            }
            if (gsl_fcmp(candle[i + j].low,
                         lowest_low(candle, i + j, i + j),
                         FLT_EPSILON) <= 0 &&
                    gsl_fcmp(candle[i - 1].high,
                             candle[i + j].low,
                             FLT_EPSILON) < 0 &&
                    gsl_fcmp(candle[i + 1].low,
                             candle[i + j].low,
                             FLT_EPSILON) > 0 &&
                    fractal_low(candle, i + j, 5, n)) {
                r.v1.dir = 1;
                r.v1.open = candle[i].open;
                r.v1.close = candle[i].close;
                r.v1.nr = i;
                break;
            }
        }
    } else if (wrb_hg(candle, i, n).dir == -1) {
        for (j = 5; j < end_loop; j++) {
            if (gsl_fcmp(candle[i + j].high, candle[i].open, FLT_EPSILON) >= 0) {
                break;
            }
            if (gsl_fcmp(candle[i + j].high, highest_high(candle, i + j, i + j),
                         FLT_EPSILON) >= 0 &&
                    gsl_fcmp(candle[i - 1].low,
                             candle[i + j].high,
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(candle[i + 1].high, candle[i + j].high,
                             FLT_EPSILON) < 0 &&
                    fractal_high(candle, i + j, 5, n)) {
                r.v1.dir = -1;
                r.v1.open = candle[i].open;
                r.v1.close = candle[i].close;
                r.v1.nr = i;
                break;
            }
        }
    }
    return r;
}


zone wrb_zone(ohlc *candle, size_t i, size_t contraction, size_t n) {
    zone r = {};
    if (!r.v1.dir) {
        r = swing_point_1(candle, i, contraction, n);
    }
    if (!r.v1.dir) {
        r = swing_point_2(candle, i, contraction, n);
    }
    if (!r.v1.dir) {
        r = swing_point_3(candle, i, n);
    }
    if (!r.v1.dir) {
        r = strong_continuation_1(candle, i, contraction, n);
    }
    if (!r.v1.dir) {
        r = strong_continuation_2(candle, i, contraction, n);
    }
    if (!r.v1.dir) {
        r = strong_continuation_3(candle, i, contraction, n);
    }
    if (!r.v1.dir) {
        r = strong_continuation_4(candle, i, contraction, n);
    }
    if (!r.v1.dir) {
        r = reaction_zone(candle, i, contraction, n);
    }
    signal c = conf_h(candle, i, contraction, n);
    if (c.dir != 0) {
        r.v1.dir = c.c1.dir;
        r.v1.open = c.c1.open;
        r.v1.close = c.c1.close;
        r.v1.nr = c.c1.nr;
        r.v2.dir = c.c1.dir;
        r.v2.open = c.c2.open;
        r.v2.close = c.c2.close;
        r.v2.nr = c.c2.nr;
    }
    return r;
}
