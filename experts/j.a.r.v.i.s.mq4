//+-------------------------------------------------------------------+
//|                  Just A Rather Very Intelligent System by Huxley  |
//|                                         Copyright © 2013, Huxley  |
//+-------------------------------------------------------------------+
#property copyright "Copyright © 2014, Huxley"
#include <wrb_analysis.mqh>
#include <gsl_math.mqh>
#include <LibGMT.mqh>
#include <LibOrderReliable4.mqh>


extern string  gen = "----general inputs----";
extern bool    use_sd = true;
extern bool    use_sas = true;
extern int     timer_interval = 250;

extern double  max_dd = 0.3;
extern double  max_risk = 0.05;
extern int     slippage = 3;

extern int     magic_number = 0;
extern string  trade_comment = "";
extern bool    criminal_is_ecn = true;
extern double  max_spreed = 5;
extern int     hidden_pips = 3;
extern double  buffer_size = 1.0;
extern double  pending_pips = 5;

extern string  tmm = "----Trade management module----";
extern bool    use_trailing_stop = true;

extern string  amc = "----Available Margin checks----";
extern bool    use_margin_check = true;
extern int     minimum_margin_percen = 1500;

extern string  cls = "----Misc----";
extern color   supply_color = C'177,83,103';
extern color   demand_color = C'251,167,71';
extern color   pointless_color = White;
extern int     fibo_width = 1;
extern bool    show_info = true;

extern string  lab = "----Label---";
extern bool    use_label_box = true;
extern bool    show_statistic = true;
extern color   label_box = C'188,182,167';
//extern color   label_border = Black;
extern color   text_color = C'100,77,82';
extern string  font_type = "Verdana";
extern int     font_size = 8;
extern int     data_disp_offset = 14;
extern int     data_disp_gap_size = 30;

extern int     info_text_size = 10;


//Margin variables
bool           enough_margin;
string         margin_message;
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Calculate result variables
double         entry_risk_reward = 1;
double         piramide_risk_reward = 1;
double         entry_cash_profit, entry_pips_profit, entry_average_profit, entry_pips_loss, entry_average_loss, day_cash_profit, day_pip_profit;
double         piramide_cash_profit, piramide_pips_profit, piramide_average_profit, piramide_pips_loss, piramide_average_loss;
int            entry_win_trades, piramide_win_trades, today_win_trades, entry_loss_trades, piramide_loss_trades, today_loss_trades;

//Piramide varbiales
int            first_atr_timeframe, first_atr_period, next_atr_timeframe, next_atr_period, entry, magic_piramide;

//Auto tf wariables
int            up_tf, dn_tf;
double         upper_fractal, bottom_fractal;

//Trading variables
int            open_trades, last_order;
bool           buy_open, sell_open;
int            retry_count = 10;//Will make this number of attempts to get around the trade context busy error.
int            first_order = 0;
double         orders[][5]; //first array is order number array, second array =
//0 - ticket_no
//1 - entry_price
//2 - sl
//3 - tp
//4 - lot
double         first_order_distance, next_order_distance;
//Misc
int            pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
string         symbol;
int            tf, digits, multiplier, spread;
double         tickvalue, point;
string         pip_description = " pips";
bool           force_trade_closure;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
    //----
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
    max_stop *= multiplier;
    max_spreed *= multiplier;
    slippage *= multiplier;
    hidden_pips *= multiplier;
    pending_pips *= multiplier;
    entry = magic_number;
    magic_piramide = magic_number + 100;
    if (trade_comment == "") {
        trade_comment = " ";
    }
    if (criminal_is_ecn) {
        O_R_Config_use2step(true);
    }
    GetFibo();
    CalculateResult();
    DisplayUserFeedback();
    if (!IsTesting()) {
        timer();
    }
    //----
    return (0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
    //----
    Comment("");
    string prefix = sd;
    if (ObjectsTotal() > 0) {
        for (int i = ObjectsTotal() - 1; i >= 0; i--) {
            string name = ObjectName(i);
            if (StringSubstr(name, 0, 4) == prefix || StringSubstr(name, 1, 4) == prefix) {
                ObjectDelete(name);
            }
        }
    }
    //----
    return (0);
}


void timer() {
    while (true) {
        Sleep(timer_interval);
        if (IsStopped() || !IsExpertEnabled()) {
            return;
        }
        RefreshRates();
        start();
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////
//TRADE MANAGEMENT MODULE

void DragDropLine() {
    double old_stop, new_stop, old_take, new_take;
    for (int i = open_trades - 1; i >= 0; i--) {
        int ticket = orders[i][0];
        if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            if (OrderSymbol() == symbol) {
                if (OrderMagicNumber() == magic_number) {
                    old_stop = _roundp(OrderStopLoss(), digits);
                    old_take = _roundp(OrderTakeProfit(), digits);
                    if (OrderType() == OP_BUY) {
                        if (ObjectFind(ticket + sl_line_name) != -1) {
                            new_stop = _roundp(ObjectGet(ticket + sl_line_name, OBJPROP_PRICE1) + hidden_pips * point, digits);
                            if (_fcmp(old_stop, new_stop) != 0) {
                                Print("Order " + ticket + " sl trigger has been moved so i move sl line");
                                OrderModifyReliable(ticket, OrderOpenPrice(), new_stop, OrderTakeProfit(), 0, CLR_NONE);
                            }
                        } else {
                            Print("Order " + ticket + " sl does not exist, so I create a new one");
                            DrawHiddenStopLoss(ticket, old_stop + hidden_pips * point);
                        }
                        if (ObjectFind(ticket + tp_line_name) != -1) {
                            new_take = _roundp(ObjectGet(ticket + tp_line_name, OBJPROP_PRICE1) - hidden_pips * point, digits);
                            if (_fcmp(old_take, new_take) != 0) {
                                Print("Order " + ticket + " tp trigger has been moved so i move tp line");
                            }
                            OrderModifyReliable(ticket, OrderOpenPrice(), OrderStopLoss(), new_take, 0, CLR_NONE);
                        }
                    } else {
                        Print("Order " + ticket + " tp does not exist, so I create a new one");
                        DrawHiddenTakeProfit(ticket, old_take - hidden_pips * Point);
                    }
                } else if (OrderType() == OP_SELL) {
                    if (ObjectFind(ticket + sl_line_name) != -1) {
                        new_stop = _roundp(ObjectGet(ticket + sl_line_name, OBJPROP_PRICE1) - hidden_pips * point, digits);
                        if (_fcmp(old_stop, new_stop) != 0) {
                            Print("Order " + ticket + " sl trigger has been moved so i move sl line");
                            OrderModifyReliable(ticket, OrderOpenPrice(), new_stop, OrderTakeProfit(), 0, CLR_NONE);
                        }
                    } else {
                        Print("Order " + ticket + " sl does not exist, so I create a new one");
                        DrawHiddenStopLoss(ticket, old_stop - hidden_pips * point);
                    }
                    if (ObjectFind(ticket + tp_line_name) != -1) {
                        new_take = _roundp(ObjectGet(ticket + tp_line_name, OBJPROP_PRICE1) + hidden_pips * point, digits);
                        if (_fcmp(old_take, new_take) != 0) {
                            Print("Order " + ticket + " tp trigger has been moved so i move tp line");
                        }
                        OrderModifyReliable(ticket, OrderOpenPrice(), OrderStopLoss(), new_take, 0, CLR_NONE);
                    }
                } else {
                    Print("Order " + ticket + " tp does not exist, so I create a new one");
                    DrawHiddenTakeProfit(ticket, old_take + hidden_pips * Point);
                }
            }
        }
    }
}
}
}

