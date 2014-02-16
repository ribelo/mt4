#pragma once

#include <gsl/gsl_math.h>
#include <float.h>
#include "deepthroat.h"
#include "wrb_struct.h"



static inline int dir(ohlc *candle, size_t i) {
	return gsl_fcmp(candle[i].close, candle[i].open, FLT_EPSILON);
}


static inline int consecutive_dir(ohlc *candle, size_t i) {
	int j, cc = 1;
	int candle_dir = dir(candle, i);
	for (j = 1; j < i; j++) {
		if (dir(candle, i - j) == candle_dir) {
			cc++;
		} else {
			break;
		}
	}
	return cc;
}


static inline int count_rising(ohlc *candle, size_t start, size_t stop) {
	int count = 0;
	for (size_t i = start; i < stop; i++) {
		if (dir(candle, i) == 1) {
			count++;
		}
	}
	return count;
}


static inline int count_falling(ohlc *candle, size_t start, size_t stop) {
	int count = 0;
	for (size_t i = start; i < stop; i++) {
		if (dir(candle, i) == -1) {
			count++;
		}
	}
	return count;
}


static inline double body_size(ohlc *candle, size_t i) {
	return fabs(roundp(candle[i].close - candle[i].open, 5));
}


static inline double body_mid_point(ohlc *candle, size_t i) {
	return roundp((candle[i].close + candle[i].open) * 0.5, 5);
}


static inline int broke_body_size(ohlc *candle, size_t i, size_t j) {
	int k;
	for (k = GSL_MIN_INT(i, j); k > 0; k--) {
		if (gsl_fcmp(body_size(candle, i - k), body_size(candle, i), FLT_EPSILON) > 0) {
			return 0;
		}
	}
	return 1;
}


static inline int body_size_break(ohlc *candle, size_t i) {
	int j, r = 0;
	for (j = 1; j < i; j++) {
		if (gsl_fcmp(body_size(candle, i - j), body_size(candle, i), FLT_EPSILON) > 0) {
			r++;
		} else {
			break;
		}
	}
	return r;
}


static inline double gap(ohlc *candle, size_t i) {
	double gap_val = 0.0;
	if (gsl_fcmp(candle[i + 1].low, candle[i - 1].high, FLT_EPSILON) > 0 ||
	    	gsl_fcmp(candle[i + 1].high, candle[i - 1].low, FLT_EPSILON) < 0) {
		gap_val =  GSL_MAX_DBL(candle[i + 1].low - candle[i - 1].high,
		                   candle[i - 1].low - candle[i + 1].high);
	}
	return gap_val;
}


static inline int broke_bars(ohlc *candle, size_t i, size_t j) {
	int k;
	int candle_dir = dir(candle, i);
	if (candle_dir == 1) {
		for (k = GSL_MIN_INT(i, j); k > 0; k--) {
			if (gsl_fcmp(candle[i - k].high, candle[i].close, FLT_EPSILON) > 0) {
				return 0;
			}
		}
	} else if (candle_dir == -1) {
		for (k = GSL_MIN_INT(i, j); k > 0; k--) {
			if (gsl_fcmp(candle[i - k].low, candle[i].close, FLT_EPSILON) < 0) {
				return 0;
			}
		}
	}
	return 1;
}


static inline int bars_broken_by_body(ohlc *candle, size_t i) {
	int j, r = 0;
	int candle_dir = dir(candle, i);
	if (candle_dir == 1) {
		for (j = 1; j < i; j++) {
			if (gsl_fcmp(candle[i - j].close, candle[i].high, FLT_EPSILON) > 0) {
				r++;
			} else {
				break;
			}
		}
	} else if (candle_dir == -1) {
		for (j = 1; j < i; j++) {
			if (gsl_fcmp(candle[i - j].close, candle[i].low, FLT_EPSILON) < 0) {
				r++;
			} else {
				break;
			}
		}
	}
	return r;
}


