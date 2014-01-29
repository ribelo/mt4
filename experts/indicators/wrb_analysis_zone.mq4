//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                  Huxley WRB Zone.mq4                                      |
//|                                                                                           |
//+-------------------------------------------------------------------------------------------+
#property copyright "Copyright © 2014 Huxley"
#property link      "email:   huxley.source@gmail.com"
#include <wrb_analysis.mqh>
#include <hxl_utils.mqh>


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


#define  i_name "hxl_wrb_zone"
#define  short_name "Huxley WRB Zone"

//Global External Inputs

extern int look_back = 1024;
extern bool swing_point_1 = true;
extern bool swing_point_2 = true;
extern bool swing_point_3 = true;
extern bool strong_continuation_1 = true;
extern bool strong_continuation_2 = true;
extern bool strong_continuation_3 = false;
extern bool strong_continuation_4 = false;
extern bool reaction_zone = true;
extern int contraction_size = 64;
extern color zone_bull_body = C'252,165,88';
extern color zone_bear_body = C'177,83,103';
extern color contraction_bull_body = C'205,138,108';
extern color contraction_bear_body = C'151,125,130';
extern color text_color = C'56,47,50';
extern color line_color = C'111,116,125';
extern bool make_text = false;
extern bool draw_zone = true;
extern bool send_notification = false;
extern int label_offset_percent = 1;
extern int font_size = 8;
extern string font_name = "Tahoma";
extern int bar_width = 1;
extern int line_width = 1;

//Misc
double candle[][6];
int pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
string symbol;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double v1_body_open[], v1_body_close[], v2_body_open[], v2_body_close[];
double contraction_body_open[], contraction_body_close[];
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

    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                                |