void TrailingStop() {

}

//END TRADE MANAGEMENT MODULE
////////////////////////////////////////////////////////////////////////////////////////////////

bool IsTradingAllowed() {
    if (MarketInfo(symbol, MODE_SPREAD) > max_spreed) {
        return (false);
    }
    return (true);
}

double CalculateDynamicDeltaSwansonLot(double open_price, double stop_price) {
    int local_multiplier;
    int orders_history_total = OrdersHistoryTotal()
    double dd, loss_pip, stop_pip;
    double min_lot_size = MarketInfo(symbol, MODE_MINLOT);
    double high_eq, curr_balance;
    double account_balance[];

    stop_pip = _roundp(_abs(open_price - stop_price) / point, digits);

    if (orders_history_total > 0) {
        int count = _imax(orders_history_total, 5);
        ArrayResize(account_balance, orders_history_total);
        double curr_balance;
        for (int cc = 0; cc < orders_history_total; cc++) {
            if (OrderSelect(cc, SELECT_BY_POS, MODE_HISTORY)) {
                curr_balance += OrderProfit();
                account_balance[cc] = curr_balance;
            }
        }
        ArraySetAsSeries(account_balance, true);
        for (cc = 0; cc < count; cc++) {
            high_eq = MathMax(high_eq, account_balance[cc]);
        }
        for (cc = orders_history_total - count; cc < orders_history_total; cc++) {
            if (OrderSelect(cc, SELECT_BY_POS, MODE_HISTORY)) {
                if (OrderType() == 6 || OrderType() == 7) {
                    count++;
                    continue;
                }
                if (OrderProfit() < 0) {
                    dd += MathAbs(OrderOpenPrice() - OrderClosePrice()) / MarketInfo(OrderSymbol(), MODE_POINT) / local_multiplier;
                }
            }
        }
    } else {
        curr_balance = AccountBalance();
        high_eq = AccountBalance();
    }
    double average_risk_reward = CalculateResult();
    if (dd > stop_pip) {
        double delta = dd / 5;
    } else {
        delta = stop_pip / 5;
    }
    if (delta > 0) {
        double step1 = max_dd * curr_balance / delta / 100;
        double step2 = MathMax((curr_balance - high_eq) / delta / 100, 0);
        double step3 = MathMax((high_eq - curr_balance) / (average_risk_reward * delta) / 100, 0);
        double lot_size1 = (max_dd * curr_balance / delta / 100 + MathMax((curr_balance - high_eq) / delta / 100, 0) - MathMax((high_eq - curr_balance) / (average_risk_reward * delta) / 100, 0));
        double lot_size2 = MathMin(curr_balance / 1000, curr_balance * max_risk / stop_pip / 10);
        double lot_size3 = leverage * curr_balance / (400000 + (20 * stop_pip * leverage));
        double lot_size = MathMin(MathMax(max_dd * curr_balance / delta / 100 + MathMax((curr_balance - high_eq) / delta / 100, 0) - MathMax((high_eq - curr_balance) / (average_risk_reward * delta) / 100, 0) , min_lot_size), MathMin(curr_balance / 1000, curr_balance * max_risk / stop_pip / 10));
        lot_size = MathMin(lot_size - 0.005, leverage * curr_balance / (400000 + (20 * stop_pip * leverage)));
        lot_size /= tick_value;
    }
    //Print("delta ",delta);
    //Print("curr_balance ",curr_balance," max_eq ",high_eq);
    //Print("step ",step1,"   ",step2,"   ",step3);
    //Print("lot ",lot_size1,"   ",lot_size2,"   ",lot_size3);
    //Print("lot_size ",lot_size);
    return (lot_size);
}

