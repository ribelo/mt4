#pragma once

#include <stdlib.h>
#include <math.h>
#include <float.h>
#include <limits.h>
#include <gsl/gsl_math.h>


static inline double roundp(double x, int precise) {
	return floor(x * pow(10, precise) + 0.5) / pow(10, precise);
}


static inline int array_fany(double array[], size_t start, size_t stop) {
	int i;
	for (i = start; i < stop; i++) {
		if (array[i] != 0) {
			return 1;
		}
	}
	return 0;
}


static inline int array_fall(double array[], size_t start, size_t stop) {
	int i;
	for (i = start; i < stop; i++) {
		if (array[i] != 1) {
			return 0;
		}
	}
	return 1;
}


static inline int array_iany(int array[], size_t start, size_t stop) {
	int i;
	for (i = start; i < stop; i++) {
		if (array[i] != 0) {
			return 1;
		}
	}
	return 0;
}


static inline int array_iall(int array[], size_t start, size_t stop) {
	int i;
	for (i = start; i < stop; i++) {
		if (array[i] != 1) {
			return 0;
		}
	}
	return 1;
}
