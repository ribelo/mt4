//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                 Huxley SR Price.mq4                                   |
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

#define  _name "hxl_sr"
#define  short_name "Huxley SR"

//Global External Inputs

extern int   tf_higher = 240;
extern int   tf_main = 60;
extern int   tf_lower = 15;
extern bool  hg_only = true;
extern bool  use_fractal = true;
extern int   fractal_length = 5;
extern color support_higher = C'255,213,98';
extern color resistance_higher = C'233,65,103';
extern color support_main = C'253,186,94';
extern color resistance_main = C'204,83,109';
extern color support_lower = C'252,165,88';
extern color resistance_lower = C'169,77,96';
extern int line_width = 2;

//Misc
double candle_lower[][6];
double candle_main[][6];
double candle_higher[][6];
int pip_mult_tab[]={1,10,1,10,1,10,100,1000};
string symbol;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

string support_name_lower, resistance_name_lower;
string support_name_main, resistance_name_main;
string support_name_higher, resistance_name_higher;
double support_price_lower, resistance_price_lower;
double support_price_main, resistance_price_main;
double support_price_higher, resistance_price_higher;
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
    if (tf_main == 0) {
        tf_main = tf;
    }
    if (tf_lower == 0) {
        tf_lower = _lower_timeframe(tf_main);
    }
    if (tf_higher == 0) {
        tf_higher = _higher_timeframe(tf_main);
    }

    support_name_lower = _name + "_support_" + StringLower(TFToStr(tf_lower));
    resistance_name_lower = _name + "_resistance_" + StringLower(TFToStr(tf_lower));
    support_name_main = _name + "_support_" + StringLower(TFToStr(tf_main));
    resistance_name_main = _name + "_resistance_" + StringLower(TFToStr(tf_main));
    support_name_higher = _name + "_support_" + StringLower(TFToStr(tf_higher));
    resistance_name_higher = _name + "_resistance_" + StringLower(TFToStr(tf_higher));

    ArrayCopyRates(candle_lower, symbol, tf_lower);
    ArrayCopyRates(candle_main, symbol, tf_main);
    ArrayCopyRates(candle_higher, symbol, tf_higher);

    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                                |
