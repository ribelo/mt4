//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                  Huxley WRB Zone.mq4                                      |
//|                                                                                           |
//+-------------------------------------------------------------------------------------------+
#property copyright "Copyright © 2014 Huxley"
#property link      "email:   huxley.source@gmail.com"
#include <gsl_math.mqh>
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
#property indicator_color5 C'252,165,88'
#property indicator_color6 C'177,83,103'
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1
#property indicator_width5 1
#property indicator_width6 1


#define  _name "hxl_wrb_zone"
#define  short_name "Huxley WRB Zone"

//Global External Inputs

extern int look_back = 1024;
extern int refresh_candles = 16;
extern int contraction_size = 16;
extern bool swing_point_1 = true;
extern bool swing_point_2 = true;
extern bool swing_point_3 = true;
extern bool strong_continuation_1 = true;
extern bool strong_continuation_2 = true;
extern bool strong_continuation_3 = false;
extern bool strong_continuation_4 = false;
extern bool reaction_zone = true;
extern color zone_bull_body = C'252,165,88';
extern color zone_bear_body = C'177,83,103';
extern color contraction_bull_body = C'205,138,108';
extern color contraction_bear_body = C'151,125,130';
extern color zone_color = C'111,116,125';
extern color zone_hg_color = C'147,141,125';
extern color text_color = C'56,47,50';
extern bool make_text = false;
extern bool draw_zone = true;
extern bool draw_filled = false;
extern int draw_old = 512;
extern bool send_notification = false;
extern double label_offset_percent = 2;
extern int font_size = 8;
extern string font_name = "Cantarell";
extern int bar_width = 1;
extern int line_width = 1;

//Misc
double candle[][6];
int pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
string symbol, global_name;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double v1_body_open[], v1_body_close[], v2_body_open[], v2_body_close[];
double contraction_body_open[], contraction_body_close[];

