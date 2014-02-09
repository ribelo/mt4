#pragma once

#include "candle.h"

signal vtr(ohlc *main, ohlc *sister, size_t i,
           int invert, size_t look_back, size_t n);
