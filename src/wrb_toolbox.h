#pragma once

#include "math.h"
#include "wrb_analysis.h"
#include "wrb_struct.h"


static inline int contraction_share(ohlc *candle, size_t c1, size_t c2) {
    for (int i = 1; i < c1 - c2; i++) {
        if (gsl_fcmp(candle[c2].high, candle[c2 + i].low, FLT_EPSILON) < 0 ||
                gsl_fcmp(candle[c2].low, candle[c2 + i].high, FLT_EPSILON) > 0) {
            return 0;
        }
    }
    return 1;
}


static inline int prior_bull_wrb(ohlc *candle, size_t i, size_t n) {
    for (int j = 3; j < fmin(i, 256 + 3); j++) {
        if (wrb(candle, i - j, n).dir == 1 &&
                unfilled(candle, i - j, j, n)) {
            return i - j;
        }
    }
    return -1;
}


static inline int prior_bull_wrb_hg(ohlc *candle, size_t i, size_t n) {
    for (int j = 3; j < fmin(i, 256 + 3); j++) {
        if (wrb_hg(candle, i - j, n).dir == 1 &&
                unfilled(candle, i - j, j, n)) {
            return i - j;
        }
    }
    return -1;
}


static inline int prior_bear_wrb(ohlc *candle, size_t i, size_t n) {
    for (int j = 3; j < fmin(i, 256 + 3); j++) {
        if (wrb(candle, i - j, n).dir == -1 &&
                unfilled(candle, i - j, j, n)) {
            return i - j;
        }
    }
    return -1;
}


static inline int prior_bear_wrb_hg(ohlc *candle, size_t i, size_t n) {
    for (int j = 3; j < fmin(i, 256 + 3); j++) {
        if (wrb_hg(candle, i - j, n).dir == -1 &&
                unfilled(candle, i - j, j, n)) {
            return i - j;
        }
    }
    return -1;
}


static inline int fill_prior_wrb_hg(ohlc *candle, int i,
                                    int prior_wrb, size_t n) {
    if (unfilled(candle, prior_wrb, i - prior_wrb, n) ||
            filled_by(candle, prior_wrb, n) <= filled_by(candle, i, n)
        ) {
        return 1;
    }
    return 0;
}


static inline int contraction_body_size_break(ohlc *candle, size_t c1, size_t c2) {
    return gsl_fcmp(fmin(body_size(candle, c1), body_size(candle, c2)),
                    biggest_body(candle, c2 + 1, c1), FLT_EPSILON) > 0;
}


