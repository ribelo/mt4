
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
    int main_z, sister_z;
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
                main_z = wrb_zone(main, i - j, 64, i).v1.dir;
                sister_z = wrb_zone(sister, i - j, 64, i).v1.dir;
                if ((main_z == 1 &&
                        wrb_hg(sister, i - j, i).dir == 1 &&
                        unfilled(main, i - j, j)) ||
                        (sister_z == -1 &&
                         wrb_hg(main, i - j, i).dir == -1 &&
                         unfilled(sister, i - j, j))) {
                    if ((gsl_fcmp(lowest_close(main, i - 3, i - 1),
                                  main[i - j].close, FLT_EPSILON) > 0 ||
                            gsl_fcmp(lowest_close(sister, i - 3, i - 1),
                                     sister[i - j].close, FLT_EPSILON) > 0) &&
                            ((gsl_fcmp(main[i - 1].close,
                                       main[i - j].close, FLT_EPSILON) <= 0 &&
                              gsl_fcmp(main[i - 1].close,
                                       main[i - j].open, FLT_EPSILON) > 0 &&
                              gsl_fcmp(main[i].close,
                                       main[i - j].close, FLT_EPSILON) > 0 &&
                              ((gsl_fcmp(sister[i - 1].close,
                                         sister[i - j].open, FLT_EPSILON) < 0 &&
                                gsl_fcmp(sister[i].close,
                                         sister[i - j].open, FLT_EPSILON) >= 0) ||
                               (gsl_fcmp(sister[i - 1].close,
                                         sister[i - j].close, FLT_EPSILON) > 0))) ||
                             (gsl_fcmp(sister[i - 1].close,
                                       sister[i - j].close, FLT_EPSILON) <= 0 &&
                              gsl_fcmp(sister[i - 1].close,
                                       sister[i - j].open, FLT_EPSILON) > 0 &&
                              gsl_fcmp(sister[i].close,
                                       sister[i - j].close, FLT_EPSILON) > 0 &&
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
                main_z = wrb_zone(main, i - j, 64, i).v1.dir;
                sister_z = wrb_zone(sister, i - j, 64, i).v1.dir;
                if ((main_z == -1 &&
                        wrb_hg(sister, i - j, i).dir == -1 &&
                        unfilled(main, i - j, j)) ||
                        (sister_z == -1 &&
                         wrb_hg(main, i - j, i).dir == -1 &&
                         unfilled(sister, i - j, j))) {
                    if ((gsl_fcmp(highest_close(main, i - 3, i - 1),
                                  main[i - j].close, FLT_EPSILON) < 0 ||
                            gsl_fcmp(highest_close(sister, i - 3, i - 1),
                                     sister[i - j].close, FLT_EPSILON) < 0) &&
                            ((gsl_fcmp(main[i - 1].close,
                                       main[i - j].close, FLT_EPSILON) >= 0 &&
                              gsl_fcmp(main[i - 1].close,
                                       main[i - j].open, FLT_EPSILON) < 0 &&
                              gsl_fcmp(main[i].close,
                                       main[i - j].close, FLT_EPSILON) < 0 &&
                              ((gsl_fcmp(sister[i - 1].close,
                                         sister[i - j].open, FLT_EPSILON) > 0 &&
                                gsl_fcmp(sister[i].close,
                                         sister[i - j].open, FLT_EPSILON) <= 0) ||
                               (gsl_fcmp(sister[i - 1].close,
                                         sister[i - j].close, FLT_EPSILON) < 0))) ||
                             (gsl_fcmp(sister[i - 1].close,
                                       sister[i - j].close, FLT_EPSILON) >= 0 &&
                              gsl_fcmp(sister[i - 1].close,
                                       sister[i - j].open, FLT_EPSILON) < 0 &&
                              gsl_fcmp(sister[i].close,
                                       sister[i - j].close, FLT_EPSILON) < 0 &&
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
                (dir(sister, i) == -1 && dir(main, i) == 1 &&
                 dir(sister, i - 1) == -1 &&
                 gsl_fcmp(sister[i].close,
                          body_mid_point(sister, i - 1), FLT_EPSILON) < 0)) {
            // Look for zone
            for (j = 3; j < end_loop; j++) {
                main_z = wrb_zone(main, i - j, 64, i).v1.dir;
                sister_z = wrb_zone(sister, i - j, 64, i).v1.dir;
                if ((main_z == 1 &&
                        wrb_hg(sister, i - j, i).dir == -1 &&
                        unfilled(main, i - j, j)) ||
                        (sister_z == -1 &&
                         wrb_hg(main, i - j, i).dir == 1 &&
                         unfilled(sister, i - j, j))) {
                    if ((gsl_fcmp(lowest_close(main, i - 3, i - 1),
                                  main[i - j].close, FLT_EPSILON) > 0 ||
                            gsl_fcmp(highest_close(sister, i - 3, i - 1),
                                     sister[i - j].close, FLT_EPSILON) < 0) &&
                            ((gsl_fcmp(main[i - 1].close,
                                       main[i - j].close, FLT_EPSILON) <= 0 &&
                              gsl_fcmp(main[i - 1].close,
                                       main[i - j].open, FLT_EPSILON) > 0 &&
                              gsl_fcmp(main[i].close,
                                       main[i - j].close, FLT_EPSILON) > 0 &&
                              ((gsl_fcmp(sister[i - 1].close,
                                         sister[i - j].open, FLT_EPSILON) > 0 &&
                                gsl_fcmp(sister[i].close,
                                         sister[i - j].open, FLT_EPSILON) <= 0) ||
                               (gsl_fcmp(sister[i - 1].close,
                                         sister[i - j].close, FLT_EPSILON) < 0))) ||
                             (gsl_fcmp(sister[i - 1].close,
                                       sister[i - j].close, FLT_EPSILON) >= 0 &&
                              gsl_fcmp(sister[i - 1].close,
                                       sister[i - j].open, FLT_EPSILON) < 0 &&
                              gsl_fcmp(sister[i].close,
                                       sister[i - j].close, FLT_EPSILON) < 0 &&
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
                (dir(sister, i) == 1 && dir(main, i) == -1 &&
                 dir(sister, i - 1) == 1 &&
                 gsl_fcmp(sister[i].close,
                          body_mid_point(sister, i - 1), FLT_EPSILON) > 0)) {
            // Look for zone
            for (j = 3; j < end_loop; j++) {
                main_z = wrb_zone(main, i - j, 64, i).v1.dir;
                sister_z = wrb_zone(sister, i - j, 64, i).v1.dir;
                if ((main_z == -1 &&
                        wrb_hg(sister, i - j, i).dir == 1 &&
                        unfilled(main, i - j, j)) ||
                        (sister_z == 1 &&
                         wrb_hg(main, i - j, i).dir == -1 &&
                         unfilled(sister, i - j, j))) {
                    if ((gsl_fcmp(highest_close(main, i - 3, i - 1),
                                  main[i - j].close, FLT_EPSILON) < 0 ||
                            gsl_fcmp(lowest_close(sister, i - 3, i - 1),
                                     sister[i - j].close, FLT_EPSILON) > 0) &&
                            ((gsl_fcmp(main[i - 1].close,
                                       main[i - j].close, FLT_EPSILON) >= 0 &&
                              gsl_fcmp(main[i - 1].close,
                                       main[i - j].open, FLT_EPSILON) < 0 &&
                              gsl_fcmp(main[i].close,
                                       main[i - j].close, FLT_EPSILON) < 0 &&
                              ((gsl_fcmp(sister[i - 1].close,
                                         sister[i - j].open, FLT_EPSILON) < 0 &&
                                gsl_fcmp(sister[i].close,
                                         sister[i - j].open, FLT_EPSILON) >= 0) ||
                               (gsl_fcmp(sister[i - 1].close,
                                         sister[i - j].close, FLT_EPSILON) > 0))) ||
                             (gsl_fcmp(sister[i - 1].close,
                                       sister[i - j].close, FLT_EPSILON) <= 0 &&
                              gsl_fcmp(sister[i - 1].close,
                                       sister[i - j].open, FLT_EPSILON) > 0 &&
                              gsl_fcmp(sister[i].close,
                                       sister[i - j].close, FLT_EPSILON) > 0 &&
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
