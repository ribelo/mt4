
#include "wrb_struct.h"
#include "candle.h"
#include "wrb_toolbox.h"


signal conf_a(ohlc *candle, size_t i) {
    signal r = {};
    if (wrb(candle, i - 2, i).dir == -1 &&
            ((dir(candle, i - 1) == -1 &&
              gsl_fcmp(candle[i - 1].close,
                       candle[i - 2].close,
                       FLT_EPSILON) < 0) ||
             (dir(candle, i - 1) == 0 &&
              gsl_fcmp(candle[i - 1].low,
                       candle[i - 2].close,
                       FLT_EPSILON) < 0)) &&
            dir(candle, i) == 1 &&
            gsl_fcmp(candle[i].close,
                     candle[i - 1].open,
                     FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].close,
                     body_mid_point(candle, i - 2),
                     FLT_EPSILON) > 0) {
        r.c1.nr = i;
        r.c1.dir = 1;
        r.c2.nr = i - 2;
        r.dir = 1;
    } else if (wrb(candle, i - 2, i).dir == 1 &&
               ((dir(candle, i - 1) == 1 &&
                 gsl_fcmp(candle[i - 1].close,
                          candle[i - 2].close,
                          FLT_EPSILON) > 0) ||
                (dir(candle, i - 1) == 0 &&
                 gsl_fcmp(candle[i - 1].high,
                          candle[i - 2].close,
                          FLT_EPSILON) > 0)) &&
               dir(candle, i) == -1 &&
               gsl_fcmp(candle[i].close,
                        candle[i - 1].open,
                        FLT_EPSILON) < 0 &&
               gsl_fcmp(candle[i].close,
                        body_mid_point(candle, i - 2),
                        FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = -1;
        r.c2.nr = i - 2;
        r.c2.dir = -1;
        r.dir = -1;
    }
    return r;
}


signal conf_b(ohlc *candle, size_t i) {
    signal r = {};
    if (dir(candle, i - 2) == -1 &&
            wrb(candle, i - 1, i).dir == -1 &&
            dir(candle, i) == 1 &&
            gsl_fcmp(candle[i].low,
                     candle[i - 1].close,
                     FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].open,
                     body_mid_point(candle, i - 1),
                     FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].close,
                     body_mid_point(candle, i - 1),
                     FLT_EPSILON) > 0 &&
            gsl_fcmp(body_size(candle, i),
                     biggest_body(candle, i - 4, i - 1),
                     FLT_EPSILON) > 0) {
        r.c1.nr = i;
        r.c1.dir = 1;
        r.c2.nr = i - 2;
        r.dir = 1;
    } else if (dir(candle, i - 2) == 1 &&
               wrb(candle, i - 1, i).dir == 1 &&
               dir(candle, i) == -1 &&
               gsl_fcmp(candle[i].high,
                        candle[i - 1].close,
                        FLT_EPSILON) > 0 &&
               gsl_fcmp(candle[i].open,
                        body_mid_point(candle, i - 1),
                        FLT_EPSILON) > 0 &&
               gsl_fcmp(candle[i].close,
                        body_mid_point(candle, i - 1),
                        FLT_EPSILON) < 0 &&
               gsl_fcmp(body_size(candle, i),
                        biggest_body(candle, i - 4, i - 1),
                        FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = -1;
        r.c2.nr = i - 2;
        r.c2.dir = -1;
        r.dir = -1;
    }
    return r;
}


