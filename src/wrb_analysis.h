#pragma once

#include "math.h"
#include "wrb_struct.h"
#include "candle.h"


static inline body wrb(ohlc *candle, size_t i) {
    body r = {};
    if (broke_body_size(candle, i, 3) &&
            broke_bars(candle, i, 3)) {
        if (dir(candle, i) == 1) {
            r.dir = 1;
        } else if (dir(candle, i) == -1) {
            r.dir = -1;
        }
    }
    return r;
}


static inline int any_wrb(ohlc *candle, int start, int stop, int n) {
    size_t i;
    for (i = start; i < stop; i++) {
        if (wrb(candle, i).dir != 0) {
            return 1;
        }
    }
    return 0;
}


static inline int any_wrb_bull(ohlc *candle, int start, int stop, int n) {
    size_t i;
    for (i = start; i < stop; i++) {
        if (wrb(candle, i).dir == 1) {
            return 1;
        }
    }
    return 0;
}


static inline int any_wrb_bear(ohlc *candle, int start, int stop, int n) {
    size_t i;
    for (i = start; i < stop; i++) {
        if (wrb(candle, i).dir == -1) {
            return 1;
        }
    }
    return 0;
}


static inline body wrb_hg(ohlc *candle, size_t i, size_t n) {
    body r = {};
    if (i < n) {
        body _wrb = wrb(candle, i);
        double _gap = gap(candle, i);
        if (_wrb.dir == 1 &&
                gap > 0) {
            r.dir = 1;
            r.open = candle[i].open;
            r.close = candle[i].close;
        } else if (_wrb.dir == -1 &&
                   _gap > 0) {
            r.dir = -1;
            r.open = candle[i].open;
            r.close = candle[i].close;
        }
    }
    return r;
}


static inline int any_wrb_hg(ohlc *candle, int start, int stop, int n) {
    size_t i;
    for (i = start; i < stop; i++) {
        if (wrb_hg(candle, i, n).dir != 0) {
            return 1;
        }
    }
    return 0;
}


static inline int any_wrb_hg_bull(ohlc *candle, int start, int stop, int n) {
    size_t i;
    for (i = start; i < stop; i++) {
        if (wrb_hg(candle, i, n).dir == 1) {
            return 1;
        }
    }
    return 0;
}


static inline int any_wrb_hg_bear(ohlc *candle, int start, int stop, int n) {
    size_t i;
    for (i = start; i < stop; i++) {
        if (wrb_hg(candle, i, n).dir == -1) {
            return 1;
        }
    }
    return 0;
}


static inline int fractal_high(ohlc *candle, size_t i, size_t l, size_t n) {
    int j, up = 0;
    for (j = 1; j < fmin(i - l, n - i - l); j++) {
        if (gsl_fcmp(candle[i].high, candle[i - j].high, FLT_EPSILON) > 0 &&
                gsl_fcmp(candle[i].high, candle[i + j].high, FLT_EPSILON) > 0) {
            up++;
        } else {
            return 0;
        }
        if (up >= l) {
            return 1;
        }
    }
    return 0;
}


static inline int fractal_low(ohlc *candle, size_t i, size_t l, size_t n) {
    int j, dn = 0;
    for (j = 1; j < fmin(i - l, n - i - l); j++) {
        if (gsl_fcmp(candle[i].low, candle[i - j].low, FLT_EPSILON) < 0 &&
                gsl_fcmp(candle[i].low, candle[i + j].low, FLT_EPSILON) < 0) {
            dn++;
        } else {
            return 0;
        }
        if (dn >= l) {
            return 1;
        }
    }
    return 0;
}


static inline int fractal(ohlc *candle, size_t i, size_t n, size_t l) {
    if (fractal_high(candle, i, l, n) == 1) {
        return -1;
    } else if (fractal_low(candle, i, l, n) == 1) {
        return 1;
    }
    return 0;
}


static inline int fractal_break(ohlc *candle, size_t i, size_t l,
                                size_t look_back, size_t n) {
    int j, end_loop = fmin(fmin(i - l, n - i - l), look_back);;
    if (dir(candle, i) == 1) {
        for (j = 1; j < end_loop; j++) {
            if (gsl_fcmp(candle[i - j].high,
                         candle[i].close,
                         FLT_EPSILON) >= 0) {
                return 0;
            }
            if (fractal(candle, j, n, l) == -1 &&
                    gsl_fcmp(candle[i].close,
                             candle[i - j].high,
                             FLT_EPSILON) > 0 &&
                    gsl_fcmp(candle[i].open,
                             candle[i - j].high,
                             FLT_EPSILON) < 0) {
                return i - j;
            }
        }
    } else if (dir(candle, i) == -1) {
        for (j = 1; j < end_loop; j++) {
            if (gsl_fcmp(candle[i - j].low,
                         candle[i].close,
                         FLT_EPSILON) <= 0) {
                return 0;
            }
            if (fractal(candle, j, n, l) == 1 &&
                    gsl_fcmp(candle[i].close,
                             candle[i - j].low,
                             FLT_EPSILON) < 0 &&
                    gsl_fcmp(candle[i].open,
                             candle[i - j].low,
                             FLT_EPSILON) > 0) {
                return -(i - j);
            }
        }
    }
    return 0;
}


static inline signal fade_volatility(ohlc *candle, size_t i) {
    signal r = {};
    if (i > 1 && wrb(candle, i - 1).dir == -1 &&
            gsl_fcmp(candle[i].close,
                     body_mid_point(candle, i - 1),
                     FLT_EPSILON) > 0) {
        r.c1.nr = i;
        r.c1.dir = 1;
        r.c1.open = candle[i].open;
        r.c1.close = candle[i].close;
        r.c2.nr = i - 1;
        r.c2.dir = -1;
        r.c2.open = candle[i - 1].open;
        r.c2.close = candle[i - 1].close;
        r.dir = 1;
    } else if (i > 1 && wrb(candle, i - 1).dir == 1 &&
            gsl_fcmp(candle[i].close,
                     body_mid_point(candle, i - 1),
                     FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = -1;
        r.c1.open = candle[i].open;
        r.c1.close = candle[i].close;
        r.c2.nr = i - 1;
        r.c2.dir = 1;
        r.c2.open = candle[i - 1].open;
        r.c2.close = candle[i - 1].close;
        r.dir = -1;
    }
    return r;
}


static inline int dcm(ohlc *candle, size_t i, size_t n) {
    size_t j;
    if (i < n - 3) {
        if (wrb_hg(candle, i, n).dir == 1) {
            for (j = 1; j < i; j++) {
                if (wrb_hg(candle, i - j, n).dir == -1) {
                    if (gsl_fcmp(candle[i].close,
                                 candle[i - j].open,
                                 FLT_EPSILON) > 0 &&
                            unfilled(candle, i, 3, n)) {
                        return 1;
                    } else {
                        break;
                    }
                }
            }
        } else if (wrb_hg(candle, i, n).dir == -1) {
            for (j = 1; j < i; j++) {
                if (wrb_hg(candle, i - j, n).dir == 1) {
                        if (gsl_fcmp(candle[i].close,
                                 candle[i - j].open,
                                 FLT_EPSILON) < 0 &&
                            unfilled(candle, i, 3, n)) {
                        return -1;
                    }  else {
                        break;
                    }
                }
            }
        }
    }
    return 0;
}
