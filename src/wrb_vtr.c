
#include "wrb_vtr.h"
#include "gsl/gsl_math.h"
#include "wrb_struct.h"
#include "candle.h"
#include "wrb_toolbox.h"
#include "wrb_zone.h"


signal vtr(ohlc *main, ohlc *sister, size_t i,
           int invert, size_t look_back, size_t n) {
    signal r = {};
    size_t j, end_loop = fmin(i, look_back);
    body main_z, sister_z;
    if (!invert) {
        if ((dir(main, i) == 1 && dir(sister, i) == 1 &&
                dir(main, i - 1) == -1 &&
                gsl_fcmp(main[i].close,
                         body_mid_point(main, i - 1), FLT_EPSILON) > 0) ||
                (dir(sister, i) == 1 && dir(main, i) == 1 &&
                 dir(sister, i - 1) == -1 &&
                 gsl_fcmp(sister[i].close,
                          body_mid_point(sister, i - 1), FLT_EPSILON) > 0)) {
            // Look for zone
            for (j = 3; j < end_loop; j++) {
                main_z = wrb_zone(main, i - j, 64, n).v1;
                sister_z = wrb_zone(sister, i - j, 64, n).v1;
                if ((main_z.dir == 1 &&
                        wrb_hg(sister, i - j, n).dir == 1 &&
                        unfilled(main, i - j, j, n)) ||
                        (sister_z.dir == -1 &&
                         wrb_hg(main, i - j, n).dir == -1 &&
                         unfilled(sister, i - j, j, n))) {
                    if ((gsl_fcmp(lowest_close(main, i - 3, i),
                                  main[i - j].close, FLT_EPSILON) > 0 ||
                            gsl_fcmp(lowest_close(sister, i - 3, i),
                                     sister_z.close, FLT_EPSILON) > 0) &&
                            ((gsl_fcmp(main[i - 1].close,
                                       main[i - j].close, FLT_EPSILON) <= 0 &&
                              gsl_fcmp(main[i - 1].close,
                                       main[i - j].open, FLT_EPSILON) > 0 &&
                              gsl_fcmp(main[i].close,
                                       main[i - j].close, FLT_EPSILON) > 0 &&
                              ((gsl_fcmp(sister[i - 1].close,
                                         sister_z.open, FLT_EPSILON) < 0 &&
                                gsl_fcmp(sister[i].close,
                                         sister_z.open, FLT_EPSILON) >= 0) ||
                               (gsl_fcmp(sister[i - 1].close,
                                         sister_z.close, FLT_EPSILON) > 0))) ||
                             (gsl_fcmp(sister[i - 1].close,
                                       sister_z.close, FLT_EPSILON) <= 0 &&
                              gsl_fcmp(sister[i - 1].close,
                                       sister_z.open, FLT_EPSILON) > 0 &&
                              gsl_fcmp(sister[i].close,
                                       sister_z.close, FLT_EPSILON) > 0 &&
                              ((gsl_fcmp(main[i - 1].close,
                                         main[i - j].open, FLT_EPSILON) < 0 &&
                                gsl_fcmp(main[i].close,
                                         main[i - j].open, FLT_EPSILON) >= 0) ||
                               (gsl_fcmp(main[i - 1].close,
                                         main[i - j].close,
                                         FLT_EPSILON) > 0))))) {
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
                main_z = wrb_zone(main, i - j, 64, n).v1;
                sister_z = wrb_zone(sister, i - j, 64, n).v1;
                if ((main_z.dir == -1 &&
                        wrb_hg(sister, i - j, n).dir == -1 &&
                        unfilled(main, i - j, j, n)) ||
                        (sister_z.dir == -1 &&
                         wrb_hg(main, i - j, n).dir == -1 &&
                         unfilled(sister, i - j, j, n))) {
                    if ((gsl_fcmp(highest_close(main, i - 3, i),
                                  main[i - j].close, FLT_EPSILON) < 0 ||
                            gsl_fcmp(highest_close(sister, i - 3, i),
                                     sister_z.close, FLT_EPSILON) < 0) &&
                            ((gsl_fcmp(main[i - 1].close,
                                       main[i - j].close, FLT_EPSILON) >= 0 &&
                              gsl_fcmp(main[i - 1].close,
                                       main[i - j].open, FLT_EPSILON) < 0 &&
                              gsl_fcmp(main[i].close,
                                       main[i - j].close, FLT_EPSILON) < 0 &&
                              ((gsl_fcmp(sister[i - 1].close,
                                         sister_z.open, FLT_EPSILON) > 0 &&
                                gsl_fcmp(sister[i].close,
                                         sister_z.open, FLT_EPSILON) <= 0) ||
                               (gsl_fcmp(sister[i - 1].close,
                                         sister_z.close, FLT_EPSILON) < 0))) ||
                             (gsl_fcmp(sister[i - 1].close,
                                       sister_z.close, FLT_EPSILON) >= 0 &&
                              gsl_fcmp(sister[i - 1].close,
                                       sister_z.open, FLT_EPSILON) < 0 &&
                              gsl_fcmp(sister[i].close,
                                       sister_z.close, FLT_EPSILON) < 0 &&
                              ((gsl_fcmp(main[i - 1].close,
                                         main[i - j].open, FLT_EPSILON) > 0 &&
                                gsl_fcmp(main[i].close,
                                         main[i - j].open, FLT_EPSILON) <= 0) ||
                               (gsl_fcmp(main[i - 1].close,
                                         main[i - j].close,
                                         FLT_EPSILON) < 0))))) {
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
                (dir(sister, i) == -1 && dir(main, i) == -1 &&
                 dir(sister, i - 1) == 1 &&
                 gsl_fcmp(sister[i].close,
                          body_mid_point(sister, i - 1), FLT_EPSILON) < 0)) {
            // Look for zone
            for (j = 3; j < end_loop; j++) {
                main_z = wrb_zone(main, i - j, 64, n).v1;
                sister_z = wrb_zone(sister, i - j, 64, n).v1;
                if ((main_z.dir == 1 &&
                        wrb_hg(sister, i - j, n).dir == -1 &&
                        unfilled(main, i - j, j, n)) ||
                        (sister_z.dir == -1 &&
                         wrb_hg(main, i - j, n).dir == 1 &&
                         unfilled(sister, i - j, j, n))) {
                    if ((gsl_fcmp(lowest_close(main, i - 3, i),
                                  main[i - j].close, FLT_EPSILON) > 0 ||
                            gsl_fcmp(highest_close(sister, i - 3, i),
                                     sister_z.close, FLT_EPSILON) < 0) &&
                            ((gsl_fcmp(main[i - 1].close,
                                       main[i - j].close, FLT_EPSILON) <= 0 &&
                              gsl_fcmp(main[i - 1].close,
                                       main[i - j].open, FLT_EPSILON) > 0 &&
                              gsl_fcmp(main[i].close,
                                       main[i - j].close, FLT_EPSILON) > 0 &&
                              ((gsl_fcmp(sister[i - 1].close,
                                         sister_z.open, FLT_EPSILON) > 0 &&
                                gsl_fcmp(sister[i].close,
                                         sister_z.open, FLT_EPSILON) <= 0) ||
                               (gsl_fcmp(sister[i - 1].close,
                                         sister_z.close, FLT_EPSILON) < 0))) ||
                             (gsl_fcmp(sister[i - 1].close,
                                       sister_z.close, FLT_EPSILON) >= 0 &&
                              gsl_fcmp(sister[i - 1].close,
                                       sister_z.open, FLT_EPSILON) < 0 &&
                              gsl_fcmp(sister[i].close,
                                       sister_z.close, FLT_EPSILON) < 0 &&
                              ((gsl_fcmp(main[i - 1].close,
                                         main[i - j].open, FLT_EPSILON) < 0 &&
                                gsl_fcmp(main[i].close,
                                         main[i - j].open, FLT_EPSILON) >= 0) ||
                               (gsl_fcmp(main[i - 1].close,
                                         main[i - j].close,
                                         FLT_EPSILON) > 0))))) {
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
                (dir(sister, i) == 1 && dir(main, i) == 1 &&
                 dir(sister, i - 1) == -1 &&
                 gsl_fcmp(sister[i].close,
                          body_mid_point(sister, i - 1), FLT_EPSILON) > 0)) {
            // Look for zone
            for (j = 3; j < end_loop; j++) {
                main_z = wrb_zone(main, i - j, 64, n).v1;
                sister_z = wrb_zone(sister, i - j, 64, n).v1;
                if ((main_z.dir == -1 &&
                        wrb_hg(sister, i - j, n).dir == 1 &&
                        unfilled(main, i - j, j, n)) ||
                        (sister_z.dir == 1 &&
                         wrb_hg(main, i - j, n).dir == -1 &&
                         unfilled(sister, i - j, j, n))) {
                    if ((gsl_fcmp(highest_close(main, i - 3, i),
                                  main[i - j].close, FLT_EPSILON) < 0 ||
                            gsl_fcmp(lowest_close(sister, i - 3, i),
                                     sister_z.close, FLT_EPSILON) > 0) &&
                            ((gsl_fcmp(main[i - 1].close,
                                       main[i - j].close, FLT_EPSILON) >= 0 &&
                              gsl_fcmp(main[i - 1].close,
                                       main[i - j].open, FLT_EPSILON) < 0 &&
                              gsl_fcmp(main[i].close,
                                       main[i - j].close, FLT_EPSILON) < 0 &&
                              ((gsl_fcmp(sister[i - 1].close,
                                         sister_z.open, FLT_EPSILON) < 0 &&
                                gsl_fcmp(sister[i].close,
                                         sister_z.open, FLT_EPSILON) >= 0) ||
                               (gsl_fcmp(sister[i - 1].close,
                                         sister_z.close, FLT_EPSILON) > 0))) ||
                             (gsl_fcmp(sister[i - 1].close,
                                       sister_z.close, FLT_EPSILON) <= 0 &&
                              gsl_fcmp(sister[i - 1].close,
                                       sister_z.open, FLT_EPSILON) > 0 &&
                              gsl_fcmp(sister[i].close,
                                       sister_z.close, FLT_EPSILON) > 0 &&
                              ((gsl_fcmp(main[i - 1].close,
                                         main[i - j].open, FLT_EPSILON) > 0 &&
                                gsl_fcmp(main[i].close,
                                         main[i - j].open, FLT_EPSILON) <= 0) ||
                               (gsl_fcmp(main[i - 1].close,
                                         main[i - j].close,
                                         FLT_EPSILON) < 0))))) {
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
