
#include "wrb_fvb.h"
#include "gsl/gsl_math.h"
#include "wrb_struct.h"
#include "candle.h"
#include "wrb_toolbox.h"
#include "wrb_zone.h"


signal fvb(ohlc *candle, size_t i, size_t look_back, size_t n) {
    signal r = {};
    size_t j, end_loop = fmin(i, look_back);
    zone z;
    if (dir(candle, i) == 1 && wrb(candle, i - 1, i).dir == -1 &&
            gsl_fcmp(candle[i].close,
                     body_mid_point(candle, i - 1),
                     FLT_EPSILON) > 0) {
        for (j = 3; j < end_loop; j++) {
            z = wrb_zone(candle, i - j, 64, i);
            if (z.v1.dir == 1 &&
                    zone_size(&z.v1) > body_size(candle, i - 1) &&
                    unfilled(candle, i - j, j) &&
                    zone_bounce(candle, i, &z) == 1) {
                r.c1.nr = i;
                r.c2.nr = i - 1;
                r.zone.v1.nr = i - j;
                r.dir = 1;
                break;
            }
        }
    } else if (dir(candle, i) == -1 && wrb(candle, i - 1, i).dir == 1 &&
               gsl_fcmp(candle[i].close,
                        body_mid_point(candle, i - 1),
                        FLT_EPSILON) < 0) {
        for (j = 3; j < end_loop; j++) {
            z = wrb_zone(candle, i - j, 64, i);
            if (z.v1.dir < 0 &&
                    zone_size(&z.v1) > body_size(candle, i - 1) &&
                    unfilled(candle, i - j, j) &&
                    zone_bounce(candle, i, &z) == -1) {
                r.c1.nr = i;
                r.c2.nr = i - 1;
                r.zone.v1.nr = i - j;
                r.dir = -1;
                break;
            }
        }
    }
    return r;
}
