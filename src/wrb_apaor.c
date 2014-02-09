
#include "wrb_apaor.h"
#include "math.h"
#include <gsl/gsl_math.h>
#include "wrb_struct.h"
#include "candle.h"
#include "wrb_analysis.h"
#include <stdio.h>


typedef struct {
    double a;
    double b;
    double c;
} line;

typedef struct {
    long int x;
    double y;
} point;


line get_line(point p1, point p2) {
   line l = {};
   if(p1.x == p2.x){
      l.a = 1;
      l.b = 0;
      l.c = -p1.x;
   } else {
      l.a = p2.y - p1.y ;
      l.b = p1.x - p2.x ;
      l.c = p1.y * p2.x - p2.y * p1.x;
   }
   return l;
}


static inline double point_side(line l, point p) {
    double a = l.a / -l.b;
    double b = l.c / -l.b;
    return p.y - (a * p.x + b);
}


// static inline double point_distance(line l, point p) {
//     return (l.a * p.x + l.b * p.y + l.c) / sqrt(gsl_pow_2(l.a) + gsl_pow_2(l.b));
// }


static inline int get_prior_low_fractal(ohlc *candle, size_t i, size_t l, size_t n) {
    for (size_t j = l; j < i; j++) {
        if (fractal_low(candle, i - j, l, n)) {
            return i - j;
        }
    }
    return -1;
}


static inline int get_prior_high_fractal(ohlc *candle, size_t i, size_t l, size_t n) {
    for (size_t j = l; j < i; j++) {
        if (fractal_high(candle, i - j, l, n)) {
            return i - j;
        }
    }
    return -1;
}


static inline int broke_line(ohlc *candle, line l, size_t start,
                             size_t stop, int dir) {
    point p;
    if (dir == 1) {
        for (int i = start; i < stop; i ++) {
            p.x = i;
            p.y = candle[i].low;
            if (gsl_fcmp(point_side(l, p), 0.0, FLT_EPSILON) < 0){
                return 1;
            }
        }
    } else if (dir == -1) {
        for (int i = start; i < stop; i ++) {
            p.x = i;
            p.y = candle[i].high;
            if (gsl_fcmp(point_side(l, p), 0.0, FLT_EPSILON) > 0){
                return 1;
            }
        }
    }
    return 0;
}