signal conf_c(ohlc *candle, size_t i) {
    signal r = {};
    if (wrb(candle, i - 2, i).dir == -1 &&
            dir(candle, i - 1) == 1 &&
            dir(candle, i) == 1 &&
            gsl_fcmp(candle[i].close,
                     candle[i - 1].close,
                     FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i - 1].open,
                     candle[i - 2].close,
                     FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i - 1].low,
                     candle[i - 2].close,
                     FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].low,
                     candle[i - 2].close,
                     FLT_EPSILON) >= 0 &&
            gsl_fcmp(candle[i].close,
                     candle[i - 2].open,
                     FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].high,
                     candle[i - 2].open,
                     FLT_EPSILON) <= 0 &&
            gsl_fcmp(candle[i].high,
                     body_mid_point(candle, i - 2),
                     FLT_EPSILON) > 0 &&
            (gsl_fcmp(body_size(candle, i - 1),
                      smalest_body(candle, i - 5, i - 2),
                      FLT_EPSILON) < 0 ||
             gsl_fcmp(shadow_bottom(candle, i),
                      biggest_shadow_bottom(candle, i - 5, i - 2),
                      FLT_EPSILON) > 0) &&
            gsl_fcmp(lowest_high(candle, i - 5, i - 2),
                     candle[i - 2].open,
                     FLT_EPSILON) > 0) {
        r.c1.nr = i;
        r.c1.dir = 1;
        r.c2.nr = i - 2;
        r.dir = 1;
    } else if (wrb(candle, i - 2, i).dir == 1 &&
               dir(candle, i - 1) == -1 &&
               dir(candle, i) == -1 &&
               gsl_fcmp(candle[i].close,
                        candle[i - 1].close,
                        FLT_EPSILON) < 0 &&
               gsl_fcmp(candle[i - 1].open,
                        candle[i - 2].close,
                        FLT_EPSILON) <= 0 &&
               gsl_fcmp(candle[i - 1].high,
                        candle[i - 2].close,
                        FLT_EPSILON) > 0 &&
               gsl_fcmp(candle[i].high,
                        candle[i - 2].close,
                        FLT_EPSILON) <= 0 &&
               gsl_fcmp(candle[i].close,
                        candle[i - 2].open,
                        FLT_EPSILON) > 0 &&
               gsl_fcmp(candle[i].low,
                        candle[i - 2].open,
                        FLT_EPSILON) >= 0 &&
               gsl_fcmp(candle[i].low,
                        body_mid_point(candle, i - 2),
                        FLT_EPSILON) < 0 &&
               (gsl_fcmp(body_size(candle, i - 1),
                         smalest_body(candle, i - 5, i - 2),
                         FLT_EPSILON) < 0 ||
                gsl_fcmp(shadow_upper(candle, i),
                         biggest_shadow_upper(candle, i - 5, i - 2),
                         FLT_EPSILON) > 0) &&
               gsl_fcmp(highest_low(candle, i - 5, i - 2),
                        candle[i - 2].open,
                        FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = -1;
        r.c2.nr = i - 2;
        r.c2.dir = -1;
        r.dir = -1;
    }
    return r;
}


signal conf_d(ohlc *candle, size_t i) {
    signal r = {};
    if (dir(candle, i - 2) == -1 &&
            dir(candle, i - 1) != 0 &&
            dir(candle, i) == 1) {
        if (gsl_fcmp(candle[i].open,
                     candle[i - 1].close,
                     FLT_EPSILON) < 0 &&
                gsl_fcmp(candle[i].close,
                         candle[i - 1].open,
                         FLT_EPSILON) > 0 &&
                gsl_fcmp(candle[i - 1].open,
                         candle[i - 2].low, FLT_EPSILON) < 0) {
            r.c1.nr = i;
            r.c1.dir = 1;
            r.c2.nr = i - 2;
            r.c2.dir = -1;
            r.dir = 1;
        } else if (gsl_fcmp(candle[i].open,
                            candle[i - 2].close,
                            FLT_EPSILON) < 0 &&
                   gsl_fcmp(candle[i].close,
                            candle[i - 2].open,
                            FLT_EPSILON) > 0 &&
                   gsl_fcmp(candle[i - 1].high,
                            candle[i - 2].open,
                            FLT_EPSILON) < 0 &&
                   gsl_fcmp(fmax(candle[i - 1].open, candle[i - 1].close),
                            candle[i - 2].low,
                            FLT_EPSILON) < 0) {
            r.c1.nr = i;
            r.c1.dir = 1;
            r.c2.nr = i - 2;
            r.dir = 1;
        }
    } else if (dir(candle, i - 2) == 1 &&
               dir(candle, i - 1) != 0 &&
               dir(candle, i) == -1) {
        if (gsl_fcmp(candle[i].open,
                     candle[i - 1].close,
                     FLT_EPSILON) > 0 &&
                gsl_fcmp(candle[i].close,
                         candle[i - 1].open,
                         FLT_EPSILON) < 0 &&
                gsl_fcmp(candle[i - 1].open,
                         candle[i - 2].high, FLT_EPSILON) > 0) {
            r.c1.nr = i;
            r.c1.dir = -1;
            r.c2.nr = i - 2;
            r.c2.dir = -1;
            r.dir = -1;
        } else if (gsl_fcmp(candle[i].open,
                            candle[i - 2].close,
                            FLT_EPSILON) > 0 &&
                   gsl_fcmp(candle[i].close,
                            candle[i - 2].open,
                            FLT_EPSILON) < 0 &&
                   gsl_fcmp(candle[i - 1].low,
                            candle[i - 2].open,
                            FLT_EPSILON) > 0 &&
                   gsl_fcmp(fmin(candle[i - 1].open, candle[i - 1].close),
                            candle[i - 2].high,
                            FLT_EPSILON) > 0) {
            r.c1.nr = i;
            r.c1.dir = -1;
            r.c2.nr = i - 2;
            r.c2.dir = -1;
            r.dir = -1;
        }
    }
    return r;
}


