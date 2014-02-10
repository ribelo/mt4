//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                 Huxley WRB Trailing.mq4                                   |
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
#property indicator_buffers 4
#property indicator_color1 C'245,146,86'
#property indicator_color2 C'126,59,73'
#property indicator_color3 C'252,165,88'
#property indicator_color4 C'177,83,103'
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1

#define  i_name "hxl_wrb"
#define  short_name "Huxley WRB Trailing"

//Global External Inputs

extern bool  hg_only = true;
extern bool  use_fractal = true;
extern int   fractal_length = 5;
extern color buy_stop_loss = C'245,146,86';
extern color sell_stop_loss = C'126,59,73';
extern int line_width = 1;

//Misc
double candle[][6];
int pip_mult_tab[]={1,10,1,10,1,10,100,1000};
string symbol;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double line_buy[], line_sell[];
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
    SetIndexBuffer(0, line_buy);
    SetIndexStyle(0, DRAW_LINE, 0, line_width, buy_stop_loss);
    SetIndexLabel(0, "WRB Trailing");
    SetIndexBuffer(1, line_sell);
    SetIndexStyle(1, DRAW_LINE, 0, line_width, sell_stop_loss);
    SetIndexLabel(1, "WRB Trailing");

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
    int i, j, limit;
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
    limit = iBars(symbol, tf) - counted_bars;
    for (i = 512; i > 0; i--) {
        line_buy[i] = _support(candle, i, hg_only, use_fractal,
                               fractal_length, iBars(symbol, tf));
        line_sell[i] = _resistance(candle, i, hg_only, use_fractal,
                                   fractal_length, iBars(symbol, tf));

    }
    return (0);
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+
