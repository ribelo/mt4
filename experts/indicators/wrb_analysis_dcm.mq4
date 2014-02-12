//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                    Huxley DCM.mq4                                      |
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
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 1
#property indicator_buffers 2

#property indicator_color1  C'205,138,108'
#property indicator_color2  C'151,125,130'

#define  i_name "hxl_dcm"
#define  short_name "Huxley DCM"

//Global External Inputs
extern int contraction_size = 64;
extern color bull_color = C'205,138,108';
extern color bear_color = C'151,125,130';
extern int bar_width = 2;
extern bool show_label = true;

//Misc
double candle[][6];
int pip_mult_tab[]={1,10,1,10,1,10,100,1000};
string symbol;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double dcm_bull[], dcm_bear[];

int last_dcm;
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
    SetIndexBuffer(0, dcm_bull);
    SetIndexStyle(0, DRAW_HISTOGRAM, 0, bar_width, bull_color);
    SetIndexLabel(0, "Bull DCM");
    SetIndexBuffer(1, dcm_bear);
    SetIndexStyle(1, DRAW_HISTOGRAM, 0, bar_width, bear_color);
    SetIndexLabel(1, "Bear DCM");

    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                                |
//+-------------------------------------------------------------------------------------------+
int deinit() {
    return (0);
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator iteration function                                                       |
//+-------------------------------------------------------------------------------------------+
int start() {
    int i, dcm, last_dcm;
    if (!_new_bar(symbol, tf)) {
        return (0);
    }
    for(i = iBars(symbol, tf); i >= 4; i--) {
        dcm = _dcm(candle, i, contraction_size, iBars(symbol, tf));
        if(last_dcm == 1) {
            dcm_bull[i] = 1;
        } else if(last_dcm == -1) {
            dcm_bear[i] = 1;
        }
        if(dcm != 0) {
            last_dcm = dcm;
        }
    }
    return (0);
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+

