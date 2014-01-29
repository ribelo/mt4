
#include "candle.h"
#include "wrb_toolbox.h"


inline int contraction_share(ohlc *candle, size_t c1, size_t c2);

inline int prior_bull_wrb(ohlc *candle, size_t i, size_t n);

inline int prior_bull_wrb_hg(ohlc *candle, size_t i, size_t n);

inline int prior_bear_wrb(ohlc *candle, size_t i, size_t n);

inline int prior_bear_wrb_hg(ohlc *candle, size_t i, size_t n);

inline int fill_prior_wrb_hg(ohlc *candle, int i,int prior_wrb, size_t n);

inline int contraction_body_size_break(ohlc *candle, size_t c1, size_t c2);

inline int volatility_expand(ohlc *candle, size_t i, int strength, int side);

inline int contraction_retrace(ohlc *candle, size_t c1, size_t c2, size_t n);

inline int zone_bounce(ohlc *candle, size_t i, zone z);

inline int zone_bounce1(ohlc *candle, size_t i, size_t zone);