void GetFibo() {
    static datetime new_bar1, new_bar2;
    static double fibo_var[][4];
    double entry_price, stop_price, label_price, temp_pending_pips, temp_break_even;
    datetime start_time, end_time, label_time;
    string label_name, text_color, zone_size, lot_val, move_val, profit_margin;
    bool draw_info;
    if (ObjectsTotal() == 0) {
        return;
    } else {
        if (ObjectsTotal(OBJ_FIBO) > 0) {
            ArrayResize(fibo_var, ObjectsTotal(OBJ_FIBO));
            for (int i = ObjectsTotal() - 1; i >= 0; i--) {
                string name = ObjectName(i);
                if (ObjectType(name) == OBJ_FIBO) {
                    if (ObjectGet(name, OBJPROP_COLOR) != pointless_color) {
                        entry_price = _roundp(ObjectGet(name, OBJPROP_PRICE1), digits);
                        stop_price = _roundp(ObjectGet(name, OBJPROP_PRICE2), digits);
                        start_time = ObjectGet(name, OBJPROP_TIME1);
                        end_time = ObjectGet(name, OBJPROP_TIME2);
                        draw_info = false;
                        if (MathAbs(entry_price - stop_price) > max_stop * Point && max_stop != 0) {
                            Print("Zone > max_stop");
                            return;
                        }
                        if (fibo_var[i][0] != entry_price || fibo_var[i][1] != stop_price || fibo_var[i][2] != start_time) {
                            draw_info = true;
                            fibo_var[i][0] = entry_price;
                            fibo_var[i][1] = stop_price;
                            fibo_var[i][2] = start_time;
                            fibo_var[i][3] = end_time;
                        }
                        if (entry_price > stop_price) {
                            if (pending_pips_rr == 0) {
                                temp_pending_pips = pending_pips * Point;
                            } else {
                                temp_pending_pips = (entry_price - stop_price);
                                temp_pending_pips *= pending_pips_rr;
                            }
                            if (ObjectGet(name, OBJPROP_COLOR) != demand_color) {
                                ObjectSet(name, OBJPROP_COLOR, demand_color);
                            }
                            if (ObjectGet(name, OBJPROP_LEVELCOLOR) != demand_color) {
                                ObjectSet(name, OBJPROP_LEVELCOLOR, demand_color);
                            }
                            if (ObjectGet(name, OBJPROP_LEVELWIDTH) != fibo_width) {
                                ObjectSet(name, OBJPROP_LEVELWIDTH, fibo_width);
                            }
                            if (ObjectGet(name, OBJPROP_FIBOLEVELS) != 3) {
                                ObjectSet(name, OBJPROP_FIBOLEVELS, 3);
                            }
                            if (ObjectGetFiboDescription(name, 0) != "Sl = %$") {
                                ObjectSetFiboDescription(name, 0, "Sl = %$");
                            }
                            if (ObjectGetFiboDescription(name, 1) != "Entry = %$") {
                                ObjectSetFiboDescription(name, 1, "Entry = %$");
                            }
                            if (ObjectGetFiboDescription(name, 2) != "TP = %$") {
                                ObjectSetFiboDescription(name, 2, "TP = %$");
                            }
                            if (show_info) {
                                label_time = Time[0];
                                if (draw_info) {
                                    label_name = StringConcatenate(name, ".label");
                                    text_color = "demand";
                                    label_price = stop_price - (entry_price - stop_price) * 0.25;
                                    zone_size = DoubleToStr(MathAbs(entry_price - stop_price) / Point / multiplier, 0);
                                    text_color = StringConcatenate(text_color, " | zone_size: ", zone_size, "pips");
                                    if (ObjectFind(label_name) == -1) {
                                        ObjectCreate(label_name, OBJ_TEXT, 0, label_time, label_price);
                                    }
                                    ObjectSetText(label_name, text_color, info_text_size, "Verdana Bold", demand_color);
                                    ObjectSet(label_name, OBJPROP_PRICE1, label_price);
                                    ObjectSet(label_name, OBJPROP_TIME1, label_time);
                                }
                            }
                        }
                        if (entry_price < stop_price) {
                            if (pending_pips_rr == 0) {
                                temp_pending_pips = pending_pips * Point;
                            } else {
                                temp_pending_pips = (stop_price - entry_price);
                                temp_pending_pips *= pending_pips_rr;
                            }
                            if (ObjectGet(name, OBJPROP_COLOR) != supply_color) {
                                ObjectSet(name, OBJPROP_COLOR, supply_color);
                            }
                            if (ObjectGet(name, OBJPROP_LEVELCOLOR) != supply_color) {
                                ObjectSet(name, OBJPROP_LEVELCOLOR, supply_color);
                            }
                            if (ObjectGet(name, OBJPROP_LEVELWIDTH) != fibo_width) {
                                ObjectSet(name, OBJPROP_LEVELWIDTH, fibo_width);
                            }
                            if (ObjectGet(name, OBJPROP_FIBOLEVELS) != 3) {
                                ObjectSet(name, OBJPROP_FIBOLEVELS, 3);
                            }
                            if (ObjectGetFiboDescription(name, 0) != "Sl = %$") {
                                ObjectSetFiboDescription(name, 0, "Sl = %$");
                            }
                            if (ObjectGetFiboDescription(name, 1) != "Entry = %$") {
                                ObjectSetFiboDescription(name, 1, "Entry = %$");
                            }
                            if (ObjectGetFiboDescription(name, 2) != "TP = %$") {
                                ObjectSetFiboDescription(name, 2, "TP = %$");
                            }
                            if (show_info) {
                                label_time = Time[0];
                                if (draw_info) {
                                    label_name = StringConcatenate(name, ".label");
                                    text_color = "supply";
                                    label_price = stop_price - (entry_price - stop_price) * 0.5;
                                    zone_size = DoubleToStr(MathAbs(entry_price - stop_price) / Point / multiplier, 0);
                                    text_color = StringConcatenate(text_color, " | zone_size: ", zone_size, "pips");
                                    if (ObjectFind(label_name) == -1) {
                                        ObjectCreate(label_name, OBJ_TEXT, 0, label_time, label_price);
                                    }
                                    ObjectSetText(label_name, text_color, info_text_size, "Verdana Bold", supply_color);
                                    ObjectSet(label_name, OBJPROP_PRICE1, label_price);
                                    ObjectSet(label_name, OBJPROP_TIME1, label_time);
                                }
                            }
                        }
                    }
                }
            }
        }
        if (ObjectsTotal(OBJ_TEXT) > 0) {
            for (int y = ObjectsTotal() - 1; y >= 0; y--) {
                name = ObjectName(y);
                if (ObjectType(name) == OBJ_TEXT) {
                    int name_len = StringLen(name);
                    //int label_len = StringLen(".label");
                    string short_name = StringSubstr(name, 0, name_len - 6);
                    if (StringSubstr(name, 0, 4) == "Fibo") {
                        if (ObjectFind(short_name) == -1) {
                            if (ObjectDelete(name)) {
                                y++;
                            }
                        } else if (ObjectGet(short_name, OBJPROP_COLOR) == pointless_color) {
                            if (ObjectDelete(name)) {
                                y++;
                            }
                        }
                    }
                }
            }
        }
    }
}

