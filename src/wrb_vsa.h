#pragma once

#include "candle.h"

signal vsa_a(ohlc *candle, size_t i, size_t n);

signal vsa_b(ohlc *candle, size_t i, size_t n);

signal vsa_c(ohlc *candle, size_t i, size_t n);

signal vsa_d(ohlc *candle, size_t i, size_t n);

signal vsa_e(ohlc *candle, size_t i, size_t n);

signal vsa_f(ohlc *candle, size_t i, size_t n);

signal vsa_g(ohlc *candle, size_t i, size_t n);

signal vsa_h(ohlc *candle, size_t i, size_t n);

signal effort_a(ohlc *candle, size_t i, size_t n);

signal effort_b(ohlc *candle, size_t i, size_t n);

signal effort_c(ohlc *candle, size_t i, size_t n);

signal effort_d(ohlc *candle, size_t i, size_t n);

signal effort_e(ohlc *candle, size_t i, size_t n);

signal vsa(ohlc *candle, size_t i, size_t look_for_zone, int nd_ns, int effort, size_t n);
