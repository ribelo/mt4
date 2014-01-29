
#include "wrb_analysis.h"

inline body wrb(ohlc *candle, int i);

inline int any_wrb(ohlc *candle, int start, int stop, int n);

inline int any_wrb_bull(ohlc *candle, int start, int stop, int n);

inline int any_wrb_bear(ohlc *candle, int start, int stop, int n);

inline body wrb_hg(ohlc *candle, int i);

inline int any_wrb_hg(ohlc *candle, int start, int stop, int n);

inline int any_wrb_hg_bull(ohlc *candle, int start, int stop, int n);

inline int any_wrb_hg_bear(ohlc *candle, int start, int stop, int n);

inline int fractal_high(ohlc *candle, size_t i, size_t n, size_t l);

inline int fractal_low(ohlc *candle, size_t i, size_t n, size_t l);

inline int fractal(ohlc *candle, size_t i, size_t n, size_t l);

inline int fractal_break(ohlc *candle, size_t i, size_t n, size_t l, size_t look_back);

inline int dcm(ohlc *candle, size_t i, size_t n, size_t look_back);