double GetSupply(int type) {
    static double supply_var[][5], sl_price, tp_price;
    string supply_name;
    double temp_pending_pips;
    if (type == go_short) {
        ArrayResize(supply_var, ObjectsTotal());
        if (ObjectsTotal(OBJ_FIBO) > 0) {
            for (int i = ObjectsTotal() - 1; i >= 0; i--) {
                supply_name = ObjectName(i);
                if (ObjectType(supply_name) == OBJ_FIBO) {
                    if (ObjectGet(supply_name, OBJPROP_COLOR) == supply_color) {
                        supply_var[i][0] = ObjectGet(supply_name, OBJPROP_PRICE1);
                        supply_var[i][1] = ObjectGet(supply_name, OBJPROP_PRICE2);
                        supply_var[i][2] = ObjectGet(supply_name, OBJPROP_FIRSTLEVEL + 2);
                        if (supply_var[i][3] != supply_var[i][1] - supply_var[i][0]) {
                            supply_var[i][3] = supply_var[i][1] - supply_var[i][0];
                            supply_var[i][4] = 0;
                        }
                        if (pending_pips_rr == 0) {
                            temp_pending_pips = pending_pips * Point;
                        } else {
                            temp_pending_pips = supply_var[i][3] * pending_pips_rr;
                        }
                        if (supply_var[i][0] != 0 && supply_var[i][1] != 0 && supply_var[i][2] != 0 && supply_var[i][3] != 0) {
                            if (Bid >= supply_var[i][0] && Ask <= supply_var[i][1] && supply_var[i][4] == 0) {
                                supply_var[i][4] = 1;
                            }
                            if (supply_var[i][4] == 1) {
                                if (Bid >= _roundp(supply_var[i][1] + supply_var[i][3] * buffer_size , digits)) {
                                    ObjectSet(supply_name, OBJPROP_COLOR, pointless_color);
                                    ObjectSet(supply_name, OBJPROP_LEVELCOLOR, pointless_color);
                                    ObjectSet(supply_name, OBJPROP_LEVELWIDTH, 2);
                                    ObjectSet(supply_name, OBJPROP_FIBOLEVELS, 2);
                                    supply_var[i][0] = 0;
                                    supply_var[i][1] = 0;
                                    supply_var[i][2] = 0;
                                    supply_var[i][3] = 0;
                                    supply_var[i][4] = 0;
                                    sl_price = 0;
                                    tp_price = 0;
                                    continue;
                                }
                                if (Bid <= supply_var[i][0] - temp_pending_pips) {
                                    sl_price = supply_var[i][1];
                                    tp_price = _roundp(supply_var[i][0] - (supply_var[i][2] - 1) * supply_var[i][3], digits) ;
                                    supply_var[i][0] = 0;
                                    supply_var[i][1] = 0;
                                    supply_var[i][2] = 0;
                                    supply_var[i][3] = 0;
                                    supply_var[i][4] = 0;
                                    ObjectSet(supply_name, OBJPROP_COLOR, pointless_color);
                                    ObjectSet(supply_name, OBJPROP_LEVELCOLOR, pointless_color);
                                    ObjectSet(supply_name, OBJPROP_LEVELWIDTH, 2);
                                    ObjectSet(supply_name, OBJPROP_FIBOLEVELS, 2);
                                    return (true);
                                }
                            }
                        }
                    }
                }
            }
        } else {
            return (false);
        }
    }
    if (type == 2 && sl_price > 0) {
        return (sl_price);
    }
    if (type == 3 && tp_price > 0) {
        return (tp_price);
    }
}

double GetDemand(int type) {
    static double demand_var[][5], sl_price, tp_price;
    string demand_name;
    double temp_pending_pips;
    if (type == go_long) {
        ArrayResize(demand_var, ObjectsTotal());
        if (ObjectsTotal(OBJ_FIBO) > 0) {
            for (int i = ObjectsTotal() - 1; i >= 0; i--) {
                demand_name = ObjectName(i);
                if (ObjectType(demand_name) == OBJ_FIBO) {
                    if (ObjectGet(demand_name, OBJPROP_COLOR) == demand_color) {
                        demand_var[i][0] = ObjectGet(demand_name, OBJPROP_PRICE1);
                        demand_var[i][1] = ObjectGet(demand_name, OBJPROP_PRICE2);
                        demand_var[i][2] = ObjectGet(demand_name, OBJPROP_FIRSTLEVEL + 2);
                        if (demand_var[i][3] != demand_var[i][0] - demand_var[i][1]) {
                            demand_var[i][3] = demand_var[i][0] - demand_var[i][1];
                            demand_var[i][4] = 0;
                        }
                        if (pending_pips_rr == 0) {
                            temp_pending_pips = pending_pips * Point;
                        } else {
                            temp_pending_pips = demand_var[i][3] * pending_pips_rr;
                        }
                        if (demand_var[i][0] != 0 && demand_var[i][1] != 0 && demand_var[i][2] != 0 && demand_var[i][3] != 0) {
                            if (Ask <= demand_var[i][0] && Bid >= demand_var[i][1] && demand_var[i][4] == 0) {
                                demand_var[i][4] = 1;
                            }
                            if (demand_var[i][4] == 1) {
                                if (Ask <= _roundp(demand_var[i][1] - demand_var[i][3] * buffer_size , digits)) {
                                    ObjectSet(demand_name, OBJPROP_COLOR, pointless_color);
                                    ObjectSet(demand_name, OBJPROP_LEVELCOLOR, pointless_color);
                                    ObjectSet(demand_name, OBJPROP_LEVELWIDTH, 2);
                                    ObjectSet(demand_name, OBJPROP_FIBOLEVELS, 2);
                                    demand_var[i][0] = 0;
                                    demand_var[i][1] = 0;
                                    demand_var[i][2] = 0;
                                    demand_var[i][3] = 0;
                                    demand_var[i][4] = 0;
                                    sl_price = 0;
                                    tp_price = 0;
                                    continue;
                                }
                                if (Ask >= demand_var[i][0] + temp_pending_pips) {
                                    sl_price = demand_var[i][1];
                                    tp_price = _roundp(demand_var[i][0] + (demand_var[i][2] - 1) * demand_var[i][3], digits) ;
                                    demand_var[i][0] = 0;
                                    demand_var[i][1] = 0;
                                    demand_var[i][2] = 0;
                                    demand_var[i][3] = 0;
                                    demand_var[i][4] = 0;
                                    ObjectSet(demand_name, OBJPROP_COLOR, pointless_color);
                                    ObjectSet(demand_name, OBJPROP_LEVELCOLOR, pointless_color);
                                    ObjectSet(demand_name, OBJPROP_LEVELWIDTH, 2);
                                    ObjectSet(demand_name, OBJPROP_FIBOLEVELS, 2);
                                    return (true);
                                }
                            }
                        }
                    }
                }
            }
        } else {
            return (false);
        }
    }
    if (type == get_sl_price && sl_price > 0) {
        return (sl_price);
    }
    if (type == get_tp_price && tp_price > 0) {
        return (tp_price);
    }
}


