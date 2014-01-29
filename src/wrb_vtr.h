#pragma once

#include "candle.h"

signal vtr(ohlc *main, ohlc *sister, size_t i, size_t n,
           int invert, size_t look_back, int h_zone);
