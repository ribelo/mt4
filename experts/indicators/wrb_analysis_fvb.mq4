//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                  Huxley FVB.mq4                                      |
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
#property indicator_color1 C'255,213,98'
#property indicator_color2 C'233,65,103'
#property indicator_color3 C'252,165,88'
#property indicator_color4 C'177,83,103'
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1

#define  _name "hxl_fvb"
#define  short_name "Huxley FVB"

//Global External Inputs

extern int look_back = 512;
extern int refres_candles = 0;
extern int look_for_zone = 256;
extern bool draw_zone = false;
extern color bull_fvb = C'255,213,98';
extern color bear_fvb = C'233,65,103';
extern color bull_zone = C'252,165,88';
extern color bear_zone = C'177,83,103';
extern color text_color = C'56,47,50';
extern bool make_text = true;
extern bool send_notification = true;
extern int label_offset_percent = 1.25;
extern int font_size = 8;
extern string font_name = "Cantarell";
extern int bar_width = 1;

//Misc
double candle[][6];
int pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
string symbol, global_name;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double body_fvb_open[], body_fvb_close[];
double body_zone_open[], body_zone_close[];

int last_fvb;
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
    IndicatorShortName(short_name);
    SetIndexBuffer(0, body_fvb_close);
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, bar_width, bull_fvb);
    SetIndexLabel(0, "FVB");
    SetIndexBuffer(1, body_fvb_open);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, bear_fvb);
    SetIndexLabel(1, "FVB");
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
    for (i = 1; i < limit; i++) {
        time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                     TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
        text_name = StringConcatenate(_name, "_", time_str);
        if (_fvb(candle, i, look_for_zone, iBars(symbol, tf), r) != 0) {
            body_fvb_open[r[0]] = iOpen(symbol, tf, r[0]);
            body_fvb_close[r[0]] = iClose(symbol, tf, r[0]);
            body_fvb_open[r[1]] = iOpen(symbol, tf, r[1]);
            body_fvb_close[r[1]] = iClose(symbol, tf, r[1]);
            if (draw_zone == true) {
                body_zone_open[r[2]] = iOpen(symbol, tf, r[2]);
                body_zone_close[r[2]] = iClose(symbol, tf, r[2]);
            }
            if (make_text == true) {
                time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                             TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                text_name = StringConcatenate(_name, "_", time_str);
                if (r[3] == 1) {
                    text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 1, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 1, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 1, i))) / 2) * label_offset_percent;
                    make_text(text_name, "FVB", Time[r[0] + 1], text_price, font_size, text_color) ;
                } else if (r[3] == -1) {
                    text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 1, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 1, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 1, i))) / 2) * label_offset_percent;
                    make_text(text_name, "FVB", Time[r[0] + 1], text_price,  font_size, text_color) ;
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