void SupplyDemandTrading() {
    double take, stop, price, send_lot, temp_send_lot, ticket;
    int type, temp_magic_number;
    bool send_trade;
    RefreshRates();
    if (!IsTradingAllowed()) {
        return;
    }
    if (GetDemand(go_long) == true) {
        if (sell_open) {
            force_trade_closure = true;
            while (force_trade_closure) {
                CloseAllTrades();
                Sleep(100);
            }
        }
        type = OP_BUY;
        price = Ask;
        stop = _roundp(GetDemand(get_sl_price) - hidden_pips * Point, digits);
        take = _roundp(GetDemand(get_tp_price) + hidden_pips * Point, digits);
        temp_send_lot = CalculateDynamicDeltaSwansonLot(price, stop + hidden_pips * Point);
        send_trade = true;
    } else if (GetSupply(go_short) == true) {
        if (buy_open) {
            force_trade_closure = true;
            while (force_trade_closure) {
                CloseAllTrades();
                Sleep(100);
            }
        }
        type = OP_SELL;
        price = Bid;
        stop = _roundp(GetSupply(get_sl_price) + hidden_pips * Point, digits);
        take = _roundp(GetSupply(get_tp_price) - hidden_pips * Point, digits);
        temp_send_lot = CalculateDynamicDeltaSwansonLot(price, stop - hidden_pips * Point);
        send_trade = true;
    }
    if (send_trade) {
        if (open_trades == 0) {
            temp_magic_number = entry;
        } else {
            temp_magic_number = magic_piramide;
        }
        while (temp_send_lot > 0) {
            if (temp_send_lot > MarketInfo(symbol, MODE_MAXLOT)) {
                send_lot = MarketInfo(symbol, MODE_MAXLOT);
                temp_send_lot -= MarketInfo(symbol, MODE_MAXLOT);
            } else {
                send_lot = temp_send_lot;
                temp_send_lot = 0;
            }
            if (ticket == 0) {
                ticket = OrderSendReliable(symbol, type, send_lot, price, slippage, stop, take, trade_comment, temp_magic_number, 0, CLR_NONE);
            }
            if (ticket != 0) {
                if (type == OP_SELL) {
                    stop -= hidden_pips * Point;
                    take += hidden_pips * Point;
                    DrawHiddenTakeProfit(ticket, take);
                    DrawHiddenStopLoss(ticket, stop);
                }
                if (type == OP_BUY) {
                    stop += hidden_pips * Point;
                    take -= hidden_pips * Point;
                    DrawHiddenTakeProfit(ticket, take);
                    DrawHiddenStopLoss(ticket, stop);
                }
            }
        }
    }
}

void SasTrading() {
    if (!IsTradingAllowed()) {
        return;
    }
    if (ObjectsTotal(OBJ_HLINE) > 0) {
        for (int i = ObjectsTotal() - 1; i >= 0; i--) {
            int type, ticket, temp_magic_number;
            double price, stop, take, send_lot, temp_send_lot;
            string name = ObjectName(i);
            if (StringSubstr(name, 0, 15) == "Horizontal Line") {
                Print("I found !sas trigger");
                double trigger = ObjectGet(name, OBJPROP_PRICE1);
                if (open_trades == 0) {
                    temp_magic_number = entry;
                } else {
                    temp_magic_number = magic_piramide;
                }
                if (trigger > Ask) {
                    Print("Trigger is sell signal");
                    if (trigger - Ask > max_stop * point && max_stop > 0) {
                        ObjectDelete(name);
                        Print("Error: stop " + (trigger - Ask) + " > " + (max_stop * point) + " max_stop ");
                        Print(max_stop);
                        Print(point);
                        Print(trigger - Ask > max_stop * point);
                        return;
                    }
                    type = OP_SELL;
                    price = Bid;
                    stop = trigger + hidden_pips * point;
                    take = price - (trigger - price) * 3 - hidden_pips * point;
                    temp_send_lot = CalculateDynamicDeltaSwansonLot(price, trigger);
                    while (ticket == 0) {
                        while (temp_send_lot > 0) {
                            if (temp_send_lot > MarketInfo(symbol, MODE_MAXLOT)) {
                                send_lot = MarketInfo(symbol, MODE_MAXLOT);
                                temp_send_lot -= MarketInfo(symbol, MODE_MAXLOT);
                            } else {
                                send_lot = temp_send_lot;
                                temp_send_lot = 0;
                            }
                            if (ticket == 0) {
                                ticket = OrderSendReliable(symbol, type, send_lot, price, slippage, stop, take, trade_comment, temp_magic_number, 0, CLR_NONE);
                            }
                        }
                    }
                    if (ticket != 0) {
                        ObjectDelete(name);
                        stop = trigger;
                        take -= hidden_pips * point;
                        DrawHiddenTakeProfit(ticket, take);
                        DrawHiddenStopLoss(ticket, stop);
                    }
                }
                if (trigger < Bid) {
                    Print("Trigger is buy signal");
                    Print(Bid, " ", trigger, " ", max_stop, " ", point, " ", multiplier);
                    if (Bid - trigger > max_stop * point) {
                        ObjectDelete(name);
                        Print("Error: stop " + (trigger - Ask) + " > " + (max_stop * point) + " max_stop ");
                        return;
                    }
                    type = OP_BUY;
                    price = Ask;
                    stop = trigger - hidden_pips * point;
                    take = price + (price - trigger) * 3 +  hidden_pips * point;
                    Print("blablabla0");
                    temp_send_lot = CalculateDynamicDeltaSwansonLot(price, trigger);
                    Print("blablabla1");
                    while (ticket == 0) {
                        while (temp_send_lot > 0) {
                            if (temp_send_lot > MarketInfo(symbol, MODE_MAXLOT)) {
                                send_lot = MarketInfo(symbol, MODE_MAXLOT);
                                temp_send_lot -= MarketInfo(symbol, MODE_MAXLOT);
                            } else {
                                send_lot = temp_send_lot;
                                temp_send_lot = 0;
                            }
                            if (ticket == 0) {
                                ticket = OrderSendReliable(symbol, type, send_lot, price, slippage, stop, take, trade_comment, temp_magic_number, 0, CLR_NONE);
                            }
                        }
                    }
                    if (ticket != 0) {
                        ObjectDelete(name);
                        stop = trigger;
                        take += hidden_pips * Point;
                        DrawHiddenTakeProfit(ticket, take);
                        DrawHiddenStopLoss(ticket, stop);
                    }
                }
            }
        }
    }
}