static inline int volatility_expand(ohlc *candle, size_t i,
                                    int strength, int side) {
    int cc = 0;

    if (strength == -3) { // strong bear expand
        if (side == 1) { // after
            return (dir(candle, i) == -1 &&
                    dir(candle, i + 1) == -1 &&
                    dir(candle, i + 2) == -1 &&
                    gsl_fcmp(candle[i + 1].close,
                             candle[i].close,
                             FLT_EPSILON) < 0 &&
                    gsl_fcmp(candle[i + 2].close,
                             candle[i + 1].close,
                             FLT_EPSILON) < 0);
        } else if (side == -1) { // before
            return (dir(candle, i) == -1 &&
                    dir(candle, i + 1) == -1 &&
                    dir(candle, i + 2) == -1 &&
                    gsl_fcmp(candle[i + 1].close,
                             candle[i].close,
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(candle[i + 2].close,
                             candle[i + 1].close,
                             FLT_EPSILON) > 0);
        }
    } else if (strength == -2) { // bear expand
        if (side == 1) { // after
            for (int j = 1; j < fmin(16 + 1, i); j++) {
                if (gsl_fcmp(candle[i + j].high,
                             candle[i].open,
                             FLT_EPSILON) >= 0) {
                    return 0;
                }
                if (dir(candle, i + j) == -1 && dir(candle, j + i + 1) == -1 &&
                        gsl_fcmp(candle[i + j + 1].close,
                                 candle[i + j].close,
                                 FLT_EPSILON) < 0 &&
                        gsl_fcmp(candle[i + j].close,
                                 candle[i].close,
                                 FLT_EPSILON) < 0) {
                    return 1;
                }
            }
            return 0;
        } else if (side == -1) { // before
            for (int j = 1; j < fmin(16 + 1, i); j++) {
                if (dir(candle, i - j) == -1 && dir(candle, j - i - 1) == -1 &&
                        gsl_fcmp(candle[i - j - 1].close,
                                 candle[i - j].close,
                                 FLT_EPSILON) > 0 &&
                        gsl_fcmp(candle[i - j].close,
                                 candle[i].close,
                                 FLT_EPSILON) > 0) {
                    return 1;
                }
            }
        }
    } else if (strength == -1) { // week bear expand
        if (side == 1) { // after
            for (int j = 1; j < fmin(16 + 1, i); j++) {
                if (dir(candle, i + j) == -1 &&
                        gsl_fcmp(candle[i + j].close,
                                 candle[i].close,
                                 FLT_EPSILON) < 0) {
                    cc++;
                }
                if (cc >= 2) {
                    return 1;
                }
            }
        } else if (side == -1) { // before
            for (int j = 1; j < fmin(16 + 1, i); j++) {
                if (dir(candle, i - j) == -1 &&
                        gsl_fcmp(candle[i - j].close,
                                 candle[i].close,
                                 FLT_EPSILON) > 0) {
                    cc++;
                }
                if (cc >= 2) {
                    return 1;
                }
            }
        }
    } else if (strength == 1) { // week bull expand
        if (side == 1) { // after
            for (int j = 1; j < fmin(16 + 1, i); j++) {
                if (dir(candle, i + j) == 1 &&
                        gsl_fcmp(candle[i + j].close,
                                 candle[i].close,
                                 FLT_EPSILON) > 0) {
                    cc++;
                }
                if (cc >= 2) {
                    return 1;
                }
            }
        } else if (side == -1) { // before
            for (int j = 1; j < fmin(16 + 1, i); j++) {
                if (dir(candle, i - j) == 1 &&
                        gsl_fcmp(candle[i - j].close,
                                 candle[i].close,
                                 FLT_EPSILON) < 0) {
                    cc++;
                }
                if (cc >= 2) {
                    return 1;
                }
            }
        }
    } else if (strength == 2) { // bull expand
        if (side == 1) { // after
            for (int j = 1; j < fmin(16 + 1, i); j++) {
                if (gsl_fcmp(candle[i + j].low,
                             candle[i].open,
                             FLT_EPSILON) <= 0) {
                    return 0;
                }
                if (dir(candle, i + j) == 1 && dir(candle, j + i + 1) == 1 &&
                        gsl_fcmp(candle[i + j + 1].close,
                                 candle[i + j].close,
                                 FLT_EPSILON) > 0 &&
                        gsl_fcmp(candle[i + j].close,
                                 candle[i].close,
                                 FLT_EPSILON) > 0) {
                    return 1;
                }
            }
            return 0;
        } else if (side == -1) { // before
            for (int j = 1; j < fmin(16 + 1, i); j++) {
                if (gsl_fcmp(candle[i - j].low,
                             candle[i].open,
                             FLT_EPSILON) <= 0) {
                    return 0;
                }
                if (dir(candle, i - j) == 1 && dir(candle, j - i - 1) == 1 &&
                        gsl_fcmp(candle[i - j - 1].close,
                                 candle[i - j].close,
                                 FLT_EPSILON) < 0 &&
                        gsl_fcmp(candle[i - j].close,
                                 candle[i].close,
                                 FLT_EPSILON) < 0) {
                    return 1;
                }
            }
            return 0;
        }
    } else if (strength == 3) { // strong bull expand
        if (side == 1) { // after
            return (dir(candle, i) == 1 &&
                    dir(candle, i + 1) == 1 &&
                    dir(candle, i + 2) == 1 &&
                    gsl_fcmp(candle[i + 1].close,
                             candle[i].close,
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(candle[i + 2].close,
                             candle[i + 1].close,
                             FLT_EPSILON) > 0);
        } else if (side == -1) { // before
            return (dir(candle, i) == 1 &&
                    dir(candle, i + 1) == 1 &&
                    dir(candle, i + 2) == 1 &&
                    gsl_fcmp(candle[i + 1].close,
                             candle[i].close,
                             FLT_EPSILON) < 0 &&
                    gsl_fcmp(candle[i + 2].close,
                             candle[i + 1].close,
                             FLT_EPSILON) < 0);
        }
    }
    return 0;
}


static inline int contraction_retrace(ohlc *candle, size_t c1,
                                      size_t c2, size_t n) {
    if (dir(candle, c2) == 1) {
        return (gsl_fcmp(lowest_low(candle, c2 - 3, c2),
                         lowest_low(candle, c2, c1),
                         FLT_EPSILON) < 0);
    } else if (dir(candle, c2) == -1) {
        return (gsl_fcmp(highest_high(candle, c2 - 3, c2),
                         highest_high(candle, c2, c1),
                         FLT_EPSILON) > 0);
    }
    return 0;
}


static inline int zone_bounce(ohlc *candle, size_t i, zone *z) {
    if (dir(candle, i) == 1) {
        if ((gsl_fcmp(candle[i - 1].close,
                      z->v1.close,
                      FLT_EPSILON) <= 0 &&
                gsl_fcmp(candle[i - 1].close,
                         z->v1.open,
                         FLT_EPSILON) > 0 &&
                gsl_fcmp(candle[i].close,
                         z->v1.close,
                         FLT_EPSILON) > 0 &&
                gsl_fcmp(lowest_close(candle, i - 4, i - 1),
                         z->v1.close,
                         FLT_EPSILON) > 0) ||
                (gsl_fcmp(candle[i - 1].close,
                          z->v1.open,
                          FLT_EPSILON) < 0 &&
                 gsl_fcmp(candle[i].close,
                          z->v1.open,
                          FLT_EPSILON) >= 0 &&
                 gsl_fcmp(lowest_close(candle, i - 4, i - 1),
                          z->v1.open,
                          FLT_EPSILON) > 0)) {
            return 1;
        }
    } else if (dir(candle, i) == -1) {
        if ((gsl_fcmp(candle[i - 1].close,
                      z->v1.close,
                      FLT_EPSILON) >= 0 &&
                gsl_fcmp(candle[i - 1].close,
                         z->v1.open,
                         FLT_EPSILON) < 0 &&
                gsl_fcmp(candle[i].close,
                         z->v1.close,
                         FLT_EPSILON) < 0 &&
                gsl_fcmp(highest_close(candle, i - 4, i - 1),
                         z->v1.close,
                         FLT_EPSILON) < 0) ||
                (gsl_fcmp(candle[i - 1].close,
                          z->v1.open,
                          FLT_EPSILON) > 0 &&
                 gsl_fcmp(candle[i].close,
                          z->v1.open,
                          FLT_EPSILON) <= 0 &&
                 gsl_fcmp(highest_close(candle, i - 4, i - 1),
                          z->v1.open,
                          FLT_EPSILON) < 0)) {
            return -1;
        }
    }
    return 0;
}
