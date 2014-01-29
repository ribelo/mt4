
#include "candle.h"

inline int dir(ohlc *candle, size_t i);

inline int consecutive_dir(ohlc *candle, size_t i);

inline double body_size(ohlc *candle, size_t i);

inline double body_mid_point(ohlc *candle, size_t i);

inline int broke_body_size(ohlc *candle, size_t i, size_t j);

inline int body_size_break(ohlc *candle, size_t i);

inline double gap(ohlc *candle, size_t i);

inline int broke_bars(ohlc *candle, size_t i, size_t j);

inline int bars_broken_by_body(ohlc *candle, size_t i);

inline double shadow_upper(ohlc *candle, size_t i);

inline double shadow_bottom(ohlc *candle, size_t i);

inline int unfilled(ohlc *candle, size_t i, size_t);

inline int filled_by(ohlc *candle, size_t i, int n);

inline double highest_open(ohlc *candle, size_t start, size_t stop);

inline double highest_high(ohlc *candle, size_t start, size_t stop);

inline double highest_low(ohlc *candle, size_t start, size_t stop);

inline double highest_close(ohlc *candle, size_t start, size_t stop);

inline double highest_vol(ohlc *candle, size_t start, size_t stop);

inline double highest_body(ohlc *candle, size_t start, size_t stop);

inline double lowest_open(ohlc *candle, size_t start, size_t stop);

inline double lowest_high(ohlc *candle, size_t start, size_t stop);

inline double lowest_low(ohlc *candle, size_t start, size_t stop);

inline double lowest_close(ohlc *candle, size_t start, size_t stop);

inline double lowest_vol(ohlc *candle, size_t start, size_t stop);

inline double lowest_body(ohlc *candle, size_t start, size_t stop);

inline double biggest_body(ohlc *candle, size_t start, size_t stop);

inline double smalest_body(ohlc *candle, size_t start, size_t stop);

inline double biggest_shadow_upper(ohlc *candle, size_t start, size_t stop);

inline double smalest_shadow_upper(ohlc *candle, size_t start, size_t stop);

inline double biggest_shadow_bottom(ohlc *candle, size_t start, size_t stop);

inline double smalest_shadow_bottom(ohlc *candle, size_t start, size_t stop);
