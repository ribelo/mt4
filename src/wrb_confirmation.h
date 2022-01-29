#pragma once

#include "candle.h"

signal conf_fade(ohlc *candle, size_t i);
signal conf_a(ohlc *candle, size_t i);
signal conf_b(ohlc *candle, size_t i);
signal conf_c(ohlc *candle, size_t i);
signal conf_d(ohlc *candle, size_t i);
signal conf_e(ohlc *candle, size_t i);
signal conf_h1(ohlc *candle, size_t i, size_t contraction, size_t n);
signal conf_h2(ohlc *candle, size_t i, size_t contraction, size_t n);
signal conf_h3(ohlc *candle, size_t i, size_t contraction, size_t n);
signal conf_h4(ohlc *candle, size_t i, size_t contraction, size_t n);
signal conf_h(ohlc *candle, size_t i, size_t contraction, size_t n);
