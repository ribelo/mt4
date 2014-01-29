//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                  Huxley Fractals.mq4                                      |
//|                                                                                           |
//+-------------------------------------------------------------------------------------------+
#property copyright "Copyright � 2014 Huxley"
#property link      "email:   huxley.source@gmail.com"
#include <wrb_analysis.mqh>
#include <hxl_utils.mqh>


//+-------------------------------------------------------------------------------------------+
//| Indicator Global Inputs                                                                   |
//+-------------------------------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_color1 C'112,92,45'
#property indicator_color2 C'110,89,95'
#property indicator_color3 C'130,103,47'
#property indicator_color4 C'131,98,105'
#property indicator_color5 C'147,114,49'
#property indicator_color6 C'153,106,117'
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1
#property indicator_width5 1
#property indicator_width6 1

#define  i_name "hxl_frctl"
#define  short_name "Huxley Fractals"

//Global External Inputs

extern int lenght = 5;
extern color bull_shadow = C'130,103,47';
extern color bear_shadow = C'131,98,105';
extern int bar_width = 1;

//Misc
double candle[][6];
int pip_mult_tab[]={1,10,1,10,1,10,100,1000};
string symbol;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double shadow_open_weak[], shadow_close_weak[];
double shadow_open[], shadow_close[];
double shadow_open_strong[], shadow_close_strong[];
//+-------------------------------------------------------------------------------------------+
//| Custom indicator initialization function                                                  |
//+-------------------------------------------------------------------------------------------+
int init() {
    symbol = Symbol();
    tf = Period();
    digits = MarketInfo(symbol, MODE_DIGITS);
    multiplier = pip_mult_tab[digits];
    point = MarketInfo(symbol, MODE_POINT) * multiplier;
    spread = MarketInfo(symbol, MODE_SPREAD) * multiplier;
    tickvalue = MarketInfo(symbol, MODE_TICKVALUE) * multiplier;
    if (multiplier > 1) {
        pip_description = " points";
    }
    ArrayCopyRates(candle, symbol, tf);
    IndicatorShortName(short_name);
    SetIndexBuffer(1, shadow_close);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, bull_shadow);
    SetIndexLabel(1, "Fractal " + lenght);
    SetIndexBuffer(2, shadow_open);
    SetIndexStyle(2, DRAW_HISTOGRAM, 0, bar_width, bear_shadow);
    SetIndexLabel(2, "Fractal " + lenght);


    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                                |
//+-------------------------------------------------------------------------------------------+
int deinit() {
    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator iteration function                                                       |
//+-------------------------------------------------------------------------------------------+
int start() {
    int i, limit;
    int counted_bars = IndicatorCounted();
    if (!_new_bar(symbol, tf)) {
        return (0);
    }
    if (iBars(symbol, tf) <= 0) {
        return (0);
    }
    if (counted_bars > 0) {
        counted_bars--;
    }
    limit = Bars - counted_bars - lenght;
    for(i = lenght; i < limit; i++) {
        if(_fractal(candle, i, Bars, lenght) == 1) {
            shadow_open[i] = Low[i];
            shadow_close[i] = MathMin(Open[i], Close[i]);
        }
        if(_fractal(candle, i, Bars, lenght) == -1) {
            shadow_open[i] = High[i];
            shadow_close[i] = MathMax(Open[i], Close[i]);
        }
    }
    return (0);
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+

