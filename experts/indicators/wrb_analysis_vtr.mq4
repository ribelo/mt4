//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                  Huxley VTR.mq4                                      |
//|                                                                                           |
//+-------------------------------------------------------------------------------------------+
#property copyright "Copyright © 2014 Huxley"
#property link      "email:   huxley.source@gmail.com"
#include <wrb_analysis.mqh>
#include <hxl_utils.mqh>
#include <hanover --- function header (np).mqh>


//+-------------------------------------------------------------------------------------------+
//| Indicator Global Inputs                                                                   |
//+-------------------------------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 C'255,213,98'
#property indicator_color2 C'233,65,103'
#property indicator_color3 C'252,165,88'
#property indicator_color4 C'177,83,103'
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1

#define  i_name "hxl_vtr"
#define  short_name "Huxley VTR"

//Global External Inputs

extern int look_back = 512;
extern string sister_symbol = "";
extern bool invert_sister = 0;
extern int look_for_zone = 256;
extern bool draw_zone = true;
extern color bull_vtr = C'255,213,98';
extern color bear_vtr = C'233,65,103';
extern color bull_zone = C'252,165,88';
extern color bear_zone = C'177,83,103';
extern color text_color = C'56,47,50';
extern bool make_text = false;
extern bool send_notification = true;
extern int label_offset_percent = 1;
extern int font_size = 8;
extern string font_name = "Tahoma";
extern int bar_width = 1;

//Misc
double main[][6], sister[][6];
int pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
string symbol, global_name;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double body_vtr_open[], body_vtr_close[];
double body_zone_open[], body_zone_close[];

double last_vtr;
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
    global_name = StringLower(i_name + "_" + ReduceCcy(symbol) + "_" + TFToStr(tf));
    if (multiplier > 1) {
        pip_description = " points";
    }
    ArrayCopyRates(main, symbol, tf);
    ArrayCopyRates(sister, sister_symbol, tf);
    IndicatorShortName(short_name);
    SetIndexBuffer(0, body_vtr_close);
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, bar_width, bull_vtr);
    SetIndexLabel(0, "VTR");
    SetIndexBuffer(1, body_vtr_open);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, bear_vtr);
    SetIndexLabel(1, "VTR");
    SetIndexBuffer(2, body_zone_close);
    SetIndexStyle(2, DRAW_HISTOGRAM, 0, bar_width, bull_zone);
    SetIndexLabel(2, "ZONE");
    SetIndexBuffer(3, body_zone_open);
    SetIndexStyle(3, DRAW_HISTOGRAM, 0, bar_width, bear_zone);
    SetIndexLabel(3, "ZONE");

    if (!GlobalVariableCheck(global_name)) {
        GlobalVariableSet(global_name, 0);
    }
    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                                |
//+-------------------------------------------------------------------------------------------+
int deinit() {
    for (int i = ObjectsTotal(OBJ_TEXT) - 1; i >= 0; i--) {
        string name = ObjectName(i);
        int length = StringLen(i_name);
        if (StringSubstr(name, 0, length) == i_name) {
            ObjectDelete(name);
        }
        if (StringSubstr(name, 0, length) == i_name) {
            ObjectDelete(name);
        }
    }
    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator iteration function                                                       |
//+-------------------------------------------------------------------------------------------+
int start() {
    int i, limit, r[4];
    int counted_bars = IndicatorCounted();
    double text_price;
    string text_name, time_str;
    if (!_new_bar(symbol, tf)) {
        return (0);
    }
    if (iBars(symbol, tf) <= 0) {
        return (0);
    }
    if (counted_bars > 0) {
        counted_bars--;
    }
    limit = MathMin(iBars(symbol, tf) - counted_bars, look_back);
    for (i = 1; i < limit; i++) {
        if (_vtr(main, sister, i, invert_sister,
                     look_for_zone, iBars(symbol, tf),
                     iBars(sister_symbol, tf), r) != 0) {
            body_vtr_open[r[0]] = iOpen(symbol, tf, r[0]);
            body_vtr_close[r[0]] = iClose(symbol, tf, r[0]);
            body_vtr_open[r[1]] = iOpen(symbol, tf, r[1]);
            body_vtr_close[r[1]] = iClose(symbol, tf, r[1]);
            if (draw_zone == true) {
                body_zone_open[r[2]] = iOpen(symbol, tf, r[2]);
                body_zone_close[r[2]] = iClose(symbol, tf, r[2]);
            }
            if (make_text == true) {
                time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                             TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                text_name = StringConcatenate(i_name, "_", time_str);
                if (r[3] == 1) {
                    text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 1, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 1, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 1, i))) / 2) * label_offset_percent;
                    make_text(text_name, "VTR", Time[r[0] + 1], text_price, font_size, text_color) ;
                } else if (r[3] == -1) {
                    text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 1, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 1, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 1, i))) / 2) * label_offset_percent;
                    make_text(text_name, "VTR", Time[r[0] + 1], text_price,  font_size, text_color) ;
                }
            }
            if (send_notification == true) {
                if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                    GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                    if (r[3] == 1) {
                        SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull VTR at " + TimeToStr(iTime(symbol, tf, i)));
                    } else if (r[3] == -1) {
                        SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear VTR at " + TimeToStr(iTime(symbol, tf, i)));
                    }
                }
            }
        }
    }
    return (0);
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+