//+-------------------------------------------------------------------------------------------+
int deinit() {
    for (int i = ObjectsTotal(OBJ_TEXT) - 1; i >= 0; i--) {
        string name = ObjectName(i);
        int length = StringLen(_name);
        if (StringFind(name, _name) != -1) {
            ObjectDelete(name);
        }
    }
    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator iteration function                                                       |
//+-------------------------------------------------------------------------------------------+
int start() {
    static int last_time;
    if (_new_bar(symbol, tf_lower)) {
        support_price_lower = _support(candle_lower, 1, hg_only, use_fractal,
                                 fractal_length, iBars(symbol, tf_lower));

        resistance_price_lower = _resistance(candle_lower, 1, hg_only, use_fractal,
                                       fractal_length, iBars(symbol, tf_lower));
    }
    if (_new_bar(symbol, tf_main)) {
        support_price_main = _support(candle_main, 1, hg_only, use_fractal,
                                 fractal_length, iBars(symbol, tf_main));
        resistance_price_main = _resistance(candle_main, 1, hg_only, use_fractal,
                                       fractal_length, iBars(symbol, tf_main));

    }
    if (_new_bar(symbol, tf_higher)) {
        support_price_higher = _support(candle_higher, 1, hg_only, use_fractal,
                                 fractal_length, iBars(symbol, tf_higher));
        resistance_price_higher = _resistance(candle_higher, 1, hg_only, use_fractal,
                                       fractal_length, iBars(symbol, tf_higher));

    }
    if (last_time != iTime(symbol, Period(), 0)) {
        last_time = iTime(symbol, Period(), 0);
        if (ObjectFind(support_name_lower) == -1) {
            ObjectCreate(support_name_lower, OBJ_TREND, 0, iTime(symbol, tf_main, 0), support_price_lower, iTime(symbol, tf_main, 0) + 5 * Period() * 60, support_price_lower);
            ObjectSet(support_name_lower, OBJPROP_COLOR, support_lower);
            ObjectSet(support_name_lower, OBJPROP_WIDTH, line_width);
            ObjectSet(support_name_lower, OBJPROP_BACK, true);
            ObjectSet(support_name_lower, OBJPROP_RAY, true);
        } else {
            ObjectSet(support_name_lower, OBJPROP_TIME1, iTime(symbol, tf_main, 0));
            ObjectSet(support_name_lower, OBJPROP_TIME2, iTime(symbol, tf_main, 0) + 5 * Period() * 60);
            ObjectSet(support_name_lower, OBJPROP_PRICE1, support_price_lower);
            ObjectSet(support_name_lower, OBJPROP_PRICE2, support_price_lower);
            ObjectSet(support_name_lower, OBJPROP_COLOR, support_lower);
            ObjectSet(support_name_lower, OBJPROP_WIDTH, line_width);
            ObjectSet(support_name_lower, OBJPROP_BACK, true);
            ObjectSet(support_name_lower, OBJPROP_RAY, true);
        }
        if (ObjectFind(resistance_name_lower) == -1) {
            ObjectCreate(resistance_name_lower, OBJ_TREND, 0, iTime(symbol, tf_main, 0), resistance_price_lower, iTime(symbol, tf_main, 0) + 5 * Period() * 60, resistance_price_lower);
            ObjectSet(resistance_name_lower, OBJPROP_COLOR, resistance_lower);
            ObjectSet(resistance_name_lower, OBJPROP_WIDTH, line_width);
            ObjectSet(resistance_name_lower, OBJPROP_BACK, true);
            ObjectSet(resistance_name_lower, OBJPROP_RAY, true);
        } else {
            ObjectSet(resistance_name_lower, OBJPROP_TIME1, iTime(symbol, tf_main, 0));
            ObjectSet(resistance_name_lower, OBJPROP_TIME2, iTime(symbol, tf_main, 0) + 5 * Period() * 60);
            ObjectSet(resistance_name_lower, OBJPROP_PRICE1, resistance_price_lower);
            ObjectSet(resistance_name_lower, OBJPROP_PRICE2, resistance_price_lower);
            ObjectSet(resistance_name_lower, OBJPROP_COLOR, resistance_lower);
            ObjectSet(resistance_name_lower, OBJPROP_WIDTH, line_width);
            ObjectSet(resistance_name_lower, OBJPROP_BACK, true);
            ObjectSet(resistance_name_lower, OBJPROP_RAY, true);
        }
        if (ObjectFind(support_name_main) == -1) {
            ObjectCreate(support_name_main, OBJ_TREND, 0, iTime(symbol, tf_main, 0), support_price_main, iTime(symbol, tf_main, 0) + 5 * Period() * 60, support_price_main);
            ObjectSet(support_name_main, OBJPROP_COLOR, support_main);
            ObjectSet(support_name_main, OBJPROP_WIDTH, line_width);
            ObjectSet(support_name_main, OBJPROP_BACK, true);
            ObjectSet(support_name_main, OBJPROP_RAY, true);
        } else {
            ObjectSet(support_name_main, OBJPROP_TIME1, iTime(symbol, tf_main, 0));
            ObjectSet(support_name_main, OBJPROP_TIME2, iTime(symbol, tf_main, 0) + 5 * Period() * 60);
            ObjectSet(support_name_main, OBJPROP_PRICE1, support_price_main);
            ObjectSet(support_name_main, OBJPROP_PRICE2, support_price_main);
            ObjectSet(support_name_main, OBJPROP_COLOR, support_main);
            ObjectSet(support_name_main, OBJPROP_WIDTH, line_width);
            ObjectSet(support_name_main, OBJPROP_BACK, true);
            ObjectSet(support_name_main, OBJPROP_RAY, true);
        }
        if (ObjectFind(resistance_name_main) == -1) {
            ObjectCreate(resistance_name_main, OBJ_TREND, 0, iTime(symbol, tf_main, 0), resistance_price_main, iTime(symbol, tf_main, 0) + 5 * Period() * 60, resistance_price_main);
            ObjectSet(resistance_name_main, OBJPROP_COLOR, resistance_main);
            ObjectSet(resistance_name_main, OBJPROP_WIDTH, line_width);
            ObjectSet(resistance_name_main, OBJPROP_BACK, true);
            ObjectSet(resistance_name_main, OBJPROP_RAY, true);
        } else {
            ObjectSet(resistance_name_main, OBJPROP_TIME1, iTime(symbol, tf_main, 0));
            ObjectSet(resistance_name_main, OBJPROP_TIME2, iTime(symbol, tf_main, 0) + 5 * Period() * 60);
            ObjectSet(resistance_name_main, OBJPROP_PRICE1, resistance_price_main);
            ObjectSet(resistance_name_main, OBJPROP_PRICE2, resistance_price_main);
            ObjectSet(resistance_name_main, OBJPROP_COLOR, resistance_main);
            ObjectSet(resistance_name_main, OBJPROP_WIDTH, line_width);
            ObjectSet(resistance_name_main, OBJPROP_BACK, true);
            ObjectSet(resistance_name_main, OBJPROP_RAY, true);
        }
        if (ObjectFind(support_name_higher) == -1) {
            ObjectCreate(support_name_higher, OBJ_TREND, 0, iTime(symbol, tf_main, 0), support_price_higher, iTime(symbol, tf_main, 0) + 5 * Period() * 60, support_price_higher);
            ObjectSet(support_name_higher, OBJPROP_COLOR, support_higher);
            ObjectSet(support_name_higher, OBJPROP_WIDTH, line_width);
            ObjectSet(support_name_higher, OBJPROP_BACK, true);
            ObjectSet(support_name_higher, OBJPROP_RAY, true);
        } else {
            ObjectSet(support_name_higher, OBJPROP_TIME1, iTime(symbol, tf_main, 0));
            ObjectSet(support_name_higher, OBJPROP_TIME2, iTime(symbol, tf_main, 0) + 5 * Period() * 60);
            ObjectSet(support_name_higher, OBJPROP_PRICE1, support_price_higher);
            ObjectSet(support_name_higher, OBJPROP_PRICE2, support_price_higher);
            ObjectSet(support_name_higher, OBJPROP_COLOR, support_higher);
            ObjectSet(support_name_higher, OBJPROP_WIDTH, line_width);
            ObjectSet(support_name_higher, OBJPROP_BACK, true);
            ObjectSet(support_name_higher, OBJPROP_RAY, true);
        }
        if (ObjectFind(resistance_name_higher) == -1) {
            ObjectCreate(resistance_name_higher, OBJ_TREND, 0, iTime(symbol, tf_main, 0), resistance_price_higher, iTime(symbol, tf_main, 0) + 5 * Period() * 60, resistance_price_higher);
            ObjectSet(resistance_name_higher, OBJPROP_COLOR, resistance_higher);
            ObjectSet(resistance_name_higher, OBJPROP_WIDTH, line_width);
            ObjectSet(resistance_name_higher, OBJPROP_BACK, true);
            ObjectSet(resistance_name_higher, OBJPROP_RAY, true);
        } else {
            ObjectSet(resistance_name_higher, OBJPROP_TIME1, iTime(symbol, tf_main, 0));
            ObjectSet(resistance_name_higher, OBJPROP_TIME2, iTime(symbol, tf_main, 0) + 5 * Period() * 60);
            ObjectSet(resistance_name_higher, OBJPROP_PRICE1, resistance_price_higher);
            ObjectSet(resistance_name_higher, OBJPROP_PRICE2, resistance_price_higher);
            ObjectSet(resistance_name_higher, OBJPROP_COLOR, resistance_higher);
            ObjectSet(resistance_name_higher, OBJPROP_WIDTH, line_width);
            ObjectSet(resistance_name_higher, OBJPROP_BACK, true);
            ObjectSet(resistance_name_higher, OBJPROP_RAY, true);
        }
    }
    return (0);
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+
