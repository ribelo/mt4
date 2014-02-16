#pragma once

#include "candle.h"


int hammer_line_bull(ohlc *candle, size_t i, size_t n);


int hammer_line_bear(ohlc *candle, size_t i, size_t n);


int deep_shadow_upper(ohlc *candle, size_t i);


int deep_shadow_bottom(ohlc *candle, size_t i);


int big_body_bull(ohlc *candle, size_t i);


int big_body_bear(ohlc *candle, size_t i);


signal hammer(ohlc *candle, size_t i);


signal harami(ohlc *candle, size_t i);


signal engulfing(ohlc *candle, size_t i);


signal soldiers(ohlc *candle, size_t i, size_t n);
