#pragma once

#include "candle.h"


signal apaor(ohlc *main, ohlc *sister, size_t i, size_t pa_l,
                  size_t pb_l, int invert, size_t look_back, size_t n);

int div_bull(ohlc *main, ohlc *sister, size_t i, size_t pa_l,
             int invert, size_t look_back, size_t n);

int div_bear(ohlc *main, ohlc *sister, size_t i, size_t pa_l,
             int invert, size_t look_back, size_t n);
