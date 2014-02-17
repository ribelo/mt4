//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                  Huxley WRB Body.mq4                                      |
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

#define  _name "hxl_wrb"
#define  short_name "Huxley WRB Body"

//Global External Inputs

extern int   look_back = 2048;
extern bool  draw_wrb = true;
extern bool  draw_wrb_hg = true;
extern color bull_wrb_body = C'245,146,86';
extern color bear_wrb_body = C'126,59,73';
extern color bull_wrb_hg_body = C'252,165,88';
extern color bear_wrb_hg_body = C'177,83,103';
extern int bar_width = 1;

//Misc
double candle[][6];
int pip_mult_tab[]={1,10,1,10,1,10,100,1000};
string symbol;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double body_wrb_open[], body_wrb_close[], body_wrb_hg_open[], body_wrb_hg_close[];
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
    SetIndexBuffer(0, body_wrb_close);
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, bar_width, bull_wrb_body);
    SetIndexLabel(0, "WRB");
    SetIndexBuffer(1, body_wrb_open);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, bear_wrb_body);
    SetIndexLabel(1, "WRB");
    SetIndexBuffer(2, body_wrb_hg_close);
    SetIndexStyle(2, DRAW_HISTOGRAM, 0, bar_width, bull_wrb_hg_body);
    SetIndexLabel(2, "WRB HG");
    SetIndexBuffer(3, body_wrb_hg_open);
    SetIndexStyle(3, DRAW_HISTOGRAM, 0, bar_width, bear_wrb_hg_body);
    SetIndexLabel(3, "WRB HG");

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
    int i, limit, counted_bars;
    if (!_new_bar(symbol, tf)) {
        return (0);
    }
    counted_bars = IndicatorCounted();
    if(counted_bars > 0) {
        counted_bars--;
    }
    limit = MathMin(iBars(symbol, tf) - counted_bars, look_back);
    for (i = 1; i < iBars(symbol, tf); i++) {
        if (draw_wrb == true) {
            if (_wrb(candle, i, iBars(symbol, tf)) != 0) {
                body_wrb_open[i] = iOpen(symbol, tf, i);
                body_wrb_close[i] = iClose(symbol, tf, i);
            }
        }
        if (draw_wrb_hg == true) {
            if (_wrb_hg(candle, i, iBars(symbol, tf)) != 0) {
                body_wrb_hg_open[i] = iOpen(symbol, tf, i);
                body_wrb_hg_close[i] = iClose(symbol, tf, i);
            }
        }
    }
    return (0);
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+

