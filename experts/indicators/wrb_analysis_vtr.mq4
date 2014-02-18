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
#include <hanover --- extensible functions (np).mqh>


//+-------------------------------------------------------------------------------------------+
//| Indicator Global Inputs                                                                   |
//+-------------------------------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_color1 C'205,138,108'
#property indicator_color2 C'151,125,130'
#property indicator_color3 C'252,165,88'
#property indicator_color4 C'177,83,103'
#property indicator_color5 C'255,213,98'
#property indicator_color6 C'233,65,103'
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1
#property indicator_width5 1
#property indicator_width6 1

#define  _name "hxl_vtr"
#define  short_name "Huxley VTR"

//Global External Inputs

extern int look_back = 512;
extern int refresh_candles = 0;
extern int look_for_zone = 256;
extern string sister_symbol = "";
extern bool invert_sister = 0;
extern bool draw_zone = false;
extern color bull_vtr = C'255,213,98';
extern color bear_vtr = C'233,65,103';
extern color contraction_bull_body = C'205,138,108';
extern color contraction_bear_body = C'151,125,130';
extern color bull_zone = C'252,165,88';
extern color bear_zone = C'177,83,103';
extern color text_color = C'56,47,50';
extern bool make_text = true;
extern bool send_notification = true;
extern double label_offset_percent = 1.0;
extern int font_size = 8;
extern string font_name = "Cantarell";
extern int bar_width = 1;

//Misc
double main[][6], sister[][6];
int pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
string symbol, global_name;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double body_vtr_open[], body_vtr_close[];
double contraction_body_open[], contraction_body_close[];
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
    global_name = StringLower(_name + "_" + ReduceCcy(symbol) + "_" + TFToStr(tf));
    if (multiplier > 1) {
        pip_description = " points";
    }
    ArrayCopyRates(main, symbol, tf);
    ArrayCopyRates(sister, sister_symbol, tf);
    IndicatorShortName(short_name);
    SetIndexBuffer(0, contraction_body_close);
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, bar_width, contraction_bull_body);
    SetIndexLabel(0, "VTR Contraction");
    SetIndexBuffer(1, contraction_body_open);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, contraction_bear_body);
    SetIndexLabel(1, "VTR Contraction");
    SetIndexBuffer(2, body_zone_close);
    SetIndexStyle(2, DRAW_HISTOGRAM, 0, bar_width, bull_zone);
    SetIndexLabel(2, "VTR Zone");
    SetIndexBuffer(3, body_zone_open);
    SetIndexStyle(3, DRAW_HISTOGRAM, 0, bar_width, bear_zone);
    SetIndexLabel(3, "VTR Zone");
    SetIndexBuffer(4, body_vtr_close);
    SetIndexStyle(4, DRAW_HISTOGRAM, 0, bar_width, bull_vtr);
    SetIndexLabel(4, "VTR");
    SetIndexBuffer(5, body_vtr_open);
    SetIndexStyle(5, DRAW_HISTOGRAM, 0, bar_width, bear_vtr);
    SetIndexLabel(5, "VTR");

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
        if (_vtr(main, sister, i, invert_sister,
                     look_for_zone, iBars(symbol, tf),
                     iBars(sister_symbol, tf), r) != 0) {
            body_vtr_open[r[0]] = iOpen(symbol, tf, r[0]);
            body_vtr_close[r[0]] = iClose(symbol, tf, r[0]);
            body_vtr_open[r[1]] = iOpen(symbol, tf, r[1]);
            body_vtr_close[r[1]] = iClose(symbol, tf, r[1]);
            for (j = 1; j < r[1] - r[0]; j++) {
                contraction_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                contraction_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
            }
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

