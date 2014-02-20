//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                    Huxley DIV.mq4                                      |
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
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 1
#property indicator_buffers 2

#property indicator_color1  C'205,138,108'
#property indicator_color2  C'151,125,130'

#define  _name "hxl_div"
#define  short_name "Huxley DIV"

//Global External Inputs
extern int look_back = 512;
extern string sister_symbol = "";
extern bool invert_sister = false;
extern int pA_length = 10;
extern color bull_color = C'205,138,108';
extern color bear_color = C'151,125,130';
extern int bar_width = 2;
extern bool show_label = true;

//Misc
double main[][6], sister[][6];
int pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
string symbol, global_name;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double div_bull[], div_bear[];

int last_dcm;
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
    ArrayCopyRates(main, symbol, tf);
    ArrayCopyRates(sister, sister_symbol, tf);
    IndicatorShortName(short_name);
    SetIndexBuffer(0, div_bull);
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, bar_width, bull_color);
    SetIndexLabel(0, "Bull DIV");
    SetIndexBuffer(1, div_bear);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, bear_color);
    SetIndexLabel(1, "Bear DIV");

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
    int i, div, limit, counted_bars;
    if (!_new_bar(symbol, tf)) {
        return (0);
    }
    counted_bars = IndicatorCounted();
    if(counted_bars > 0) {
        counted_bars--;
    }
    limit = MathMin(iBars(symbol, tf) - counted_bars, look_back);
    for(i = 1; i < limit; i++) {
        div = _div_insta(main, sister, i, pA_length, invert_sister, look_back,
                         iBars(symbol, tf), iBars(sister_symbol, tf));
        if (div == 1) {
            div_bull[i] = 1;
        } else if (div == -1) {
            div_bear[i] = 1;
        }
    }
    return (0);
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+