void LookForTradeClosure(int ticket) {
    if (!OrderSelect(ticket, SELECT_BY_TICKET)) {
        return;
    }
    if (OrderSelect(ticket, SELECT_BY_TICKET) && OrderCloseTime() > 0) {
        return;
    }
    bool CloseThisTrade;
    double take = ObjectGet(tp_line_name, OBJPROP_PRICE1);
    double stop = ObjectGet(sl_line_name, OBJPROP_PRICE1);
    if (OrderType() == OP_BUY) {
        if (Ask >= take && take > 0) {
            CloseThisTrade = true;
        }
        if (Bid <= stop && stop > 0) {
            CloseThisTrade = true;
        }
    }
    if (OrderType() == OP_SELL) {
        if (Bid <= take && take > 0) {
            CloseThisTrade = true;
        }
        if (Ask >= stop && stop > 0) {
            CloseThisTrade = true;
        }
    }
    if (CloseThisTrade) {
        bool result = OrderCloseReliable(ticket, OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
    }
    if (result) {
        open_trades--;
        DeletePendingPriceLines(ticket);
    }
}

void CloseAllTrades() {
    force_trade_closure = false;
    if (OrdersTotal() == 0) {
        return;
    }
    for (int cc = OrdersTotal() - 1; cc >= 0; cc--) {
        if (OrderSelect(cc, SELECT_BY_POS)) {
            if (OrderMagicNumber() == magic_number || OrderMagicNumber() == magic_piramide) {
                if (OrderSymbol() == symbol) {
                    if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
                        bool result = OrderCloseReliable(OrderTicket(), OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
                    }
                    if (result) {
                        cc++;
                    }
                    if (!result) {
                        force_trade_closure = true;
                    }
                }
            }
        }
    }
    if (!force_trade_closure) {
        open_trades = 0;
        buy_open = false;
        sell_open = false;
    }
}

void CountOpenTrades() {
    open_trades = 0;
    buy_open = false;
    sell_open = false;
    ArrayResize(orders, 0);
    if (OrdersTotal() > 0) {
        ArrayResize(orders, OrdersTotal());
        for (int i = OrdersTotal() - 1; i >= 0; i--) {
            if (OrderSelect(i, SELECT_BY_POS)) {
                if (OrderSymbol() == symbol && (OrderMagicNumber() == magic_number || OrderMagicNumber() == magic_piramide) && (OrderType() == OP_BUY || OrderType() == OP_SELL)) {
                    open_trades++;
                    int ticket_no = OrderTicket();
                    orders[i][0] = OrderTicket();
                    orders[i][1] = _roundp(OrderOpenPrice(), digits);
                    orders[i][2] = _roundp(OrderStopLoss(), digits);
                    orders[i][3] = _roundp(OrderTakeProfit(), digits);
                    orders[i][4] = OrderLots();
                    if (OrderType() == OP_BUY) {
                        buy_open = true;
                    }
                    if (OrderType() == OP_SELL) {
                        sell_open = true;
                    }
                    LookForTradeClosure(ticket_no);
                }
            }
        }
    } else {
        ArrayResize(orders, 0);
    }
    ArrayResize(orders, open_trades);
    last_order = open_trades - 1;
}

////////////////////////////////////////////////////////////////////////////////////////////////
//Indicator module

double GetAtr(int tf, int period, double multiplier) {
    double atr = iATR(NULL, tf, period, 0);
    atr *= multiplier;
    return (atr);
}

double GetFractal(int type, int mode, int timeframe) {
    for (int i = 1; i < Bars; i++) {
        double last_fractal = iFractals(symbol, timeframe, type, i);
        if (last_fractal != 0) {
            if (type == MODE_UPPER) {
                if (mode == 0) {
                    if (last_fractal > iHigh(symbol, timeframe, iHighest(symbol, timeframe, MODE_CLOSE, i - 1, 1))) {
                        return (last_fractal);
                    }
                }
                if (mode == 1) {
                    return (last_fractal);
                }
            }
            if (type == MODE_LOWER) {
                if (mode == 0) {
                    if (last_fractal <  iLow(symbol, timeframe, iLowest(symbol, timeframe, MODE_CLOSE, i - 1, 1))) {
                        return (last_fractal);
                    }
                }
                if (mode == 1) {
                    return (last_fractal);
                }
            }
        }
    }
}

void CalculateResult() {
    static int old_history_total;
    static datetime day_bar;
    double local_multiplier, pips;
    if (old_history_total != OrdersHistoryTotal() || day_bar != iTime(symbol, 1440, 0)) {
        old_history_total = OrdersHistoryTotal();
        day_bar = iTime(symbol, 1440, 0);
        entry_cash_profit = 0;
        entry_win_trades = 0;
        entry_pips_profit = 0;
        entry_loss_trades = 0;
        entry_pips_loss = 0;
        piramide_cash_profit = 0;
        piramide_win_trades = 0;
        piramide_pips_profit = 0;
        piramide_loss_trades = 0;
        piramide_pips_loss = 0;
        today_loss_trades = 0;
        today_win_trades = 0;
        day_cash_profit = 0;
        day_pip_profit = 0;
        int total_history = OrdersHistoryTotal();
        if (total_history == 0) {
            return;
        }
        for (int cc = total_history; cc >= 0; cc--) {
            if (OrderSelect(cc, SELECT_BY_POS, MODE_HISTORY)) {
                if (OrderType() != 6 && OrderType() != 7) {
                    if (MarketInfo(OrderSymbol(), MODE_DIGITS) == 1 || MarketInfo(OrderSymbol(), MODE_DIGITS) == 3 || MarketInfo(OrderSymbol(), MODE_DIGITS) == 5 || MarketInfo(OrderSymbol(), MODE_MARGINCALCMODE) != 0) {
                        local_multiplier = 10;
                    } else {
                        local_multiplier = 1;
                    }
                    if (OrderMagicNumber() == entry) {
                        entry_cash_profit += (OrderProfit() + OrderSwap() + OrderCommission());
                        if (OrderProfit() > 0) {
                            entry_win_trades++;
                            entry_pips_profit += MathAbs((OrderClosePrice() - OrderOpenPrice()) / MarketInfo(OrderSymbol(), MODE_POINT) / local_multiplier);
                        } else if (OrderProfit() < 0) {
                            entry_loss_trades++;
                            entry_pips_loss += MathAbs((OrderClosePrice() - OrderOpenPrice()) / MarketInfo(OrderSymbol(), MODE_POINT) / local_multiplier);
                        }
                    } else if (OrderMagicNumber() == magic_piramide) {
                        piramide_cash_profit += (OrderProfit() + OrderSwap() + OrderCommission());
                        if (OrderProfit() > 0) {
                            piramide_win_trades++;
                            piramide_pips_profit += MathAbs((OrderClosePrice() - OrderOpenPrice()) / MarketInfo(OrderSymbol(), MODE_POINT) / local_multiplier);
                        } else if (OrderProfit() < 0) {
                            piramide_loss_trades++;
                            piramide_pips_loss += MathAbs((OrderClosePrice() - OrderOpenPrice()) / MarketInfo(OrderSymbol(), MODE_POINT) / local_multiplier);
                        }
                    }
                    if (TimeDayOfYear(GMTseconds() + (3600 * broker_time_shift)) == TimeDayOfYear(OrderCloseTime())) {
                        day_cash_profit += (OrderProfit() + OrderSwap() + OrderCommission());
                        if (OrderType() == OP_BUY) {
                            day_pip_profit += (OrderClosePrice() - OrderOpenPrice()) / MarketInfo(OrderSymbol(), MODE_POINT) / local_multiplier;
                        }
                        if (OrderType() == OP_SELL) {
                            day_pip_profit += (OrderOpenPrice() - OrderClosePrice()) / MarketInfo(OrderSymbol(), MODE_POINT) / local_multiplier;
                        }
                        if (OrderProfit() > 0) {
                            today_win_trades++;
                        }
                        if (OrderProfit() < 0) {
                            today_loss_trades++;
                        }
                    }
                }
            }
        }
        if (entry_pips_profit > 0 && entry_win_trades > 0) {
            entry_average_profit = entry_pips_profit / entry_win_trades;
        }
        if (entry_pips_loss > 0 && entry_loss_trades > 0) {
            entry_average_loss = entry_pips_loss / entry_loss_trades;
        }
        if (entry_average_loss > 0 && entry_average_profit > 0) {
            entry_risk_reward = entry_average_loss / entry_average_profit;
        }
        if (piramide_pips_profit > 0 && piramide_win_trades > 0) {
            piramide_average_profit = piramide_pips_profit / piramide_win_trades;
        }
        if (piramide_pips_loss > 0 && piramide_loss_trades > 0) {
            piramide_average_loss = piramide_pips_loss / piramide_loss_trades;
        }
        if (piramide_average_loss > 0 && piramide_average_profit > 0) {
            piramide_risk_reward = piramide_average_loss / piramide_average_profit;
        }
        entry_pips_loss *= -1;
        piramide_pips_loss *= -1;
    }
}

double GetLotDistance() {
    double lot_distance;
    for (int i = last_order; i >= 0; i--) {
        if (OrderSelect(orders[i][0], SELECT_BY_TICKET, MODE_TRADES)) {
            if (OrderSymbol() == symbol) {
                if (OrderType() == OP_BUY) {
                    double distance = (Bid - orders[i][1]) / Point;
                    lot_distance += distance * OrderLots();
                }
                if (OrderType() == OP_SELL) {
                    distance = (orders[i][1] - Ask) / Point;
                    lot_distance += distance * OrderLots();
                }
            }
        }
    }
    return (lot_distance);
}

double CheckLotDistance(double percent) {
    double actual_lot_distance = GetLotDistance();
    double required_lot_distance = actual_lot_distance * (100 - percent) * 0.01;
    double difrence_lot_distance = actual_lot_distance - required_lot_distance;
    double total_size;
    for (int i = last_order; i >= 0; i--) {
        if (OrderSelect(orders[i][0], SELECT_BY_TICKET, MODE_TRADES)) {
            if (OrderSymbol() == symbol) {
                total_size += OrderLots();
            }
        }
    }
    return (difrence_lot_distance / total_size);
}

//End Indicator module
////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////
//Pending trade price lines module.
void DrawHiddenStopLoss(int ticket, double price) {
    string sl_name = StringConcatenate(ticket, sl_line_name);
    if (ObjectFind(sl_name) == -1) {
        ObjectCreate(sl_name, OBJ_HLINE, 0, Time[0], price);
        ObjectSet(sl_name, OBJPROP_COLOR, supply_color);
        ObjectSet(sl_name, OBJPROP_WIDTH, 1);
        ObjectSet(sl_name, OBJPROP_STYLE, STYLE_SOLID);
    }
}


void DrawHiddenTakeProfit(int ticket, double price) {
    string tp_name = StringConcatenate(ticket, tp_line_name);
    if (ObjectFind(tp_name) == -1) {
        ObjectCreate(tp_name, OBJ_HLINE, 0, Time[0], price);
        ObjectSet(tp_name, OBJPROP_COLOR, demand_color);
        ObjectSet(tp_name, OBJPROP_WIDTH, 1);
        ObjectSet(tp_name, OBJPROP_STYLE, STYLE_SOLID);
    }
}


void DeletePendingPriceLines(int ticket) {
    string tp_name = StringConcatenate(ticket, tp_line_name);
    string sl_name = StringConcatenate(ticket, sl_line_name);
    if (ObjectFind(sl_line_name) != -1) {
        ObjectDelete(sl_line_name);
    }
    if (ObjectFind(tp_line_name) != -1) {
        ObjectDelete(tp_line_name);
    }
}

void DeleteOrphanPriceLines() {
    for (int i = ObjectsTotal(OBJ_HLINE) - 1; i >= 0; i--) {
        string line_name = ObjectName(i);
        Print("found " + line_name);
        int tp_index = StringFind(line_name, tp_line_name, 0);
        int sl_index = StringFind(line_name, sl_line_name, 0);
        if (tp_index != -1) {
            string ticket = StringSubstr(line_name, 0, tp_index);
            Print("Delete Ticket: " + ticket);
            if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
                ObjectDelete(line_name);
            }
        }
    }
}