int last_sp1, last_sp2, last_sp3, last_sc1, last_sc2, last_sc3, last_sc4, last_rz;
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
    SetIndexBuffer(0, contraction_body_close);
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, bar_width, contraction_bull_body);
    SetIndexLabel(0, "WRB Contraction");
    SetIndexBuffer(1, contraction_body_open);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, contraction_bear_body);
    SetIndexLabel(1, "WRB Contraction");
    SetIndexBuffer(2, v2_body_close);
    SetIndexStyle(2, DRAW_HISTOGRAM, 0, bar_width, zone_bull_body);
    SetIndexLabel(2, "WRB Zone V2");
    SetIndexBuffer(3, v2_body_open);
    SetIndexStyle(3, DRAW_HISTOGRAM, 0, bar_width, zone_bear_body);
    SetIndexLabel(3, "WRB Zone V2");
    SetIndexBuffer(4, v1_body_close);
    SetIndexStyle(4, DRAW_HISTOGRAM, 0, bar_width, zone_bull_body);
    SetIndexLabel(4, "WRB Zone V1");
    SetIndexBuffer(5, v1_body_open);
    SetIndexStyle(5, DRAW_HISTOGRAM, 0, bar_width, zone_bear_body);
    SetIndexLabel(5, "WRB Zone V1");

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
    for (i = limit; i > 0; i--) {
        v1_body_open[i] = 0.0;
        v1_body_close[i] = 0.0;
        v2_body_open[i] = 0.0;
        v2_body_close[i] = 0.0;
        contraction_body_open[i] = 0.0;
        contraction_body_close[i] = 0.0;
        if (swing_point_1 == true) {
            if (_swing_point_1(candle, i, contraction_size,
                               iBars(symbol, tf), r) != 0) {
                v1_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                v1_body_close[r[0]] = iClose(symbol, tf, r[0]);
                v2_body_open[r[1]] = iOpen(symbol, tf, r[1]);
                v2_body_close[r[1]] = iClose(symbol, tf, r[1]);
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    contraction_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_sp1_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SP1", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > GlobalVariableGet(global_name)) {
                        GlobalVariableSet(global_name, iTime(symbol, tf, r[0]));
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Swing Point 1 at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Swing Point 1 at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (swing_point_2 == true) {
            if (_swing_point_2(candle, i, contraction_size,
                               iBars(symbol, tf), r) != 0) {
                v1_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                v1_body_close[r[0]] = iClose(symbol, tf, r[0]);
                v2_body_open[r[1]] = iOpen(symbol, tf, r[1]);
                v2_body_close[r[1]] = iClose(symbol, tf, r[1]);
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    contraction_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_sp2_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SP2", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > last_sp2) {
                        last_sp2 = iTime(symbol, tf, r[0]);
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Swing Point 2 at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Swing Point 2 at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (swing_point_3 == true) {
            if (_swing_point_3(candle, i, iBars(symbol, tf), r) != 0) {
                if (r[3] == 1) {
                    v1_body_open[r[0]] = Low[r[0]];
                    v1_body_close[r[0]] = MathMin(iClose(symbol, tf, r[0]), iOpen(symbol, tf, r[0]));
                } else if (r[3] == -1) {
                    v1_body_open[r[0]] = High[r[0]];
                    v1_body_close[r[0]] = MathMax(iClose(symbol, tf, r[0]), iOpen(symbol, tf, r[0]));
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_sp3_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, r[0]) - ((iHigh(symbol, tf, r[0]) - iLow(symbol, tf, r[0])) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, r[0]) + ((iHigh(symbol, tf, r[0]) - iLow(symbol, tf, r[0])) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SP3", Time[r[0]], text_price, font_size, text_color);
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > last_sp3) {
                        last_sp3 = iTime(symbol, tf, r[0]);
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Swing Point 3 at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Swing Point 3 at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (strong_continuation_1 == true) {
            if (_strong_continuation_1(candle, i, contraction_size,
                                       iBars(symbol, tf), r) != 0) {
                v1_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                v1_body_close[r[0]] = iClose(symbol, tf, r[0]);
                v2_body_open[r[1]] = iOpen(symbol, tf, r[1]);
                v2_body_close[r[1]] = iClose(symbol, tf, r[1]);
                int v1 = MathRound(MathMin(r[0], r[1]));
                for (j = 1; j < MathAbs(r[1] - r[0]); j++) {
                    contraction_body_open[v1 + j] = Open[v1 + j];
                    contraction_body_close[v1 + j] = Close[v1 + j];
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_sc1_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SC1", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > last_sc1) {
                        last_sc1 = iTime(symbol, tf, r[0]);
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Strong Continuation 1 at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Strong Continuation 1 at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (strong_continuation_2 == true) {
            if (_strong_continuation_2(candle, i, contraction_size,
                                       iBars(symbol, tf), r) != 0) {
                v1_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                v1_body_close[r[0]] = iClose(symbol, tf, r[0]);
                v2_body_open[r[1]] = iOpen(symbol, tf, r[1]);
                v2_body_close[r[1]] = iClose(symbol, tf, r[1]);
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    contraction_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_sc2_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SC2", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > last_sc2) {
                        last_sc2 = iTime(symbol, tf, r[0]);
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Strong Continuation 2 at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Strong Continuation 2 at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (strong_continuation_3 == true) {
            if (_strong_continuation_3(candle, i, contraction_size,
                                       iBars(symbol, tf), r) != 0) {
                v1_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                v1_body_close[r[0]] = iClose(symbol, tf, r[0]);
                v2_body_open[r[1]] = iOpen(symbol, tf, r[1]);
                v2_body_close[r[1]] = iClose(symbol, tf, r[1]);
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    contraction_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_sc3_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SC3", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > last_sc3) {
                        last_sc3 = iTime(symbol, tf, r[0]);
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Strong Continuation 3 at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Strong Continuation 3 at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (strong_continuation_4 == true) {
            if (_strong_continuation_4(candle, i, contraction_size,
                                       iBars(symbol, tf), r) != 0) {
                v1_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                v1_body_close[r[0]] = iClose(symbol, tf, r[0]);
                v2_body_open[r[1]] = iOpen(symbol, tf, r[1]);
                v2_body_close[r[1]] = iClose(symbol, tf, r[1]);
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = iOpen(symbol, tf, r[0] + j);
                    contraction_body_close[r[0] + j] = iClose(symbol, tf, r[0] + j);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_sc4_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SC4", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > last_sc4) {
                        last_sc4 = iTime(symbol, tf, r[0]);
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Strong Continuation 4 at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Strong Continuation 4 at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
        if (reaction_zone == true) {
            if (_reaction_zone(candle, i, contraction_size,
                               iBars(symbol, tf), r) != 0) {
                v1_body_open[r[0]] = iOpen(symbol, tf, r[0]);
                v1_body_close[r[0]] = iClose(symbol, tf, r[0]);
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(iTime(symbol, tf, i), TIME_DATE), "_",
                                                 TimeToStr(iTime(symbol, tf, i), TIME_MINUTES));
                    text_name = StringConcatenate(_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "RZ", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (iTime(symbol, tf, r[0]) > last_rz) {
                        last_rz = iTime(symbol, tf, r[0]);
                        if (r[3] == 1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bull Reaction Zone at " + TimeToStr(iTime(symbol, tf, i)));
                        } else if (r[3] == -1) {
                            SendNotification(ReduceCcy(symbol)  + " " + TFToStr(tf) + " Bear Reaction Zone at " + TimeToStr(iTime(symbol, tf, i)));
                        }
                    }
                }
                continue;
            }
        }
    }
    if (draw_zone == true ) {
        validate_zone(v1_body_open, v1_body_close);
    }
    return (0);
}


void validate_zone(double &zone_open[], double &zone_close[]) {
    int i, j, end_bar;

    for (i = 0; i < iBars(symbol, tf); i++) {
        if (zone_open[i] > 0) {
            end_bar = 0;
            if (zone_close[i] > zone_open[i]) {
                for (j = i - 1; j >=0; j--) {
                    if (iLow(symbol, tf, j) <= zone_open[i]) {
                        end_bar = j;
                        break;
                    }
                }
                if (draw_filled || end_bar == 0) {
                    draw_zone(i, end_bar, zone_open[i], zone_close[i]);
                }
            } else if (zone_close[i] < zone_open[i]) {
                for (j = i - 1; j >=0; j--) {
                    if (iHigh(symbol, tf, j) >= zone_open[i]) {
                        end_bar = j;
                        break;
                    }
                }
                if (draw_filled || end_bar == 0) {
                    draw_zone(i, end_bar, zone_open[i], zone_close[i]);
                }
            }
        }
    }
}


void draw_zone(int begin, int end, double zone_open, double zone_close) {
    string time_str = StringConcatenate(TimeToStr(Time[begin], TIME_DATE), "_",
                                        TimeToStr(Time[begin], TIME_MINUTES));
    string open_zone_name = StringConcatenate(_name, "_open_zone_line_", time_str);
    string close_zone_name = StringConcatenate(_name, "_close_zone_line_", time_str);
    string open_hg_name = StringConcatenate(_name, "_open_hg_line_", time_str);
    string close_hg_name = StringConcatenate(_name, "_close_hg_line_", time_str);
    double hg_open = 0.0, hg_close = 0.0;
    int hg_open_begin = 0, hg_close_begin = 0;
    if (begin - end > 3 && begin - end < draw_old) {
        if (zone_close > zone_open &&
                !_fcmp(zone_open, iOpen(symbol, tf, begin)) &&
                !_fcmp(zone_close, iClose(symbol, tf, begin))) {
            if (iHigh(symbol, tf, begin + 1) > zone_open) {
                hg_open = iHigh(symbol, tf, begin + 1);
                hg_open_begin = begin + 1;
            }
            if (iLow(symbol, tf, begin - 1) < zone_close) {
                hg_close = iLow(symbol, tf, begin - 1);
                hg_close_begin = begin - 1;
            }
        } else if (zone_close < zone_open &&
                !_fcmp(zone_open, iOpen(symbol, tf, begin)) &&
                !_fcmp(zone_close, iClose(symbol, tf, begin))) {
            if (iLow(symbol, tf, begin + 1) < zone_open) {
                hg_open = iLow(symbol, tf, begin + 1);
                hg_open_begin = begin + 1;
            }
            if (iHigh(symbol, tf, begin - 1) > zone_close) {
                hg_close = iHigh(symbol, tf, begin - 1);
                hg_close_begin = begin - 1;
            }
        }
        if (ObjectFind(open_zone_name) == -1) {
            ObjectCreate(open_zone_name, OBJ_TREND, 0, Time[begin], zone_open, Time[end], zone_open);
            ObjectSet(open_zone_name, OBJPROP_COLOR, zone_color);
            ObjectSet(open_zone_name, OBJPROP_COLOR, zone_color);
            ObjectSet(open_zone_name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSet(open_zone_name, OBJPROP_WIDTH, line_width);
            ObjectSet(open_zone_name, OBJPROP_RAY, false);
            ObjectSet(open_zone_name, OBJPROP_BACK, true);
        } else {
            ObjectSet(open_zone_name, OBJPROP_TIME2, Time[end]);
        }
        if (ObjectFind(close_zone_name) == -1) {
            ObjectCreate(close_zone_name, OBJ_TREND, 0, Time[begin], zone_close, Time[end], zone_close);
            ObjectSet(close_zone_name, OBJPROP_COLOR, zone_color);
            ObjectSet(close_zone_name, OBJPROP_COLOR, zone_color);
            ObjectSet(close_zone_name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSet(close_zone_name, OBJPROP_WIDTH, line_width);
            ObjectSet(close_zone_name, OBJPROP_RAY, false);
            ObjectSet(close_zone_name, OBJPROP_BACK, true);
        } else {
            ObjectSet(close_zone_name, OBJPROP_TIME2, Time[end]);
        }

        if (ObjectFind(open_hg_name) == -1 && hg_open > 0.0) {
            ObjectCreate(open_hg_name, OBJ_TREND, 0, Time[hg_open_begin], hg_open, Time[end], hg_open);
            ObjectSet(open_hg_name, OBJPROP_COLOR, zone_hg_color);
            ObjectSet(open_hg_name, OBJPROP_COLOR, zone_hg_color);
            ObjectSet(open_hg_name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSet(open_hg_name, OBJPROP_WIDTH, line_width);
            ObjectSet(open_hg_name, OBJPROP_RAY, false);
            ObjectSet(open_hg_name, OBJPROP_BACK, true);
        } else {
            ObjectSet(open_zone_name, OBJPROP_TIME2, Time[end]);
        }
        if (ObjectFind(close_hg_name) == -1) {
            ObjectCreate(close_hg_name, OBJ_TREND, 0, Time[hg_close_begin], hg_close, Time[end], hg_close);
            ObjectSet(close_hg_name, OBJPROP_COLOR, zone_hg_color);
            ObjectSet(close_hg_name, OBJPROP_COLOR, zone_hg_color);
            ObjectSet(close_hg_name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSet(close_hg_name, OBJPROP_WIDTH, line_width);
            ObjectSet(close_hg_name, OBJPROP_RAY, false);
            ObjectSet(close_hg_name, OBJPROP_BACK, true);
        } else {
            ObjectSet(close_hg_name, OBJPROP_TIME2, Time[end]);
        }
    } else {
        if (ObjectFind(open_zone_name) == 1) {
            ObjectDelete(open_zone_name);
        }
        if (ObjectFind(close_zone_name) == 1) {
            ObjectDelete(close_zone_name);
        }
        if (ObjectFind(open_hg_name) == 1) {
            ObjectDelete(open_hg_name);
        }
        if (ObjectFind(close_hg_name) == 1) {
            ObjectDelete(close_hg_name);
        }
    }
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+
