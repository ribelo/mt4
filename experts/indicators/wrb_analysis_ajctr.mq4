//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                  Huxley WRB AJCTR.mq4                                     |
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


#define  i_name "hxl_ajctr"
#define  short_name "Huxley WRB AJCTR"

//Global External Inputs

extern int look_back = 512;
extern int refresh_candles = 0;
extern bool hammer = true;
extern bool harami = true;
extern bool engulfing = true;
extern bool soldiers = true;
extern color ajctr_bull_body = C'252,165,88';
extern color ajctr_bear_body = C'177,83,103';
extern color contraction_bull_body = C'205,138,108';
extern color contraction_bear_body = C'151,125,130';
extern color text_color = C'56,47,50';
extern bool make_text = false;
extern bool send_notification = true;
extern int label_offset_percent = 1;
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

double ajctr_body_open[], ajctr_body_close[];
double contraction_body_open[], contraction_body_close[];
int last_hammer, last_harami, last_engulfing, last_soldiers;
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
    ArrayCopyRates(candle, symbol, tf);
    IndicatorShortName(short_name);
    SetIndexBuffer(0, contraction_body_close);
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, bar_width, contraction_bull_body);
    SetIndexLabel(0, "WRB Contraction");
    SetIndexBuffer(1, contraction_body_open);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, contraction_bear_body);
    SetIndexLabel(1, "WRB Contraction");
    SetIndexBuffer(2, ajctr_body_close);
    SetIndexStyle(2, DRAW_HISTOGRAM, 0, bar_width, ajctr_bull_body);
    SetIndexLabel(2, "WRB AJCTR");
    SetIndexBuffer(3, ajctr_body_open);
    SetIndexStyle(3, DRAW_HISTOGRAM, 0, bar_width, ajctr_bear_body);
    SetIndexLabel(3, "WRB AJCTR");

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
    int i, j, limit, counted_bars, r[4];
    double text_price;
    string text_name, time_str;
    if (!_new_bar(symbol, tf)) {
        return (0);
    }
    if(counted_bars > 0) {
        counted_bars--;
        counted_bars -= refresh_candles;
    }
    limit = MathMin(iBars(symbol, tf) - counted_bars, look_back);
    for (i = limit; i > 0; i--) {
        if (hammer == true) {
            if (_hammer(candle, i, iBars(symbol, tf), r) != 0) {
                if (r[3] == 1) {
                    ajctr_body_open[r[0]] = iLow(symbol, tf, r[0]);
                    ajctr_body_close[r[0]] = iClose(symbol, tf, r[0]);
                } else if (r[3] == -1) {
                    ajctr_body_open[r[0]] = iHigh(symbol, tf, r[0]);
                    ajctr_body_close[r[0]] = iClose(symbol, tf, r[0]);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "HAM", iTime(symbol, tf, r[0] + 1), text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "HAM", iTime(symbol, tf, r[0] + 1), text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Hammer at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Hammer at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (harami == true) {
            static int last_harami = 0;
            if (_harami(candle, i, iBars(symbol, tf), r) != 0) {
                ajctr_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                ajctr_body_close[r[0]] = iClose(symbol, tf, r[0]);
                for (j = 1; j <= r[1] - r[0]; j++) {
                    ajctr_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    ajctr_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "HAR", iTime(symbol, tf, r[0] + 1), text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "HAR", iTime(symbol, tf, r[0] + 1), text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Harami at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Harami at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (engulfing == true) {
            static int last_engulfing = 0;
            if (_engulfing(candle, i, iBars(symbol, tf), r) != 0) {
                ajctr_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                ajctr_body_close[r[0]] = iClose(symbol, tf, r[0]);
                for (j = 1; j <= r[1] - r[0]; j++) {
                    ajctr_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    ajctr_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "ENG", iTime(symbol, tf, r[0] + 1), text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "ENG", iTime(symbol, tf, r[0] + 1), text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Engulfing at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Engulfing at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (soldiers == true) {
            static int last_soldiers = 0;
            if (_soldiers(candle, i, iBars(symbol, tf), r) != 0) {
                ajctr_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                ajctr_body_close[r[0]] = iClose(symbol, tf, r[0]);
                ajctr_body_open[r[0] + 1] = iOpen(symbol, tf, r[0] + 1);
                ajctr_body_close[r[0] + 1] = iClose(symbol, tf, r[0] + 1);
                ajctr_body_open[r[1]] = iOpen(symbol, tf, r[1]);
                ajctr_body_close[r[1]] = iClose(symbol, tf, r[1]);
                ajctr_body_open[r[1] - 1] = iOpen(symbol, tf, r[1] - 1);
                ajctr_body_close[r[1] - 1] = iClose(symbol, tf, r[1] - 1);
                for (j = 2; j <= r[1] - r[0] - 2; j++) {
                    contraction_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    contraction_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "SOL", iTime(symbol, tf, r[0] + 1), text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "SOL", iTime(symbol, tf, r[0] + 1), text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Soldiers at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Soldiers at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }

    }
    return (0);
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+