bool CheckMarginLevel() {
    if (use_margin_check && AccountMargin() > 0) {
        double ml = _roundp(AccountEquity() / AccountMargin() * 100, 2);
        if (ml < minimum_margin_percen) {
            //string screen_message = StringConcatenate ( "There is insufficient margin percent to allow trading. ", DoubleToStr ( ml, 2 ), "%" );
            //ObjectMakeLabel ( StringConcatenate ( sd, "margin_level_message" ), screen_message, font_size, font_type, Red, 30, 30, 0, 1 );
            DisplayUserFeedback();
            return (false);
        } else {
            ObjectDelete(StringConcatenate(sd, "margin_level_message"));
        }
    }
    return (true);
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
    //----
    DragDropLine();
    if (use_sd) {
        GetFibo();
    }
    if (force_trade_closure) {
        CloseAllTrades();
        return;
    }
    CountOpenTrades();
    CalculateResult();
    TradeManagementModule();
    if (CheckMarginLevel()) {
        if (!stop_trading) {
            if (use_sd) {
                SupplyDemandTrading();
            }
            if (use_sas) {
                SasTrading();
            }
        }
    }
    DeleteOrphanPriceLines();
    DisplayUserFeedback();
    //----
    return (0);
}
//+------------------------------------------------------------------+

