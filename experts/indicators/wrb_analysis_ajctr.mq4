//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                  Huxley WRB AJCTR.mq4                                     |
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
#property indicator_buffers 4
#property indicator_color1 C'255,213,98'
#property indicator_color2 C'233,65,103'
#property indicator_color3 C'252,165,88'
#property indicator_color4 C'177,83,103'
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1


#define  i_name "hxl_wrb_ajctr"
#define  short_name "Huxley WRB AJCTR"

//Global External Inputs

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
extern string font_name = "Tahoma";
extern int bar_width = 1;

//Misc
double candle[][6];
int pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
string symbol;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double ajctr_body_open[], ajctr_body_close[];
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
    SetIndexBuffer(2, ajctr_body_close);
    SetIndexStyle(2, DRAW_HISTOGRAM, 0, bar_width, ajctr_bull_body);
    SetIndexLabel(2, "WRB AJCTR");
    SetIndexBuffer(3, ajctr_body_open);
    SetIndexStyle(3, DRAW_HISTOGRAM, 0, bar_width, ajctr_bear_body);
    SetIndexLabel(3, "WRB AJCTR");


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
    int i, j, limit, r[4];
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
    limit = Bars - counted_bars;
    for (i = limit; i >= 0; i--) {
        if (hammer == true) {
            if (_hammer(candle, i, Bars, r) != 0) {
                if (r[3] == 1) {
                    ajctr_body_open[r[0]] = Low[r[0]];
                    ajctr_body_close[r[0]] = Close[r[0]];
                } else if (r[3] == -1) {
                    ajctr_body_open[r[0]] = High[r[0]];
                    ajctr_body_close[r[0]] = Close[r[0]];
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(Time[i], TIME_DATE), "_",
                                                 TimeToStr(Time[i], TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "HAM", Time[r[0] + 1], text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "HAM", Time[r[0] + 1], text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (i == 1) {
                        if (r[3] == 1) {
                            SendNotification("ajctr bull hammer at " + TimeToStr(Time[i]));
                        } else if (r[3] == -1) {
                            SendNotification("ajctr bear hammer at " + TimeToStr(Time[i]));
                        }
                    }
                }
                continue;
            }
        }
        if (harami == true) {
            if (_harami(candle, i, Bars, r) != 0) {
                ajctr_body_open[r[0]] = Open[r[0]];
                ajctr_body_close[r[0]] = Close[r[0]];
                for (j = 1; j <= r[1] - r[0]; j++) {
                    ajctr_body_open[r[0] + j] = Open[r[0] + j];
                    ajctr_body_close[r[0] + j] = Close[r[0] + j];
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(Time[i], TIME_DATE), "_",
                                                 TimeToStr(Time[i], TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "HAR", Time[r[0] + 1], text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "HAR", Time[r[0] + 1], text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (i == 1) {
                        if (r[3] == 1) {
                            SendNotification("ajctr bull harami at " + TimeToStr(Time[i]));
                        } else if (r[3] == -1) {
                            SendNotification("ajctr bear harami at " + TimeToStr(Time[i]));
                        }
                    }
                }
                continue;
            }
        }
        if (engulfing == true) {
            if (_engulfing(candle, i, Bars, r) != 0) {
                ajctr_body_open[r[0]] = Open[r[0]];
                ajctr_body_close[r[0]] = Close[r[0]];
                for (j = 1; j <= r[1] - r[0]; j++) {
                    ajctr_body_open[r[0] + j] = Open[r[0] + j];
                    ajctr_body_close[r[0] + j] = Close[r[0] + j];
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(Time[i], TIME_DATE), "_",
                                                 TimeToStr(Time[i], TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "ENG", Time[r[0] + 1], text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "ENG", Time[r[0] + 1], text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (i == 1) {
                        if (r[3] == 1) {
                            SendNotification("ajctr bull engulfing at " + TimeToStr(Time[i]));
                        } else if (r[3] == -1) {
                            SendNotification("ajctr bear engulfing at " + TimeToStr(Time[i]));
                        }
                    }
                }
                continue;
            }
        }
        if (soldiers == true) {
            if (_soldiers(candle, i, Bars, r) != 0) {
                ajctr_body_open[r[0]] = Open[r[0]];
                ajctr_body_close[r[0]] = Close[r[0]];
                ajctr_body_open[r[0] + 1] = Open[r[0] + 1];
                ajctr_body_close[r[0] + 1] = Close[r[0] + 1];
                ajctr_body_open[r[1]] = Open[r[1]];
                ajctr_body_close[r[1]] = Close[r[1]];
                ajctr_body_open[r[1] - 1] = Open[r[1] - 1];
                ajctr_body_close[r[1] - 1] = Close[r[1] - 1];
                for (j = 2; j <= r[1] - r[0] - 2; j++) {
                    contraction_body_open[r[0] + j] = Open[r[0] + j];
                    contraction_body_close[r[0] + j] = Close[r[0] + j];
                }
                if (make_text == true) {
                    time_str = StringConcatenate(TimeToStr(Time[i], TIME_DATE), "_",
                                                 TimeToStr(Time[i], TIME_MINUTES));
                    text_name = StringConcatenate(i_name, "_", time_str);
                    if (r[3] == 1) {
                        text_price = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i)) - ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "SOL", Time[r[0] + 1], text_price, font_size, text_color) ;
                    } else if (r[3] == -1) {
                        text_price = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) + ((iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 3, i)) - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 3, i))) / 2) * label_offset_percent;
                        make_text(text_name, "SOL", Time[r[0] + 1], text_price,  font_size, text_color) ;
                    }
                }
                if (send_notification == true) {
                    if (i == 1) {
                        if (r[3] == 1) {
                            SendNotification("ajctr bull soldiers at " + TimeToStr(Time[i]));
                        } else if (r[3] == -1) {
                            SendNotification("ajctr bear soldiers at " + TimeToStr(Time[i]));
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