signal apaor(ohlc *main, ohlc *sister, size_t i, size_t pa_l,
                  size_t pb_l, int invert, size_t look_back, size_t n) {
    signal r = {};
    point m_pb, m_pa, s_pb, s_pa;
    line m_apaor_line, s_apaor_line;
    if (!invert) {
        if (fractal_low(main, i, pb_l, n)) {
            m_pb.x = i;
            m_pb.y = main[m_pb.x].low;
            m_pa.x = get_prior_low_fractal(main, m_pb.x, pa_l, n);
            m_pa.y = main[m_pa.x].low;
            if (fractal_low(sister, i - 1, pb_l, n)) {
                s_pb.x = i - 1;
                s_pb.y = sister[s_pb.x].low;
                s_pa.x = get_prior_low_fractal(sister, s_pb.x, pa_l, n);
                s_pa.y = sister[s_pa.x].low;
            } else if (fractal_low(sister, i, pb_l, n)) {
                s_pb.x = i;
                s_pb.y = sister[s_pb.x].low;
                s_pa.x = get_prior_low_fractal(sister, s_pb.x, pa_l, n);
                s_pa.y = sister[s_pa.x].low;
            } else if (fractal_low(sister, i + 1, pb_l, n)) {
                s_pb.x = i + 1;
                s_pb.y = sister[s_pb.x].low;
                s_pa.x = get_prior_low_fractal(sister, s_pb.x, pa_l, n);
                s_pa.y = sister[s_pa.x].low;
            } else {
                return r;
            }
            m_apaor_line = get_line(m_pb, m_pa);
            s_apaor_line = get_line(s_pb, s_pa);
            if (!broke_line(main, m_apaor_line, m_pa.x + 1, m_pb.x, 1) &&
                !broke_line(sister, s_apaor_line, s_pa.x + 1, s_pb.x, 1) &&
                ((gsl_fcmp(m_pa.y, m_pb.y, FLT_EPSILON) > 0 &&
                  gsl_fcmp(s_pa.y, s_pb.y, FLT_EPSILON) < 0) ||
                 (gsl_fcmp(m_pa.y, m_pb.y, FLT_EPSILON) < 0 &&
                  gsl_fcmp(s_pa.y, s_pb.y, FLT_EPSILON) > 0))) {
                r.c1.nr = m_pb.x;
                r.c2.nr = m_pa.x;
                r.dir = 1;
            }
        } else if (fractal_high(main, i, pb_l, n)) {
            m_pb.x = i;
            m_pb.y = main[m_pb.x].high;
            m_pa.x = get_prior_high_fractal(main, i, pa_l, n);
            m_pa.y = main[m_pa.x].high;
            if (fractal_high(sister, i - 1, pb_l, n)) {
                s_pb.x = i - 1;
                s_pb.y = sister[s_pb.x].high;
                s_pa.x = get_prior_high_fractal(sister, s_pb.x, pa_l, n);
                s_pa.y = sister[s_pa.x].high;
            } else if (fractal_high(sister, i, pb_l, n)) {
                s_pb.x = i;
                s_pb.y = sister[s_pb.x].high;
                s_pa.x = get_prior_high_fractal(sister, s_pb.x, pa_l, n);
                s_pa.y = sister[s_pa.x].high;
            } else if (fractal_high(sister, i + 1, pb_l, n)) {
                s_pb.x = i + 1;
                s_pb.y = sister[s_pb.x].high;
                s_pa.x = get_prior_high_fractal(sister, s_pb.x, pa_l, n);
                s_pa.y = sister[s_pa.x].high;
            } else {
                return r;
            }
            m_apaor_line = get_line(m_pb, m_pa);
            s_apaor_line = get_line(s_pb, s_pa);
            if (!broke_line(main, m_apaor_line, m_pa.x + 1, m_pb.x, -1) &&
                !broke_line(sister, s_apaor_line, s_pa.x + 1, s_pb.x, -1) &&
                ((gsl_fcmp(m_pa.y, m_pb.y, FLT_EPSILON) > 0 &&
                  gsl_fcmp(s_pa.y, s_pb.y, FLT_EPSILON) < 0) ||
                 (gsl_fcmp(m_pa.y, m_pb.y, FLT_EPSILON) < 0 &&
                  gsl_fcmp(s_pa.y, s_pb.y, FLT_EPSILON) > 0))) {
                r.c1.nr = m_pb.x;
                r.c2.nr = m_pa.x;
                r.dir = -1;
            }
        }
    } else {
        if (fractal_low(main, i, pb_l, n)) {
            m_pb.x = i;
            m_pb.y = main[m_pb.x].low;
            m_pa.x = get_prior_low_fractal(main, i, pa_l, n);
            m_pa.y = main[m_pa.x].low;
            if (fractal_high(sister, i - 1, pb_l, n)) {
                s_pb.x = i - 1;
                s_pb.y = sister[s_pb.x].high;
                s_pa.x = get_prior_high_fractal(sister, s_pb.x, pa_l, n);
                s_pa.y = sister[s_pa.x].high;
            } else if (fractal_high(sister, i, pb_l, n)) {
                s_pb.x = i;
                s_pb.y = sister[s_pb.x].high;
                s_pa.x = get_prior_high_fractal(sister, s_pb.x, pa_l, n);
                s_pa.y = sister[s_pa.x].high;
            } else if (fractal_high(sister, i + 1, pb_l, n)) {
                s_pb.x = i + 1;
                s_pb.y = sister[s_pb.x].high;
                s_pa.x = get_prior_high_fractal(sister, s_pb.x, pa_l, n);
                s_pa.y = sister[s_pa.x].high;
            } else {
                return r;
            }
            m_apaor_line = get_line(m_pb, m_pa);
            s_apaor_line = get_line(s_pb, s_pa);
            if (!broke_line(main, m_apaor_line, m_pa.x + 1, m_pb.x, 1) &&
                !broke_line(sister, s_apaor_line, s_pa.x + 1, s_pb.x, -1) &&
                ((gsl_fcmp(m_pa.y, m_pb.y, FLT_EPSILON) > 0 &&
                  gsl_fcmp(s_pa.y, s_pb.y, FLT_EPSILON) > 0) ||
                 (gsl_fcmp(m_pa.y, m_pb.y, FLT_EPSILON) < 0 &&
                  gsl_fcmp(s_pa.y, s_pb.y, FLT_EPSILON) < 0))) {
                r.c1.nr = m_pb.x;
                r.c2.nr = m_pa.x;
                r.dir = 1;
            }
        } else if (fractal_high(main, i, pb_l, n)) {
            m_pb.x = i;
            m_pb.y = main[m_pb.x].high;
            m_pa.x = get_prior_high_fractal(main, i, pa_l, n);
            m_pa.y = main[m_pa.x].high;
            if (fractal_low(sister, i - 1, pb_l, n)) {
                s_pb.x = i - 1;
                s_pb.y = sister[s_pb.x].low;
                s_pa.x = get_prior_low_fractal(sister, s_pb.x, pa_l, n);
                s_pa.y = sister[s_pa.x].low;
            } else if (fractal_low(sister, i, pb_l, n)) {
                s_pb.x = i;
                s_pb.y = sister[s_pb.x].low;
                s_pa.x = get_prior_low_fractal(sister, s_pb.x, pa_l, n);
                s_pa.y = sister[s_pa.x].low;
            } else if (fractal_low(sister, i + 1, pb_l, n)) {
                s_pb.x = i + 1;
                s_pb.y = sister[s_pb.x].low;
                s_pa.x = get_prior_low_fractal(sister, s_pb.x, pa_l, n);
                s_pa.y = sister[s_pa.x].low;
            } else {
                return r;
            }
            m_apaor_line = get_line(m_pb, m_pa);
            s_apaor_line = get_line(s_pb, s_pa);
            if (!broke_line(main, m_apaor_line, m_pa.x + 1, m_pb.x, -1) &&
                !broke_line(sister, s_apaor_line, s_pa.x + 1, s_pb.x, 1) &&
                ((gsl_fcmp(m_pa.y, m_pb.y, FLT_EPSILON) > 0 &&
                  gsl_fcmp(s_pa.y, s_pb.y, FLT_EPSILON) > 0) ||
                 (gsl_fcmp(m_pa.y, m_pb.y, FLT_EPSILON) < 0 &&
                  gsl_fcmp(s_pa.y, s_pb.y, FLT_EPSILON) < 0))) {
                r.c1.nr = m_pb.x;
                r.c2.nr = m_pa.x;
                r.dir = -1;
            }
        }
    }
    return r;
}
