
#include "wrb_fvb.h"
#include "gsl/gsl_math.h"
#include "wrb_struct.h"
#include "candle.h"
#include "wrb_analysis.h"
#include "wrb_confirmation.h"
#include "wrb_toolbox.h"
#include "wrb_zone.h"


signal fvb(ohlc *candle, size_t i, size_t look_back, size_t n) {
    signal r = {};
    size_t j, end_loop = fmin(i, look_back);
    zone z;
    signal conf = fade_volatility(candle, i);
    if (!conf.dir) {
        conf = conf_h2(candle, i, 16, n);
    }
    if (conf.dir == 1) {
        for (j = 3; j < end_loop; j++) {
            z = wrb_zone(candle, i - j, 16, i);
            if (z.v1.dir == 1 &&
                    zone_size(&z.v1) > body_size(candle, conf.c2.nr) &&
                    zone_size(&z.v1) > body_size(candle, conf.c1.nr) &&
                    unfilled(candle, i - j, j, n) &&
                    zone_denial(candle, &conf, &z) == 1) {
                r.c1.nr = conf.c1.nr;
                r.c2.nr = conf.c2.nr;
                r.zone.v1.nr = i - j;
                r.dir = conf.dir;
                break;
            }
        }
    } else if (conf.dir == -1) {
        for (j = 3; j < end_loop; j++) {
            z = wrb_zone(candle, i - j, 16, i);
            if (z.v1.dir < 0 &&
                    zone_size(&z.v1) > body_size(candle, conf.c2.nr) &&
                    zone_size(&z.v1) > body_size(candle, conf.c1.nr) &&
                    unfilled(candle, i - j, j, n) &&
                    zone_denial(candle, &conf, &z) == -1) {
                r.c1.nr = conf.c1.nr;
                r.c2.nr = conf.c2.nr;
                r.zone.v1.nr = i - j;
                r.dir = conf.dir;
                break;
            }
        }
    }
    return r;
}