signal conf_e(ohlc *candle, size_t i) {
    signal r = {};
    if (dir(candle, i - 3) == -1 &&
            dir(candle, i - 2) == -1 &&
            dir(candle, i - 1) == 1 &&
            dir(candle, i) == 1 &&
            gsl_fcmp(candle[i - 1].open,
                     candle[i - 2].close,
                     FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].close,
                     candle[i - 1].close,
                     FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i].close,
                     candle[i - 2].open,
                     FLT_EPSILON) > 0 &&
            gsl_fcmp(candle[i - 2].close,
                     candle[i - 3].close, FLT_EPSILON) < 0 &&
            gsl_fcmp(candle[i].close,
                     body_mid_point(candle, i - 3),
                     FLT_EPSILON) < 0) {
        r.c1.nr = i;
        r.c1.dir = 1;
        r.c2.nr = i - 3;
        r.dir = 1;
    } else if (dir(candle, i - 3) == 1 &&
               dir(candle, i - 2) == 1 &&
               dir(candle, i - 1) == -1 &&
               dir(candle, i) == -1 &&
               gsl_fcmp(candle[i - 1].open,
                        candle[i - 2].close,
                        FLT_EPSILON) > 0 &&
               gsl_fcmp(candle[i].close,
                        candle[i - 1].close,
                        FLT_EPSILON) < 0 &&
               gsl_fcmp(candle[i].close,
                        candle[i - 2].open,
                        FLT_EPSILON) < 0 &&
               gsl_fcmp(candle[i - 2].close,
                        candle[i - 3].close, FLT_EPSILON) > 0 &&
               gsl_fcmp(candle[i].close,
                        body_mid_point(candle, i - 3),
                        FLT_EPSILON) > 0) {
        r.c1.nr = i;
        r.c1.dir = -1;
        r.c2.nr = i - 3;
        r.c2.dir = -1;
        r.dir = -1;
    }
    return r;
}


// signal conf_f(ohlc *candle, size_t i, size_t n) {
//  signal r = {};
//  int j;
//  if (wrb(candle,.dir i) == 1) {
//      for (j = 3; j < 16; j++) {
//          if (any)
//          if () {
//              r.c1.nr = i;
//              r.c1.dir = 1;
//              r.c2.nr = i - 2;
// 2            r.c1.dir = 1;
//              r.dir = 1;
//          }
//      }
//  } else if () {
//      r.c1.nr = i;
//      r.c1.dir = -1;
//      r.c2.nr = i - 2;
// 2    r.c1.dir = -1;
//      r.dir = -1;
//  }
//  return r;
// }


// signal conf_g(ohlc *candle, size_t i) {
//  signal r = {};
//  if () {
//      r.c1.nr = i;
//      r.c1.dir = 1;
//      r.c2.nr = i - 2;
// 2    r.c1.dir = 1;
//      r.dir = 1;
//  } else if () {
//      r.c1.nr = i;
//      r.c1.dir = -1;
//      r.c2.nr = i - 2;
// 2    r.c1.dir = -1;
//      r.dir = -1;
//  }
//  return r;
// }


signal conf_h1(ohlc *candle, size_t i, size_t contraction, size_t n) {
    signal r = {};
    size_t j, end_loop = fmin(i - 3, contraction + 4);
    if (wrb_hg(candle, i, n).dir == 1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, i).dir == 1 &&
                    broke_bars(candle, i, j) &&
                    contraction_share(candle, i, i - j) &&
                    contraction_body_size_break(candle, i, i - j) &&
                    volatility_expand(candle, i, 1, -1)) {
                r.c1.nr = i;
                r.c1.dir = 1;
                r.c1.open = candle[i].open;
                r.c1.close = candle[i].close;
                r.c2.nr = i - j;
                r.c2.dir = 1;
                r.c2.open = candle[i - j].open;
                r.c2.close = candle[i - j].close;
                r.dir = 1;
            }
        }
    } else if (wrb_hg(candle, i, n).dir == -1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, i).dir == -1 &&
                    broke_bars(candle, i, j) &&
                    contraction_share(candle, i, i - j) &&
                    contraction_body_size_break(candle, i, i - j) &&
                    volatility_expand(candle, i, -1, -1)) {
                r.c1.nr = i;
                r.c1.dir = -1;
                r.c1.open = candle[i].open;
                r.c1.close = candle[i].close;
                r.c2.nr = i - j;
                r.c2.dir = -1;
                r.c2.open = candle[i - j].open;
                r.c2.close = candle[i - j].close;
                r.dir = -1;
            }
        }
    }
    return r;
}


