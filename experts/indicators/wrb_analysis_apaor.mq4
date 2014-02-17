//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                  Huxley APAOR.mq4                                    |
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

#define  _name "hxl_apaor"
#define  short_name "Huxley APAOR"

//Global External Inputs

extern int look_back = 512;
extern int refresh_candles = 64;
extern string sister_symbol = "";
extern bool invert_sister = false;
extern int pA_length = 10;
extern int pB_length = 3;
extern color bull_divergence = C'255,213,98';
extern color bear_divergence = C'233,65,103';
extern bool send_notification = true;
extern int label_offset_percent = 1;
extern int line_width = 1;

//Misc
double main[][6], sister[][6];
int pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
string symbol, global_name;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double body_apaor_open[], body_apaor_close[];
double body_zone_open[], body_zone_close[];

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
    global_name = StringLower(_name + "_" + ReduceCcy(symbol) + "_" + TFToStr(tf));
    if (multiplier > 1) {
        pip_description = " points";
    }
    ArrayCopyRates(main, symbol, tf);
    ArrayCopyRates(sister, sister_symbol, tf);
    IndicatorShortName(short_name);

    if (!GlobalVariableCheck(global_name)) {
        GlobalVariableSet(global_name, 0);
    }
    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                                |
//+-------------------------------------------------------------------------------------------+
int deinit() {
    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
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
    int i, j, limit, counted_bars, r[4];
    double text_price;
    string text_name, time_str;
    if (!_new_bar(symbol, tf)) {
        return (0);
    }
    counted_bars = IndicatorCounted();
    if(counted_bars > 0) {
        counted_bars--;
        counted_bars -= refresh_candles;
    }
    limit = MathMin(iBars(symbol, tf) - counted_bars, look_back);
    for (i = limit; i > pB_length; i--) {
        if (_apaor(main, sister, i, pA_length, pB_length, invert_sister, look_back,
                   iBars(symbol, tf), iBars(sister_symbol, tf), r) != 0) {
            draw_line(r[0], r[1], r[3]);
            if (send_notification == true) {
                if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                    GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                    if (r[3] == 1) {
                        SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull APAOR at " + TimeToStr(iTime(symbol, tf, i)));
                    } else if (r[3] == -1) {
                        SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear APAOR at " + TimeToStr(iTime(symbol, tf, i)));
                    }
                }
            }
        }
    }
    return (0);
}


void draw_line(int pB, int pA, int dir) {
    double pA_price, pB_price;
    color line_color;
    string time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, pB), TIME_DATE), "_",
                                        TimeToStr(iTime(symbol, tf, pB), TIME_MINUTES));
    string line_name = StringConcatenate(_name, "_apaor_line_", time_str);
    if (dir == 1) {
        pA_price = Low[pA];
        pB_price = Low[pB];
        line_color = bull_divergence;
    } else if (dir == -1) {
        pA_price = High[pA];
        pB_price = High[pB];
        line_color = bear_divergence;
    }
    if (ObjectFind(line_name) == -1) {
        ObjectCreate(line_name, OBJ_TREND, 0, iTime(symbol, tf, pA), pA_price, iTime(symbol, tf, pB), pB_price);
        ObjectSet(line_name, OBJPROP_COLOR, line_color);
        ObjectSet(line_name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSet(line_name, OBJPROP_WIDTH, line_width);
        ObjectSet(line_name, OBJPROP_RAY, false);
        ObjectSet(line_name, OBJPROP_BACK, true);
    }
}

//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+

