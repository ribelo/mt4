#pragma once

#include "wrb_struct.h"
#include "candle.h"


double support(ohlc *candle, size_t i, int hg_only, int use_fractal,
               size_t l, int n);


double resistance(ohlc *candle, size_t i, int hg_only, int use_fractal,
                  size_t l, int n);
