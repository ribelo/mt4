//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                    Huxley Volume.mq4                                      |
//|                                                                                           |
//+-------------------------------------------------------------------------------------------+
#property copyright "Copyright © 2012 Huxley"
#property link      "email:   huxley_source@gmail.com"
#include <wrb_analysis.mqh>
#include <hxl_utils.mqh>
#include <hanover --- function header (np).mqh>
#include <hanover --- extensible functions (np).mqh>



//+-------------------------------------------------------------------------------------------+
//| Indicator Global Inputs                                                                   |
//+-------------------------------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_buffers 3

#property indicator_color2 C'255,213,98'
#property indicator_color3 C'233,65,103'

#property indicator_width2  2
#property indicator_width3  2

#define  _name "wrb_vsa"
#define  short_name "WRB VSA"

//Global External Inputs

extern int look_back = 1024;
extern int refresh_candles = 0;
extern int look_for_zone = 128;
extern bool nd_ns = true;
extern bool effort = false;
extern color bull_vsa = C'255,213,98';
extern color bear_vsa = C'233,65,103';
extern color text_color = C'56,47,50';
extern bool make_text = true;
extern bool send_notification = true;
extern double label_offset_percent = 3;
extern int font_size = 8;
extern string font_name = "Cantarell";
extern int bar_width = 2;

//Misc
double candle[][6];
int pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
string symbol, global_name;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double vsa_bull[], vsa_bear[], normal[];
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
    ArrayCopyRates(candle, symbol, tf);
    SetIndexBuffer(0, normal);
    SetIndexStyle(0, DRAW_NONE, 0);
    SetIndexBuffer(1, vsa_bull);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, bull_vsa);
    SetIndexLabel(1, "VSA Bull");
    SetIndexBuffer(2, vsa_bear);
    SetIndexStyle(2, DRAW_HISTOGRAM, 0, bar_width, bear_vsa);
    SetIndexLabel(2, "VSA Bear");

    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                                |
//+-------------------------------------------------------------------------------------------+
int deinit() {
    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        string name = ObjectName(i);
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
    for (i = 1; i < limit; i++) {
        normal[i] = iVolume(symbol, tf, i);
        if (_vsa(candle, i, look_for_zone, nd_ns, effort, iBars(symbol, tf), r) != 0) {
            if (r[3] == 1) {
                vsa_bull[r[0]] = iVolume(symbol, tf, r[0]);
            } else if (r[3] == -1) {
                vsa_bear[r[0]] = iVolume(symbol, tf, r[0]);
            }
            if (make_text == true) {
                time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                             TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                text_name = StringConcatenate(_name, "_", time_str);
                if (r[3] == 1) {
                    text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 1, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 1, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 1, i))) / 2) * label_offset_percent;
                    make_text(text_name, "VSA", Time[r[0] + 1], text_price, font_size, text_color) ;
                } else if (r[3] == -1) {
                    text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 1, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 1, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 1, i))) / 2) * label_offset_percent;
                    make_text(text_name, "VSA", Time[r[0] + 1], text_price,  font_size, text_color) ;
                }
            }
            if (send_notification == true) {
                if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                    GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                    if (r[3] == 1) {
                        SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull FVB at " + TimeToStr(iTime(symbol, tf, i)));
                    } else if (r[3] == -1) {
                        SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear FVB at " + TimeToStr(iTime(symbol, tf, i)));
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
