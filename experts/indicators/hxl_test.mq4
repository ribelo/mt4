//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                  Huxley WRB Body.mq4                                      |
//|                                                                                           |
//+-------------------------------------------------------------------------------------------+
#property copyright "Copyright © 2014 Huxley"
#property link      "email:   huxley.source@gmail.com"
#include <gsl_math.mqh>


//+-------------------------------------------------------------------------------------------+
//| Indicator Global Inputs                                                                   |
//+-------------------------------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 C'245,146,86'
#property indicator_color2 C'126,59,73'
#property indicator_color3 C'252,165,88'
#property indicator_color4 C'177,83,103'
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1

#define  i_name "hxl_wrb"
#define  short_name "Huxley WRB Body"

//Global External Inputs

extern bool  draw_wrb = true;
extern color bull_wrb_body = C'245,146,86';
extern color bear_wrb_body = C'126,59,73';
extern bool  draw_wrb_hg = true;
extern color bull_wrb_hg_body = C'252,165,88';
extern color bear_wrb_hg_body = C'177,83,103';
extern int bar_width = 1;

//Misc
double ohlc[][6];
int pip_mult_tab[]={1,10,1,10,1,10,100,1000};
string symbol;
int tf, digits, multiplier, spread;
double tickvalue, point;
string pip_description = " pips";

double body_wrb_open[], body_wrb_close[], body_wrb_hg_open[], body_wrb_hg_close[];
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
    int r;
    double a = 0.01001 + 0.000001;
    double b = 0.01001 + 0.000002;
    Print("Round Double");
    int begin = GetTickCount();
    for (int i = 0; i < 1000000; i++) {
      r = _roundp(a + b, digits);
    }
    Print("GSL Time: ",GetTickCount() - begin," r: ",r);

    begin = GetTickCount();
    for (i = 0; i < 1000000; i++) {
      r = NormalizeDouble(a + b, digits);
    }
    Print("MT4 Time: ",GetTickCount() - begin," r: ",r);
    Print("Is Identical?: ",_fcmp(_roundp(a + b, digits), NormalizeDouble(a + b, digits)));


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
    return (0);
}
//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+