//+-------------------------------------------------------------------------------------------+
int deinit() {
    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
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
    int i, j, limit, r[4];
    double text_price;
    string text_name, time_str;
    if (!_new_bar(symbol, tf)) {
        return (0);
    }
    limit = MathMin(iBars(symbol, tf), look_back);
    for (i = limit; i > 0; i--) {
        v1_body_open[i] = 0.0;
        v1_body_close[i] = 0.0;
        v2_body_open[i] = 0.0;
        v2_body_close[i] = 0.0;
        contraction_body_open[i] = 0.0;
        contraction_body_close[i] = 0.0;
        if (swing_point_1 == true) {
            if (_swing_point_1(candle, i, iBars(symbol, tf),
                               contraction_size, r) != 0) {
                v1_body_open[r[0]] = Open[r[0]];
                v1_body_close[r[0]] = Close[r[0]];
                v2_body_open[r[1]] = Open[r[1]];
                v2_body_close[r[1]] = Close[r[1]];
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = Open[r[0] + j];
                    contraction_body_close[r[0] + j] = Close[r[0] + j];
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(Time[i], TIME_DATE), "_",
                                                 TimeToStr(Time[i], TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_sp1_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SP1", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (i == 1) {
                        if (r[3] == 1) {
                            SendNotification("zone bull sp1 at " + TimeToStr(Time[i]));
                        } else if (r[3] == -1) {
                            SendNotification("zone bear sp1 at " + TimeToStr(Time[i]));
                        }
                    }
                }
                continue;
            }
        }
        if (swing_point_2 == true) {
            if (_swing_point_2(candle, i, iBars(symbol, tf),
                               contraction_size, r) != 0) {
                v1_body_open[r[0]] = Open[r[0]];
                v1_body_close[r[0]] = Close[r[0]];
                v2_body_open[r[1]] = Open[r[1]];
                v2_body_close[r[1]] = Close[r[1]];
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = Open[r[0] + j];
                    contraction_body_close[r[0] + j] = Close[r[0] + j];
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(Time[i], TIME_DATE), "_",
                                                 TimeToStr(Time[i], TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_sp2_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SP2", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (i == 1) {
                        if (r[3] == 1) {
                            SendNotification("zone bull sp2 at " + TimeToStr(Time[i]));
                        } else if (r[3] == -1) {
                            SendNotification("zone bear sp2 at " + TimeToStr(Time[i]));
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
                    v1_body_close[r[0]] = MathMin(Close[r[0]], Open[r[0]]);
                } else if (r[3] == -1) {
                    v1_body_open[r[0]] = High[r[0]];
                    v1_body_close[r[0]] = MathMax(Close[r[0]], Open[r[0]]);
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(Time[i], TIME_DATE), "_",
                                                 TimeToStr(Time[i], TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_sp3_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, r[0]) - ((iHigh(symbol, tf, r[0]) - iLow(symbol, tf, r[0])) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, r[0]) + ((iHigh(symbol, tf, r[0]) - iLow(symbol, tf, r[0])) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SP3", Time[r[0]], text_price, font_size, text_color);
                }
                if (send_notification == true) {
                    if (i == 1) {
                        if (r[3] == 1) {
                            SendNotification("zone bull sp3 at " + TimeToStr(Time[i]));
                        } else if (r[3] == -1) {
                            SendNotification("zone bear sp3 at " + TimeToStr(Time[i]));
                        }
                    }
                }
                continue;
            }
        }
        if (strong_continuation_1 == true) {
            if (_strong_continuation_1(candle, i, iBars(symbol, tf),
                                       contraction_size, r) != 0) {
                v1_body_open[r[0]] = Open[r[0]];
                v1_body_close[r[0]] = Close[r[0]];
                v2_body_open[r[1]] = Open[r[1]];
                v2_body_close[r[1]] = Close[r[1]];
                int start = MathRound(MathMin(r[0], r[1]));
                for (j = 1; j < MathAbs(r[1] - r[0]); j++) {
                    contraction_body_open[start + j] = Open[start + j];
                    contraction_body_close[start + j] = Close[start + j];
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(Time[i], TIME_DATE), "_",
                                                 TimeToStr(Time[i], TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_sc1_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SC1", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (i == 1) {
                        if (r[3] == 1) {
                            SendNotification("zone bull sc1 at " + TimeToStr(Time[i]));
                        } else if (r[3] == -1) {
                            SendNotification("zone bear sc1 at " + TimeToStr(Time[i]));
                        }
                    }
                }
                continue;
            }
        }
        if (strong_continuation_2 == true) {
            if (_strong_continuation_2(candle, i, iBars(symbol, tf),
                                       contraction_size, r) != 0) {
                v1_body_open[r[0]] = Open[r[0]];
                v1_body_close[r[0]] = Close[r[0]];
                v2_body_open[r[1]] = Open[r[1]];
                v2_body_close[r[1]] = Close[r[1]];
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = Open[r[0] + j];
                    contraction_body_close[r[0] + j] = Close[r[0] + j];
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(Time[i], TIME_DATE), "_",
                                                 TimeToStr(Time[i], TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_sc2_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SC2", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (i == 1) {
                        if (r[3] == 1) {
                            SendNotification("zone bull sc2 at " + TimeToStr(Time[i]));
                        } else if (r[3] == -1) {
                            SendNotification("zone bear sc2 at " + TimeToStr(Time[i]));
                        }
                    }
                }
                continue;
            }
        }
        if (strong_continuation_3 == true) {
            if (_strong_continuation_3(candle, i, iBars(symbol, tf),
                                       contraction_size, r) != 0) {
                v1_body_open[r[0]] = Open[r[0]];
                v1_body_close[r[0]] = Close[r[0]];
                v2_body_open[r[1]] = Open[r[1]];
                v2_body_close[r[1]] = Close[r[1]];
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = Open[r[0] + j];
                    contraction_body_close[r[0] + j] = Close[r[0] + j];
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(Time[i], TIME_DATE), "_",
                                                 TimeToStr(Time[i], TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_sc3_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SC3", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (i == 1) {
                        if (r[3] == 1) {
                            SendNotification("zone bull sc3 at " + TimeToStr(Time[i]));
                        } else if (r[3] == -1) {
                            SendNotification("zone bear sc3 at " + TimeToStr(Time[i]));
                        }
                    }
                }
                continue;
            }
        }
        if (strong_continuation_4 == true) {
            if (_strong_continuation_4(candle, i, iBars(symbol, tf),
                                       contraction_size, r) != 0) {
                v1_body_open[r[0]] = Open[r[0]];
                v1_body_close[r[0]] = Close[r[0]];
                v2_body_open[r[1]] = Open[r[1]];
                v2_body_close[r[1]] = Close[r[1]];
                for (j = 1; j < r[1] - r[0]; j++) {
                    contraction_body_open[r[0] + j] = Open[r[0] + j];
                    contraction_body_close[r[0] + j] = Close[r[0] + j];
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(Time[i], TIME_DATE), "_",
                                                 TimeToStr(Time[i], TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_sc4_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "SC4", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (i == 1) {
                        if (r[3] == 1) {
                            SendNotification("zone bull sc4 at " + TimeToStr(Time[i]));
                        } else if (r[3] == -1) {
                            SendNotification("zone bear sc4 at " + TimeToStr(Time[i]));
                        }
                    }
                }
                continue;
            }
        }
        if (reaction_zone == true) {
            if (_reaction_zone(candle, i, iBars(symbol, tf),
                               contraction_size, r) != 0) {
                v1_body_open[r[0]] = Open[r[0]];
                v1_body_close[r[0]] = Close[r[0]];
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(Time[i], TIME_DATE), "_",
                                                 TimeToStr(Time[i], TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, r[1] - r[0], i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, r[1] - r[0], i))) / 2) * label_offset_percent;
                    }
                    make_text(text_name, "RZ", Time[r[0] + 1], text_price,  font_size, text_color);
                }
                if (send_notification == true) {
                    if (i == 1) {
                        if (r[3] == 1) {
                            SendNotification("zone bull rz at " + TimeToStr(Time[i]));
                        } else if (r[3] == -1) {
                            SendNotification("zone bear rz at " + TimeToStr(Time[i]));
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
                draw_zone(i, end_bar, zone_open[i], zone_close[i]);
            } else if (zone_close[i] < zone_open[i]) {
                for (j = i - 1; j >=0; j--) {
                    if (iHigh(symbol, tf, j) >= zone_open[i]) {
                        end_bar = j;
                        break;
                    }
                }
                draw_zone(i, end_bar, zone_open[i], zone_close[i]);
            }
        }
    }
}