signal conf_h2(ohlc *candle, size_t i, size_t contraction, size_t n) {
    signal r = {};
    size_t j, end_loop = fmin(i - 3, contraction + 4);
    if (wrb_hg(candle, i, n).dir == 1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, i).dir == -1 &&
                    broke_bars(candle, i, j) &&
                    contraction_share(candle, i, i - j) &&
                    contraction_body_size_break(candle, i, i - j) &&
                    volatility_expand(candle, i, 1, -1)) {
                r.c1.nr = i;
                r.c1.dir = 1;
                r.c1.open = candle[i].open;
                r.c1.close = candle[i].close;
                r.c2.nr = i - j;
                r.c2.dir = -1;
                r.c2.open = candle[i - j].open;
                r.c2.close = candle[i - j].close;
                r.dir = 1;
            }
        }
    } else if (wrb_hg(candle, i, n).dir == -1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, i).dir == 1 &&
                    broke_bars(candle, i, j) &&
                    contraction_share(candle, i, i - j) &&
                    contraction_body_size_break(candle, i, i - j) &&
                    volatility_expand(candle, i, -1, -1)) {
                r.c1.nr = i;
                r.c1.dir = -1;
                r.c1.open = candle[i].open;
                r.c1.close = candle[i].close;
                r.c2.nr = i - j;
                r.c2.dir = 1;
                r.c2.open = candle[i - j].open;
                r.c2.close = candle[i - j].close;
                r.dir = -1;
            }
        }
    }
    return r;
}


signal conf_h3(ohlc *candle, size_t i, size_t contraction, size_t n) {
    signal r = {};
    size_t j, end_loop = fmin(i - 3, contraction + 4);
    if (wrb_hg(candle, i, n).dir == 1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, i).dir == 1 &&
                    contraction_share(candle, i, i - j) &&
                    contraction_body_size_break(candle, i, i - j) &&
                    volatility_expand(candle, i, 1, -1)) {
                r.c1.nr = i;
                r.c1.dir = 1;
                r.c1.open = candle[i].open;
                r.c1.close = candle[i].close;
                r.c2.nr = i - j;
                r.c2.dir = 1;
                r.c2.open = candle[i - j].open;
                r.c2.close = candle[i - j].close;
                r.dir = 1;
            }
        }
    } else if (wrb_hg(candle, i, n).dir == -1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, i).dir == -1 &&
                    contraction_share(candle, i, i - j) &&
                    contraction_body_size_break(candle, i, i - j) &&
                    volatility_expand(candle, i, -1, -1)) {
                r.c1.nr = i;
                r.c1.dir = -1;
                r.c1.open = candle[i].open;
                r.c1.close = candle[i].close;
                r.c2.nr = i - j;
                r.c2.dir = -1;
                r.c2.open = candle[i - j].open;
                r.c2.close = candle[i - j].close;
                r.dir = -1;
            }
        }
    }
    return r;
}


signal conf_h4(ohlc *candle, size_t i, size_t contraction, size_t n) {
    signal r = {};
    size_t j, end_loop = fmin(i - 3, contraction + 4);
    if (wrb_hg(candle, i, n).dir == 1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, i).dir == -1 &&
                    contraction_share(candle, i, i - j) &&
                    contraction_body_size_break(candle, i, i - j) &&
                    volatility_expand(candle, i, 1, -1)) {
                r.c1.nr = i;
                r.c1.dir = 1;
                r.c1.open = candle[i].open;
                r.c1.close = candle[i].close;
                r.c2.nr = i - j;
                r.c2.dir = -1;
                r.c2.open = candle[i - j].open;
                r.c2.close = candle[i - j].close;
                r.dir = 1;
            }
        }
    } else if (wrb_hg(candle, i, n).dir == -1) {
        for (j = 4; j < end_loop; j++) {
            if (wrb(candle, i - j, i).dir == 1 &&
                    broke_bars(candle, i, j) &&
                    contraction_share(candle, i, i - j) &&
                    contraction_body_size_break(candle, i, i - j) &&
                    volatility_expand(candle, i, -1, -1)) {
                r.c1.nr = i;
                r.c1.dir = -1;
                r.c1.open = candle[i].open;
                r.c1.close = candle[i].close;
                r.c2.nr = i - j;
                r.c2.dir = 1;
                r.c2.open = candle[i - j].open;
                r.c2.close = candle[i - j].close;
                r.dir = -1;
            }
        }
    }
    return r;
}


signal conf_h(ohlc *candle, size_t i, size_t contraction, size_t n) {
    signal r = {};
    r = conf_h1(candle, i, contraction, n);
    if (r.dir != 0) {
        return r;
    }
    r = conf_h2(candle, i, contraction, n);
    if (r.dir != 0) {
        return r;
    }
    r = conf_h3(candle, i, contraction, n);
    if (r.dir != 0) {
        return r;
    }
    r = conf_h4(candle, i, contraction, n);
    if (r.dir != 0) {
        return r;
    }
    return r;
}
