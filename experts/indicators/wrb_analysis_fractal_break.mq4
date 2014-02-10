//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                  Huxley Fractal Break.mq4                                      |
//|                                                                                           |
//+-------------------------------------------------------------------------------------------+
#property copyright "Copyright © 2014 Huxley"
#property link      "email:   huxley.source@gmail.com"
#include <wrb_analysis.mqh>
#include <hxl_utils.mqh>
#include <hanover --- function header (np).mqh>
#include <hanover --- extensible functions (np).mqh>


//+-------------------------------------------------------------------------------------------+
//| Indicator Global Inputs                                                                   |
//+-------------------------------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 C'252,165,88'
#property indicator_color2 C'177,83,103'
#property indicator_width1 1
#property indicator_width2 1


#define  i_name "hxl_frctl_brk"
#define  short_name "Huxley Fractal Break"

//Global External Inputs

//extern int lenght_weak = 3;
extern int lenght = 5;
extern int look_back = 256;
extern color bull_body = C'252,165,88';
extern color bear_body = C'177,83,103';
extern int bar_width = 1;

//Misc
double candle[][6];
int pip_mult_tab[]={1,10,1,10,1,10,100,1000};
string symbol;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";
double body_open[], body_close[];
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
    SetIndexBuffer(0, body_close);
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, bar_width, bull_body);
    SetIndexLabel(0, "Fractal " + lenght);
    SetIndexBuffer(1, body_open);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, bear_body);
    SetIndexLabel(1, "Fractal " + lenght);

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
    limit = iBars(symbol, tf) - counted_bars - lenght;
    for(i = lenght; i < limit; i++) {
        if(_fractal_break(candle, i, iBars(symbol, tf), lenght, look_back) != 0) {
            body_open[i] = iOpen(symbol, tf, i);
            body_close[i] = iClose(symbol, tf, i);
        }
    }
    return (0);
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+