static inline double shadow_upper(ohlc *candle, size_t i) {
	return roundp(candle[i].high - GSL_MAX_DBL(candle[i].open, candle[i].close), 5);
}


static inline double shadow_bottom(ohlc *candle, size_t i) {
	return roundp(GSL_MIN_DBL(candle[i].open, candle[i].close) - candle[i].low, 5);
}


static inline int unfilled(ohlc *candle, size_t i, size_t j) {
	int k;
	int candle_dir = dir(candle, i);
	if (candle_dir == 1) {
		for (k = 1; k < j; k++) {
			if (gsl_fcmp(candle[i + k].low, candle[i].open, FLT_EPSILON) < 0) {
				return 0;
			}
		}
	} else if (candle_dir == -1) {
		for (k = 1; k < j; k++) {
			if (gsl_fcmp(candle[i + k].high, candle[i].open, FLT_EPSILON) > 0) {
				return 0;
			}
		}
	}
	return 1;
}


static inline int filled_by(ohlc *candle, size_t i, int n) {
	int j;
	int candle_dir = dir(candle, i);
	if (candle_dir == 1) {
		for (j = 1; j < n - i; j++) {
			if (gsl_fcmp(candle[i + j].low, candle[i].open, FLT_EPSILON) < 0) {
				return i + j;
			}
		}
	} else if (candle_dir == -1) {
		for (j = 1; j < n - i; j++) {
			if (gsl_fcmp(candle[i + j].high, candle[i].open, FLT_EPSILON) > 0) {
				return i + j;

			}
		}
	}
	return -1;
}


static inline double highest_open(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_NEGINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MAX_DBL(candle[i].open, r);
	}
	return r;
}


static inline double highest_high(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_NEGINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MAX_DBL(candle[i].high, r);
	}
	return r;
}


static inline double highest_low(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_NEGINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MAX_DBL(candle[i].low, r);
	}
	return r;
}


static inline double highest_close(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_NEGINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MAX_DBL(candle[i].close, r);
	}
	return r;
}


static inline double highest_vol(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_NEGINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MAX_DBL(candle[i].volume, r);
	}
	return r;
}


static inline double highest_body(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_NEGINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MAX_DBL(GSL_MAX_DBL(candle[i].open, candle[i].close), r);
	}
	return r;
}


static inline double lowest_open(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_POSINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MIN_DBL(candle[i].open, r);
	}
	return r;
}


static inline double lowest_high(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_POSINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MIN_DBL(candle[i].high, r);
	}
	return r;
}


static inline double lowest_low(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_POSINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MIN_DBL(candle[i].low, r);
	}
	return r;
}


static inline double lowest_close(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_POSINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MIN_DBL(candle[i].close, r);
	}
	return r;
}


static inline double lowest_vol(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_POSINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MIN_DBL(candle[i].volume, r);
	}
	return r;
}


static inline double lowest_body(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_POSINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MIN_DBL(GSL_MIN_DBL(candle[i].open, candle[i].close), r);
	}
	return r;
}


static inline double biggest_body(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_NEGINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MAX_DBL(body_size(candle, i), r);
	}
	return r;
}


static inline double smalest_body(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_POSINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MIN_DBL(body_size(candle, i), r);
	}
	return r;
}


static inline double biggest_shadow_upper(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_NEGINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MAX_DBL(shadow_upper(candle, i), r);
	}
	return r;
}


static inline double smalest_shadow_upper(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_POSINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MIN_DBL(shadow_upper(candle, i), r);
	}
	return r;
}


static inline double biggest_shadow_bottom(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_NEGINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MAX_DBL(shadow_bottom(candle, i), r);
	}
	return r;
}


static inline double smalest_shadow_bottom(ohlc *candle, size_t start, size_t stop) {
	double r = GSL_POSINF;
	size_t i;

	for (i = start; i < stop; i ++) {
		r = GSL_MIN_DBL(shadow_bottom(candle, i), r);
	}
	return r;
}
