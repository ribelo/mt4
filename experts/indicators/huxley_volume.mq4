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
#property indicator_buffers 8

#property indicator_color1  C'188,182,167'
#property indicator_color2  C'247,121,81'
#property indicator_color3  C'92,62,79'
#property indicator_color4  C'205,138,108'
#property indicator_color5  C'151,125,130'

#property indicator_color6  C'245,146,85'
#property indicator_color7  C'177,83,103'
#property indicator_color8  C'51,37,50'
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  2
#property indicator_width5  2
#property indicator_width6  2
#property indicator_width5  2
#property indicator_width6  2
#property indicator_width7  2
#property indicator_width8  1

#define  _name "hxl_vol."
#define  short_name "Huxley Volume"

//Global External Inputs
extern int look_back = 1024;
extern int refresh_candles = 0;
extern bool auto_average_period = false;
extern int  average_period = 20;
//extern double  climax_factor = 1.5;
extern int  rf_count = 3;
//extern color normal_color = C'188,182,167';
//extern color climax_bull_color = C'245,146,85';
//extern color climax_bear_color = C'177,83,103';
//extern color rising_bull_color = C'247,121,81';
//extern color rising_bear_color = C'92,62,79';
//extern color falling_bull_color = C'205,138,108';
//extern color falling_bear_color = C'151,125,130';
extern color normal_color = C'188,182,167';
extern color climax_bull_color = C'245,146,85';
extern color climax_bear_color = C'177,83,103';
extern color rising_bull_color = C'247,121,81';
extern color rising_bear_color = C'92,62,79';
extern color falling_bull_color = C'205,138,108';
extern color falling_bear_color = C'151,125,130';
extern color moving_average_color = C'56,47,50';
extern color text_color = C'56,47,50';
extern int font_size = 8;
extern string font_name = "Cantarell";
extern int bar_width = 2;
extern bool show_label = true;

//Misc
int pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
string symbol, global_name;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

