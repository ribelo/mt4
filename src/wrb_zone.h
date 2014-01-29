#pragma once

#include "candle.h"


static inline double zone_size(body *body) {
    return fabs(roundp(body->close - body->open, 5));
}


zone swing_point_1(ohlc *candle, size_t i,
                          size_t n, size_t contraction);

zone swing_point_2(ohlc *candle, size_t i,
                          size_t n, size_t contraction);


zone swing_point_3(ohlc *candle, size_t i, size_t n);


zone strong_continuation_1(ohlc *candle, size_t i,
                                  size_t n, size_t contraction);


zone strong_continuation_2(ohlc *candle, size_t i,
                                  size_t n, size_t contraction);


zone strong_continuation_3(ohlc *candle, size_t i,
                                  size_t n, size_t contraction);


zone strong_continuation_4(ohlc *candle, size_t i,
                                  size_t n, size_t contraction);


zone reaction_zone(ohlc *candle, size_t i,
                          size_t n, size_t look_forward);


zone wrb_zone(ohlc *candle, size_t i, size_t n,
                     size_t contraction, int h_zone);
