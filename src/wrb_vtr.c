
#include "wrb_vtr.h"
#include "gsl/gsl_math.h"
#include "wrb_struct.h"
#include "candle.h"
#include "wrb_confirmation.h"
#include "wrb_toolbox.h"
#include "wrb_zone.h"


signal vtr(ohlc *main, ohlc *sister, size_t i,
           int invert, size_t look_back, size_t n) {
    signal r = {};
    size_t j, end_loop = fmin(i, look_back);
    zone main_z, sister_z;
    zone main_hg, sister_hg;
    signal main_conf = fade_volatility(main, i);
    signal sister_conf = fade_volatility(sister, i);
    if (!main_conf.dir) {
        main_conf = conf_h2(main, i, 16, n);
    }
    if (!sister_conf.dir) {
        sister_conf = conf_h2(sister, i, 16, n);
    }
    if (!invert) {
        if (dir(main, i) == 1 && dir(sister, i) == 1 &&
                (main_conf.dir == 1 || sister_conf.dir == 1)) {
            // Look for zone
            for (j = 3; j < end_loop; j++) {
                main_z = wrb_zone(main, i - j, 64, i);
                main_hg.v1 = wrb_hg(main, i - j, i);
                sister_z = wrb_zone(sister, i - j, 64, i);
                sister_hg.v1 = wrb_hg(sister, i - j, i);
                if ((main_z.v1.dir == 1 &&
                        sister_hg.v1.dir == 1 &&
                        unfilled(main, i - j, j)) ||
                        (sister_z.v1.dir == -1 &&
                         main_hg.v1.dir == -1 &&
                         unfilled(sister, i - j, j))) {
                    if (zone_divergence(main, sister, &main_conf, &sister_conf,
                                        &main_z, &sister_z, &invert)) {
                        r.c1.nr = i;
                        r.c2.nr = i - 1;
                        r.zone.v1.nr = i - j;
                        r.dir = 1;
                        break;
                    }
                }
            }
        }
        if ((dir(main, i) == -1 && dir(sister, i) == -1 &&
                dir(main, i - 1) == 1 &&
                gsl_fcmp(main[i].close,
                         body_mid_point(main, i - 1), FLT_EPSILON) < 0) ||
                (dir(sister, i) == -1 && dir(main, i) == -1 &&
                 dir(sister, i - 1) == 1 &&
                 gsl_fcmp(sister[i].close,
                          body_mid_point(sister, i - 1), FLT_EPSILON) < 0)) {
            // Look for zone
            for (j = 3; j < end_loop; j++) {
                main_z = wrb_zone(main, i - j, 64, i);
                sister_z = wrb_zone(sister, i - j, 64, i);
                if ((main_z.v1.dir == -1 &&
                        wrb_hg(sister, i - j, i).dir == -1 &&
                        unfilled(main, i - j, j)) ||
                        (sister_z.v1.dir == -1 &&
                         wrb_hg(main, i - j, i).dir == -1 &&
                         unfilled(sister, i - j, j))) {
                    if (zone_divergence(main, sister, &main_conf, &sister_conf,
                                        &main_z, &sister_z, &invert)) {
                        r.c1.nr = i;
                        r.c2.nr = i - 1;
                        r.zone.v1.nr = i - j;
                        r.dir = -1;
                        break;
                    }
                }
            }
        }
    } else {
        if ((dir(main, i) == 1 && dir(sister, i) == -1 &&
                dir(main, i - 1) == -1 &&
                gsl_fcmp(main[i].close,
                         body_mid_point(main, i - 1), FLT_EPSILON) > 0) ||
                (dir(sister, i) == -1 && dir(main, i) == 1 &&
                 dir(sister, i - 1) == 1 &&
                 gsl_fcmp(sister[i].close,
                          body_mid_point(sister, i - 1), FLT_EPSILON) < 0)) {
            // Look for zone
            for (j = 3; j < end_loop; j++) {
                main_z = wrb_zone(main, i - j, 64, i);
                sister_z = wrb_zone(sister, i - j, 64, i);
                if ((main_z.v1.dir == 1 &&
                        wrb_hg(sister, i - j, i).dir == -1 &&
                        unfilled(main, i - j, j)) ||
                        (sister_z.v1.dir == -1 &&
                         wrb_hg(main, i - j, i).dir == 1 &&
                         unfilled(sister, i - j, j))) {
                    if (zone_divergence(main, sister, &main_conf, &sister_conf,
                                        &main_z, &sister_z, &invert)) {
                        r.c1.nr = i;
                        r.c2.nr = i - 1;
                        r.zone.v1.nr = i - j;
                        r.dir = 1;
                        break;
                    }
                }
            }
        }
        if ((dir(main, i) == -1 && dir(sister, i) == 1 &&
                dir(main, i - 1) == 1 &&
                gsl_fcmp(main[i].close,
                         body_mid_point(main, i - 1), FLT_EPSILON) < 0) ||
                (dir(sister, i) == 1 && dir(main, i) == -1 &&
                 dir(sister, i - 1) == -1 &&
                 gsl_fcmp(sister[i].close,
                          body_mid_point(sister, i - 1), FLT_EPSILON) > 0)) {
            // Look for zone
            for (j = 3; j < end_loop; j++) {
                main_z = wrb_zone(main, i - j, 64, i);
                sister_z = wrb_zone(sister, i - j, 64, i);
                if ((main_z.v1.dir == -1 &&
                        wrb_hg(sister, i - j, i).dir == 1 &&
                        unfilled(main, i - j, j)) ||
                        (sister_z.v1.dir == 1 &&
                         wrb_hg(main, i - j, i).dir == -1 &&
                         unfilled(sister, i - j, j))) {
                    if (zone_divergence(main, sister, &main_conf, &sister_conf,
                                        &main_z, &sister_z, &invert)) {
                        r.c1.nr = i;
                        r.c2.nr = i - 1;
                        r.zone.v1.nr = i - j;
                        r.dir = -1;
                        break;
                    }
                }
            }
        }
    }
    return r;
}