//Global Buffers & Other Inputs
double bull_climax[], bear_climax[], rising_bull[], rising_bear[], falling_bull[], falling_bear[], normal[];
double average_volume[], average_volume_factor, volume_factor, max_vol, min_vol, max_vr;
double climax_period = 20;
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
    IndicatorShortName(short_name);
    if (auto_average_period) {
        switch (tf) {
        case 1:
            average_period = 60;
            climax_period = 60;
            break;
        case 5:
            average_period = 20;
            climax_period = 20;
            break;
        case 15:
            average_period = 16;
            climax_period = 16;
            break;
        case 30:
            average_period = 48;
            climax_period = 48;
            break;
        case 60:
            average_period = 120;
            climax_period = 24;
            break;
        case 240:
            average_period = 42;
            climax_period = 42;
            break;
        case 1440:
            average_period = 30;
            climax_period = 30;
            break;
        case 10080:
            average_period = 50;
            climax_period = 50;
            break;
        case 43200:
            average_period = 12;
            climax_period = 12;
            break;
        }
    }
    SetIndexBuffer(0, normal);
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, bar_width, normal_color);
    SetIndexLabel(0, "Normal");
    SetIndexBuffer(1, rising_bull);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, rising_bull_color);
    SetIndexLabel(1, "Rising Bull");
    SetIndexBuffer(2, rising_bear);
    SetIndexStyle(2, DRAW_HISTOGRAM, 0, bar_width, rising_bear_color);
    SetIndexLabel(2, "Rising Bear");
    SetIndexBuffer(3, falling_bull);
    SetIndexStyle(3, DRAW_HISTOGRAM, 0, bar_width, falling_bull_color);
    SetIndexLabel(3, "Falling Bull");
    SetIndexBuffer(4, falling_bear);
    SetIndexStyle(4, DRAW_HISTOGRAM, 0, bar_width, falling_bear_color);
    SetIndexLabel(4, "Falling Bear");
    SetIndexBuffer(5, bull_climax);
    SetIndexStyle(5, DRAW_HISTOGRAM, 0, bar_width, climax_bull_color);
    SetIndexLabel(5, "Bull Climax");
    SetIndexBuffer(6, bear_climax);
    SetIndexStyle(6, DRAW_HISTOGRAM, 0, bar_width, climax_bear_color);
    SetIndexLabel(6, "Bear Climax");
    SetIndexBuffer(7, average_volume);
    SetIndexStyle(7, DRAW_LINE, 0, 1, moving_average_color);
    SetIndexLabel(7, "Average of " + average_period + " bars");
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
    int i, j, l, limit, counted_bars;
    counted_bars = IndicatorCounted();
    if(counted_bars > 0) {
        counted_bars--;
    }
    limit = MathMin(iBars(symbol, tf) - counted_bars, look_back);
    for (i = 0; i < limit; i++) {
        bull_climax[i] = 0.0;
        bear_climax[i] = 0.0;
        rising_bull[i] = 0.0;
        rising_bear[i] = 0.0;
        falling_bull[i] = 0.0;
        falling_bear[i] = 0.0;
        normal[i] = 0.0;
        max_vol = 0.0;
        min_vol = 99999.0;
        max_vr = 0.0;
        average_volume[i] = sine_wma(Volume, average_period, i);
        volume_factor = Volume[i] * (High[i] * Low[i]);
        //for ( int y = i; y < i + average_period; y++ ) {
        //average_volume_factor += ( average_volume[y] * ( High[y] * Low[y] ) ) ;
        //}
        for (j = 1; j <= rf_count; j++) {
            max_vol = MathMax(max_vol, Volume[i + j]);
            min_vol = MathMin(min_vol, Volume[i + j]);
        }
        for (l = 1; l <= climax_period; l++) {
            //max_vr = MathMax(max_vr, Volume[i+l] * ( High[i+l] * Low[i+l] ) );
            max_vr = MathMax(max_vr, Volume[i + l]);
        }
        //average_volume_factor /= average_period;
        if (Close[i] > Open[i]) {
            if (Volume[i] >= max_vr) {   //climax_factor * average_volume_factor && Volume[i] > 0.9 * climax_factor * average_volume[i] ) {
                bull_climax[i] = Volume[i];
            } else if (Volume[i] >= max_vol) {
                rising_bull[i] = Volume[i];
            } else if (Volume[i] <= min_vol) {
                falling_bull[i] = Volume[i];
            } else {
                normal[i] = Volume[i];
            }
        } else if (Close[i] < Open[i]) {
            if (Volume[i] >= max_vr) {   //climax_factor * average_volume_factor && Volume[i] > 0.9 * climax_factor * average_volume[i] ) {
                bear_climax[i] = Volume[i];
            } else if (Volume[i] >= max_vol) {
                rising_bear[i] = Volume[i];
            } else if (Volume[i] <= min_vol) {
                falling_bear[i] = Volume[i];
            } else {
                normal[i] = Volume[i];
            }
        } else if (Close[i] == Open[i]) {
            if (body_dir(i) == 1) {
                if (Volume[i] >= max_vr) {   //climax_factor * average_volume_factor && Volume[i] > 0.9 * climax_factor * average_volume[i] ) {
                    bull_climax[i] = Volume[i];
                } else if (Volume[i] >= max_vol) {
                    rising_bull[i] = Volume[i];
                } else if (Volume[i] <= min_vol) {
                    falling_bull[i] = Volume[i];
                } else {
                    normal[i] = Volume[i];
                }
            }
            if (body_dir(i) == 0) {
                if (Volume[i] >= max_vr) {   //climax_factor * average_volume_factor && Volume[i] > 0.9 * climax_factor * average_volume[i] ) {
                    bear_climax[i] = Volume[i];
                } else if (Volume[i] >= max_vol) {
                    rising_bear[i] = Volume[i];
                } else if (Volume[i] <= min_vol) {
                    falling_bear[i] = Volume[i];
                } else {
                    normal[i] = Volume[i];
                }
            }
        }
    }
    if (show_label) {
        int window = WindowFind(short_name);
        double average_percent = Volume[0] * 100 / average_volume[0];
        string label_message = StringConcatenate("Average Volume: ", NormalizeDouble(average_volume[0], 0));
        make_label(_name + "average_volume", label_message, font_size, text_color, 1, 10, 10, window, font_name);
        label_message = StringConcatenate("Current Volume: ", NormalizeDouble(average_percent, 0), "%");
        make_label(_name + "current_volume", label_message, font_size, text_color, 1, 10, 25, window, font_name);
        label_message = StringConcatenate("Volume Proportion: ", volume_proportion());
        make_label(_name + "volume_proportion", label_message, font_size, text_color, 1, 10, 40, window, font_name);
    }
    return (0);
}

int body_dir(int i) {
    if (High[i] - MathMax(Close[i], Open[i]) >  MathMax(Close[i], Open[i]) - Low[i]) {
        return (0);
    } else if (MathMin(Close[i], Open[i]) - Low[i] > High[i] - MathMin(Close[i], Open[i])) {
        return (1);
    } else if (Close[i] > Open[i]) {
        return (1);
    } else if (Close[i] < Open[i]) {
        return (0);
    }
}

double volume_proportion() {
    int bear_count, bull_count;
    double bear_volume, bull_volume, proportion;

    for (int z = 1; z <= average_period; z++) {
        if (Close[z] > Open[z]) {
            bear_count++;
            bear_volume += Volume[z];
        }
        if (Close[z] < Open[z]) {
            bull_count++;
            bull_volume += Volume[z];
        }
    }
    proportion = (bull_volume / bull_count) / (bear_volume / bear_count);
    return (proportion);
}

double sine_wma(double array[], int per, int bar) {
    double pi = 3.1415926535;
    double Sum = 0;
    double Weight = 0;
    for (int i = 0; i < per - 1; i++) {
        Weight += MathSin(pi * (i + 1) / (per + 1));
        Sum += array[bar + i] * MathSin(pi * (i + 1) / (per + 1));
    }
    if (Weight > 0) {
        double swma = Sum / Weight;
    } else {
        swma = 0;
    }
    return (swma);
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+