void draw_zone(int begin, int end, double open, double close) {
    string time_str = StringConcatenate(TimeToStr(Time[begin], TIME_DATE), "_",
                                        TimeToStr(Time[begin], TIME_MINUTES));
    string open_line_name = StringConcatenate(i_name, "_open_line_", time_str);
    string close_line_name = StringConcatenate(i_name, "_close_line_", time_str);

    if (begin - end > 12 && begin - end < 512) {
        if (ObjectFind(open_line_name) == -1) {
            ObjectCreate(open_line_name, OBJ_TREND, 0, Time[begin], open, Time[end], open);
            ObjectSet(open_line_name, OBJPROP_COLOR, line_color);
            ObjectSet(open_line_name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSet(open_line_name, OBJPROP_WIDTH, line_width);
            ObjectSet(open_line_name, OBJPROP_RAY, false);
            ObjectSet(open_line_name, OBJPROP_BACK, true);
        } else {
            ObjectSet(open_line_name, OBJPROP_TIME2, Time[end]);
        }
        if (ObjectFind(close_line_name) == -1) {
            ObjectCreate(close_line_name, OBJ_TREND, 0, Time[begin], close, Time[end], close);
            ObjectSet(close_line_name, OBJPROP_COLOR, line_color);
            ObjectSet(close_line_name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSet(close_line_name, OBJPROP_WIDTH, line_width);
            ObjectSet(close_line_name, OBJPROP_RAY, false);
            ObjectSet(close_line_name, OBJPROP_BACK, true);
        } else {
            ObjectSet(close_line_name, OBJPROP_TIME2, Time[end]);
        }
    } else {
        if (ObjectFind(open_line_name) == 1) {
            ObjectDelete(open_line_name);
        }
        if (ObjectFind(close_line_name) == 1) {
            ObjectDelete(close_line_name);
        }
    }
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+