int ObjectMakeLabel(string name, string text, int font_size, string font, color font_color, int x, int y, int window, int corner) {
    if (ObjectFind(name) == -1) {
        ObjectCreate(name, OBJ_LABEL, window, 0, 0);
    }
    ObjectSet(name, OBJPROP_CORNER, corner);
    ObjectSet(name, OBJPROP_XDISTANCE, x);
    ObjectSet(name, OBJPROP_YDISTANCE, y);
    ObjectSet(name, OBJPROP_BACK, false);
    ObjectSetText(name, text, font_size, font, font_color);
    return (0);
}

void DisplayUserFeedback() {
    int temp_offset = 20;
    if (IsTesting() && !IsVisualMode()) {
        return;
    }
    temp_offset = 30;
    string screen_message = StringConcatenate("Supply&Demand semi-auto trading robot by Ribelo on ", symbol);
    ObjectMakeLabel(StringConcatenate(sd, "ea_name"), screen_message, font_size * 1.2, "ArialBlack", supply_color, data_disp_gap_size, temp_offset, 0, 0);
    temp_offset += 2 * data_disp_offset;
    double i;
    int m, s, k;
    m = Time[0] + Period() * 60 - CurTime();
    i = m / 60.0;
    s = m % 60;
    m = (m - m % 60) / 60;
    if (magic_number != 0) {
        screen_message = StringConcatenate("Magic number: ", magic_number);
        ObjectMakeLabel(StringConcatenate(sd, "magic_number_message"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
    }
    if (trade_comment != " ") {
        screen_message = StringConcatenate("Trade comment: ", trade_comment);
        ObjectMakeLabel(StringConcatenate(sd, "trade_comment_message"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
    }
    screen_message = StringConcatenate("Max spreed = ", max_spreed, ": Spread = ", MarketInfo(symbol, MODE_SPREAD));
    ObjectMakeLabel(StringConcatenate(sd, "spreed_message"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
    temp_offset += data_disp_offset * 2;
    if (automate_build_piramide) {
        screen_message = "Automate build piramide";
        ObjectMakeLabel(StringConcatenate(sd, "piramide_type"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
        screen_message = StringConcatenate("First piramide order distance: ", first_order_distance);
        ObjectMakeLabel(StringConcatenate(sd, "first_order_distance"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
        screen_message = StringConcatenate("Next piramide order distance: ", next_order_distance);
        ObjectMakeLabel(StringConcatenate(sd, "next_order_distance"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
        if (use_trailing_stop) {
            temp_offset += data_disp_offset;
            screen_message = "Trailing stop:";
            ObjectMakeLabel(StringConcatenate(sd, "trailing_stop"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
            temp_offset += data_disp_offset;
            screen_message = StringConcatenate("Strart from ", start_tp_percent, "% TP");
            ObjectMakeLabel(StringConcatenate(sd, "strart_trailing"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
            temp_offset += data_disp_offset;
            screen_message = StringConcatenate("End on ", stop_tp_percent, "% TP");
            ObjectMakeLabel(StringConcatenate(sd, "stop_trailing"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
            temp_offset += data_disp_offset;
        }
    } else {
        if (use_trailing_stop && trailing_first_trade) {
            temp_offset += data_disp_offset;
            screen_message = "Trailing stop";
            ObjectMakeLabel(StringConcatenate(sd, "trailing_stop"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
            temp_offset += data_disp_offset;
            screen_message = StringConcatenate("Strart from ", start_tp_percent, "%");
            ObjectMakeLabel(StringConcatenate(sd, "strart_stop"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
            temp_offset += data_disp_offset;
            screen_message = StringConcatenate("End on ", stop_tp_percent, "%");
            ObjectMakeLabel(StringConcatenate(sd, "stop_stop"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
            temp_offset += data_disp_offset;
        }
    }
    //Running total of trades
    if (show_statistic) {
        temp_offset += data_disp_offset;
        screen_message = StringConcatenate("Today results. Wins: ", today_win_trades, " Losses: ", today_loss_trades, " Cash: ", DoubleToStr(day_cash_profit, 2), "$ Pip: ", DoubleToStr(day_pip_profit, 2));
        ObjectMakeLabel(StringConcatenate(sd, "results_today_message"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
        screen_message = StringConcatenate("Total entry results. Wins: ", entry_win_trades, " Losses: ", entry_loss_trades, " Cash: ", DoubleToStr(entry_cash_profit, 2), "$");
        ObjectMakeLabel(StringConcatenate(sd, "results_entry_message"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
        screen_message = StringConcatenate("Total piramide results. Wins: ", piramide_win_trades, " Losses: ", piramide_loss_trades, " Cash: ", DoubleToStr(piramide_cash_profit, 2), "$");
        ObjectMakeLabel(StringConcatenate(sd, "results_piramide_message"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
        screen_message = StringConcatenate("Entry risk reward", DoubleToStr(entry_risk_reward, 2));
        ObjectMakeLabel(StringConcatenate(sd, "entry_risk_reward_message"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
        screen_message = StringConcatenate("Piramide risk reward", DoubleToStr(piramide_risk_reward, 2));
        ObjectMakeLabel(StringConcatenate(sd, "piramide_piramide_message"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
    }
    if (use_label_box) {
        //if ( ObjectFind ( "[[LabelBorder]]" ) == -1 ) {
        //ObjectMakeLabel( "[[LabelBorder]]", "c", 210, "Webdings", label_border, 10, 15, 0 );
        //}
        int count = temp_offset / data_disp_offset / 3;
        temp_offset = 20;
        for (int cc = count - 1; cc >= 0; cc--) {
            string name = StringConcatenate("[", sd, "label_box", cc, "]");
            if (ObjectFind(name) == -1) {
                ObjectMakeLabel(name, "ggggggggg", 34, "Webdings", label_box, data_disp_gap_size - (data_disp_gap_size / 2), temp_offset, 0, 0);
            }
            temp_offset += 45;
        }
    }
}//void DisplayUserFeedback()
