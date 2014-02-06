//+-------------------------------------------------------------------+
//|                  Just A Rather Very Intelligent System by Huxley  |
//|                                         Copyright   2013, Huxley  |
//+-------------------------------------------------------------------+
#property copyright "Copyright 2014, Huxley"
#include <wrb_analysis.mqh>
#include <gsl_math.mqh>
#include <LibGMT.mqh>
#include <LibOrderReliable4.mqh>
#define PREFIX "j.a.r.v.i.s"


extern string  gen = "----general inputs----";
extern bool    use_sd = true;
extern bool    use_sas = true;
extern int     timer_interval = 250;

extern double  max_stop = 30.0;
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
extern bool    hg_only = true;
extern bool    use_fractal = true;
extern int     fractal_length = 5;

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

//Trading variables
int            retry_count = 10;//Will make this number of attempts to get around the trade context busy error.
int            open_trades;
double         orders[][5]; //first array is order number array, second array =
//0 - ticket_no
//1 - entry_price
//2 - sl
//3 - tp
//4 - lot
//Misc
int            pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
string         symbol;
int            tf, digits, multiplier, spread;
double         tickvalue, point;
string         pip_description = " pips";
bool           force_trade_closure;


double candle[][6];
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
    //----
    symbol = Symbol();
    tf = Period();
    digits = MarketInfo(symbol, MODE_DIGITS);
    multiplier = pip_mult_tab[digits];
    point = MarketInfo(symbol, MODE_POINT);
    spread = MarketInfo(symbol, MODE_SPREAD) * multiplier;
    tickvalue = MarketInfo(symbol, MODE_TICKVALUE) * multiplier;
    if (multiplier > 1) {
        pip_description = " points";
    }
    ArrayCopyRates(candle, symbol, tf);
    max_stop *= multiplier;
    max_spreed *= multiplier;
    slippage *= multiplier;
    hidden_pips *= multiplier;
    pending_pips *= multiplier;
    if (trade_comment == "") {
        trade_comment = " ";
    }
    if (criminal_is_ecn) {
        O_R_Config_use2step(true);
    }
    PendingToFibo();
    GetFibo();
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
    FiboToPending();
    if (ObjectsTotal() > 0) {
        for (int i = ObjectsTotal() - 1; i >= 0; i--) {
            string name = ObjectName(i);
            if (StringSubstr(name, 0, 4) == PREFIX || StringSubstr(name, 1, 4) == PREFIX) {
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
                    old_stop = NormalizeDouble(OrderStopLoss(), digits);
                    old_take = NormalizeDouble(OrderTakeProfit(), digits);
                    if (OrderType() == OP_BUY) {
                        new_stop = NormalizeDouble(ObjectGet(ticket + "_sl_line", OBJPROP_PRICE1) - hidden_pips * point, digits);
                        new_take = NormalizeDouble(ObjectGet(ticket + "_tp_line", OBJPROP_PRICE1) + hidden_pips * point, digits);
                        if (ObjectFind(ticket + "_sl_line") != -1) {
                            if (_fcmp(old_stop, new_stop) != 0) {
                                Print("Order " + ticket + " sl ", old_stop, " trigger has been moved to ", new_stop, " so i move sl line");
                                Print("Order " + ticket + " old_stop ", old_stop," new_stop ", new_stop, " fcmp ", _fcmp(old_stop, new_stop));
                                OrderModifyReliable(ticket, OrderOpenPrice(), new_stop, new_take, 0, CLR_NONE);
                            }
                        } else {
                            Print("Order " + ticket + " sl does not exist, so I create a new one");
                            DrawHiddenStopLoss(ticket, old_stop + hidden_pips * point);
                        }
                        if (ObjectFind(ticket + "_tp_line") != -1) {
                            if (_fcmp(old_take, new_take) != 0) {
                                Print("Order " + ticket + " tp trigger has been moved so i move tp line");
                                Print("Order " + ticket + " old_take ", old_take," new_take ", new_take, " fcmp ", _fcmp(old_take, new_take));
                                OrderModifyReliable(ticket, OrderOpenPrice(), new_stop, new_take, 0, CLR_NONE);
                            }
                        } else {
                            Print("Order " + ticket + " tp does not exist, so I create a new one");
                            DrawHiddenTakeProfit(ticket, old_take - hidden_pips * Point);
                        }
                    } else if (OrderType() == OP_SELL) {
                        new_stop = NormalizeDouble(ObjectGet(ticket + "_sl_line", OBJPROP_PRICE1) + hidden_pips * point, digits);
                        new_take = NormalizeDouble(ObjectGet(ticket + "_tp_line", OBJPROP_PRICE1) - hidden_pips * point, digits);
                        if (ObjectFind(ticket + "_sl_line") != -1) {
                            if (_fcmp(old_stop, new_stop) != 0) {
                                Print("Order " + ticket + " sl trigger has been moved so i move sl line");
                                Print("Order " + ticket + " old_stop ", old_stop," new_stop ", new_stop, " fcmp ", _fcmp(old_stop, new_stop));
                                OrderModifyReliable(ticket, OrderOpenPrice(), new_stop, new_take, 0, CLR_NONE);
                            }
                        } else {
                            Print("Order " + ticket + " sl does not exist, so I create a new one");
                            DrawHiddenStopLoss(ticket, old_stop - hidden_pips * point);
                        }
                        if (ObjectFind(ticket + "_tp_line") != -1) {
                            if (_fcmp(old_take, new_take) != 0) {
                                Print("Order " + ticket + " tp trigger has been moved so i move tp line");
                                Print("Order " + ticket + " old_take ", old_take," new_take ", new_take, " fcmp ", _fcmp(old_take, new_take));
                                OrderModifyReliable(ticket, OrderOpenPrice(), new_stop, new_take, 0, CLR_NONE);
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


void FiboToPending() {
    double entry_price, exit_price, desire_price, desire_rr, zone_size, send_lot;
    int type, ticket;
    int total_objects = ObjectsTotal();
    if (total_objects > 0) {
        for (int i = 0; i < total_objects; i++) {
            string name = ObjectName(i);

            if (ObjectType(name) == OBJ_FIBO) {
                if (ObjectGet(name, OBJPROP_COLOR) == demand_color) {
                    entry_price = ObjectGet(name, OBJPROP_PRICE1);
                    exit_price = ObjectGet(name, OBJPROP_PRICE2);
                    desire_rr = ObjectGet(name, OBJPROP_FIRSTLEVEL + 2);
                    zone_size = entry_price - exit_price;
                    desire_price = entry_price + (desire_rr - 1) * zone_size;
                    send_lot = CalculateDynamicDeltaSwansonLot(entry_price, exit_price);
                    if (_fcmp(Ask, entry_price) > 0) {
                        type = OP_BUYLIMIT;
                    } else if (_fcmp(Ask, entry_price) < 0) {
                        type = OP_BUYSTOP;
                    }
                    ticket = OrderSendReliable(symbol, type, send_lot, entry_price,
                        slippage, exit_price, desire_price, trade_comment,
                        magic_number, 0, CLR_NONE);
                    if (ticket != 0) {
                        ObjectDelete(name);
                    }
                } else if (ObjectGet(name, OBJPROP_COLOR) == supply_color) {
                    entry_price = ObjectGet(name, OBJPROP_PRICE1);
                    exit_price = ObjectGet(name, OBJPROP_PRICE2);
                    desire_rr = ObjectGet(name, OBJPROP_FIRSTLEVEL + 2);
                    zone_size = exit_price - entry_price;
                    desire_price = entry_price - (desire_rr - 1) * zone_size;
                    send_lot = CalculateDynamicDeltaSwansonLot(entry_price, exit_price);
                    if (_fcmp(Bid, entry_price) < 0) {
                        type = OP_SELLLIMIT;
                    } else if (_fcmp(Bid, entry_price) > 0) {
                        type = OP_SELLSTOP;
                    }
                    ticket = OrderSendReliable(symbol, type, send_lot, entry_price,
                        slippage, exit_price, desire_price, trade_comment,
                        magic_number, 0, CLR_NONE);
                    if (ticket != 0) {
                        ObjectDelete(name);
                    }
                }
            }
        }
    }
}


void PendingToFibo() {
    double entry_price, exit_price, desire_price, desire_rr, zone_size, send_lot;
    int type, ticket;
    int total_orders = OrdersTotal();
    if (total_orders > 0) {
        for (int i = total_orders - 1; i >=0; i--) {
            OrderSelect(i, MODE_TRADES);
            type = OrderType();
            ticket = OrderTicket();
            string name = "Fibo" + ticket;
            if (type == OP_BUYLIMIT || type == OP_BUYSTOP) {
                entry_price = OrderOpenPrice();
                exit_price = OrderStopLoss();
                desire_price = OrderTakeProfit();
                desire_rr = (desire_price - entry_price) / (entry_price - exit_price);
                ObjectCreate(name, OBJ_FIBO, 0, iTime(symbol, tf, 10), entry_price, iTime(symbol, tf, 0), exit_price);
                ObjectSet(name, OBJPROP_FIBOLEVELS, 3);
                ObjectSet(name, OBJPROP_FIRSTLEVEL, 0);
                ObjectSet(name, OBJPROP_FIRSTLEVEL + 1, 1);
                ObjectSet(name, OBJPROP_FIRSTLEVEL + 2, desire_rr + 1);
                ObjectSet(name, OBJPROP_COLOR, demand_color);
                OrderDeleteReliable(ticket);
            } else if (type == OP_SELLLIMIT || type == OP_SELLSTOP) {
                entry_price = OrderOpenPrice();
                exit_price = OrderStopLoss();
                desire_price = OrderTakeProfit();
                desire_rr = (entry_price - desire_price) / (exit_price - entry_price);
                ObjectCreate(name, OBJ_FIBO, 0, iTime(symbol, tf, 10), entry_price, iTime(symbol, tf, 0), exit_price);
                ObjectSet(name, OBJPROP_FIBOLEVELS, 3);
                ObjectSet(name, OBJPROP_FIRSTLEVEL, 0);
                ObjectSet(name, OBJPROP_FIRSTLEVEL + 1, 1);
                ObjectSet(name, OBJPROP_FIRSTLEVEL + 2, desire_rr + 1);
                ObjectSet(name, OBJPROP_COLOR, supply_color);
                OrderDeleteReliable(ticket);
            }
        }
    }
}


void TrailingStop() {
    static double support;
    static double resistance;
    static int last_time = 0;
    if (last_time != iTime(symbol, tf, 0)) {
        last_time = iTime(symbol, tf, 0);
        support = _support(candle, 1, true, 1, 5, iBars(symbol, tf));
        resistance = _resistance(candle, 1, true, 1, 5, iBars(symbol, tf));
    }
    for (int i = open_trades - 1; i >= 0; i--) {
        int ticket = orders[i][0];
        if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            if (OrderSymbol() == symbol) {
                if (OrderMagicNumber() == magic_number) {
                    if (OrderType() == OP_BUY) {
                        if (_fcmp(OrderStopLoss(), support) < 0 && support != 0.0) {
                            ObjectMove(ticket + "_sl_line", 0, iTime(symbol, tf, 0), support);
                            Print("Order " + ticket + " trailing stop move sl line to ", support);
                        }
                    } else if (OrderType() == OP_SELL) {
                        if (_fcmp(OrderStopLoss(), resistance) > 0 && resistance != 0.0) {
                            ObjectMove(ticket + "_sl_line", 0, iTime(symbol, tf, 0), support);
                            Print("Order " + ticket + " trailing stop move sl line to ", support);
                        }
                    }
                }
            }
        }
    }
}

void LookForTradeClosure() {
    for (int i = open_trades - 1; i >= 0; i--) {
        int ticket = orders[i][0];
        if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            if (OrderSymbol() == symbol) {
                if (OrderMagicNumber() == magic_number) {
                    double take = NormalizeDouble(ObjectGet(ticket + "_tp_line", OBJPROP_PRICE1), digits);
                    double stop = NormalizeDouble(ObjectGet(ticket + "_sl_line", OBJPROP_PRICE1), digits);
                    if (OrderType() == OP_BUY) {
                        if (Ask >= take && take > 0) {
                            OrderCloseReliable(ticket, OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
                        }
                        if (Bid <= stop && stop > 0) {
                            OrderCloseReliable(ticket, OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
                        }
                    }
                    if (OrderType() == OP_SELL) {
                        if (Bid <= take && take > 0) {
                            OrderCloseReliable(ticket, OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
                        }
                        if (Ask >= stop && stop > 0) {
                            OrderCloseReliable(ticket, OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
                        }
                    }
                }
            }
        }
    }
}

void CloseAllTrades() {
    force_trade_closure = false;
    if (OrdersTotal() == 0) {
        return;
    }
    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS)) {
            if (OrderMagicNumber() == magic_number) {
                if (OrderSymbol() == symbol) {
                    if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
                        bool result = OrderCloseReliable(OrderTicket(), OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
                    }
                    if (!result) {
                        force_trade_closure = true;
                    }
                }
            }
        }
    }
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
    int local_multiplier, local_digits;
    int total_history = OrdersHistoryTotal();
    double dd, loss_pip, stop_pip;
    double min_lot_size = MarketInfo(symbol, MODE_MINLOT);
    double high_eq = 0.0;
    double curr_balance = 0.0;
    double account_balance[];

    stop_pip = MathAbs(open_price - stop_price) / point / multiplier;
    Print("DDSM total_history", total_history);
    if (total_history > 0) {
        int count = MathMax(total_history, 5);
        ArrayResize(account_balance, total_history);
        for (int i = total_history - 1; i >= 0; i--) {
            if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
                curr_balance += OrderProfit();
                account_balance[i] = curr_balance;
            }
        }
        Print("DDSM count", count);
        Print("DDSM ", total_history - count - 1);
        for (i = total_history - count - 1; i < total_history; i++) {
            high_eq = MathMax(high_eq, account_balance[i]);
            if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
                if (OrderType() == 6 || OrderType() == 7) {
                    count++;
                    continue;
                }
                if (OrderProfit() < 0) {
                    local_digits = MarketInfo(OrderSymbol(), MODE_DIGITS);
                    local_multiplier = pip_mult_tab[local_digits];
                    dd += MathAbs(OrderOpenPrice() - OrderClosePrice()) / MarketInfo(OrderSymbol(), MODE_POINT) / local_multiplier;
                }
            }
        }
    } else {
        curr_balance = AccountBalance();
        high_eq = AccountBalance();
    }

    double average_risk_reward = CalculateRR();
    Print("DDSM rr ", average_risk_reward);
    if (dd > stop_pip) {
        double delta = dd / 5;
    } else {
        delta = stop_pip / 5;
    }
    Print("dd ",dd);
    Print("stop_pip ",stop_pip);
    Print("delta ",delta);
    if (delta > 0) {
        double step1 = max_dd * curr_balance / delta / 100;
        Print("step1 ", step1);
        double step2 = MathMax((curr_balance - high_eq) / delta / 100, 0);
        Print("step2 ", step2);
        double step3 = MathMax((high_eq - curr_balance) / (average_risk_reward * delta) / 100, 0);
        Print("step3 ", step3);
        double lot_delta = (max_dd * curr_balance / delta / 100 + MathMax((curr_balance - high_eq) / delta / 100, 0) - MathMax((high_eq - curr_balance) / (average_risk_reward * delta) / 100, 0)) / tickvalue;
        Print("lot_delta ", lot_delta);
        double lot_risk = curr_balance * max_risk / stop_pip / tickvalue;
        Print("lot_risk ", lot_risk);
        double lot_max = AccountFreeMargin() / stop_pip / tickvalue;
        Print("lot_max ", lot_max);
        double lot_size = MathMin(MathMin(lot_delta, lot_risk), lot_max);
        Print("lot_size ", lot_size);
    }
    return (lot_size);
}

void GetFibo() {
    double entry_price, stop_price, label_price, temp_pending_pips, temp_break_even;
    datetime start_time, end_time, label_time;
    string label_name, text_color, zone_size;
    string decsript;
    int total_objects = ObjectsTotal();
    if (total_objects > 0) {
        for (int i = 0; i < total_objects; i++) {
            string name = ObjectName(i);
            if (ObjectType(name) == OBJ_FIBO) {
                if (ObjectGet(name, OBJPROP_COLOR) != pointless_color) {
                    entry_price = ObjectGet(name, OBJPROP_PRICE1);
                    stop_price = ObjectGet(name, OBJPROP_PRICE2);
                    start_time = ObjectGet(name, OBJPROP_TIME1);
                    end_time = ObjectGet(name, OBJPROP_TIME2);
                    if (MathAbs(entry_price - stop_price) > max_stop * point && max_stop != 0) {
                        Print("Zone > max_stop");
                        ObjectSet(name, OBJPROP_COLOR, pointless_color);
                        ObjectSet(name, OBJPROP_LEVELCOLOR, pointless_color);
                        continue;
                    }
                    if (_fcmp(entry_price, stop_price) > 0) {
                        ObjectSet(name, OBJPROP_COLOR, demand_color);
                        ObjectSet(name, OBJPROP_LEVELCOLOR, demand_color);
                        ObjectSet(name, OBJPROP_LEVELWIDTH, fibo_width);
                        ObjectSet(name, OBJPROP_FIBOLEVELS, 3);
                        ObjectSetFiboDescription(name, 0, "Sl = %$");
                        ObjectSetFiboDescription(name, 1, "Entry = %$");
                        ObjectSetFiboDescription(name, 2, "TP = %$");
                        if (show_info) {
                            label_name = StringConcatenate(name, "_label");
                            label_price = stop_price - (entry_price - stop_price) * 0.25;
                            zone_size = DoubleToStr(MathAbs(entry_price - stop_price) / point / multiplier, 1);
                            decsript = StringConcatenate("demand | zone_size: ", zone_size, " pips");
                            if (ObjectFind(label_name) == -1) {
                                ObjectCreate(label_name, OBJ_TEXT, 0, Time[0], label_price);
                            }
                            ObjectSetText(label_name, text_color, info_text_size, "Tahoma", demand_color);
                            ObjectSet(label_name, OBJPROP_PRICE1, label_price);
                            ObjectSet(label_name, OBJPROP_TIME1, Time[0]);
                        }
                    }
                    if (_fcmp(entry_price, stop_price) < 0) {
                        ObjectSet(name, OBJPROP_COLOR, supply_color);
                        ObjectSet(name, OBJPROP_LEVELCOLOR, supply_color);
                        ObjectSet(name, OBJPROP_LEVELWIDTH, fibo_width);
                        ObjectSet(name, OBJPROP_FIBOLEVELS, 3);
                        ObjectSetFiboDescription(name, 0, "Sl = %$");
                        ObjectSetFiboDescription(name, 1, "Entry = %$");
                        ObjectSetFiboDescription(name, 2, "TP = %$");
                        if (show_info) {
                            label_name = StringConcatenate(name, "_label");
                            label_price = stop_price - (entry_price - stop_price) * 0.5;
                            zone_size = DoubleToStr(MathAbs(entry_price - stop_price) / point / multiplier, 1);
                            text_color = StringConcatenate("supply | zone_size: ", zone_size, " pips");
                            if (ObjectFind(label_name) == -1) {
                                ObjectCreate(label_name, OBJ_TEXT, 0, Time[0], label_price);
                            }
                            ObjectSetText(label_name, text_color, info_text_size, "Tahoma", supply_color);
                            ObjectSet(label_name, OBJPROP_PRICE1, label_price);
                            ObjectSet(label_name, OBJPROP_TIME1, Time[0]);
                        }
                    }
                }
            } else if (ObjectType(name) == OBJ_TEXT) {
                int name_len = StringLen(name);
                string short_name = StringSubstr(name, 0, name_len - 6);
                if (StringSubstr(name, 0, 4) == "Fibo") {
                    if (ObjectFind(short_name) == -1) {
                        ObjectDelete(name);
                    } else if (ObjectGet(short_name, OBJPROP_COLOR) == pointless_color) {
                        ObjectDelete(name);
                    }
                }
            }
        }
    }
}


void SupplyDemandTrading() {
    double entry_price[], exit_price[], desire_rr[], zone_size[];
    bool freeze[];
    double price, stpo_price, take_price, temp_send_lot, send_lot;
    string name;
    int type, ticket;
    bool send_trade = false;
    int total_objects;
    if (total_objects != ObjectsTotal()) {
        ArrayResize(entry_price, 0);
        ArrayResize(exit_price, 0);
        ArrayResize(desire_rr, 0);
        ArrayResize(zone_size, 0);
        ArrayResize(freeze, 0);
        total_objects = ObjectsTotal();
        ArrayResize(entry_price, total_objects);
        ArrayResize(exit_price, total_objects);
        ArrayResize(desire_rr, total_objects);
        ArrayResize(zone_size, total_objects);
        ArrayResize(freeze, total_objects);
    }
    if (total_objects > 0) {
        for (int i = 0; i < total_objects ; i++) {
            name = ObjectName(i);
            if (ObjectType(name) == OBJ_FIBO) {
                if (ObjectGet(name, OBJPROP_COLOR) == demand_color) {
                    if (_fcmp(entry_price[i], ObjectGet(name, OBJPROP_PRICE1)) != 0 ||
                            _fcmp(exit_price[i], ObjectGet(name, OBJPROP_PRICE2)) != 0) {
                        entry_price[i] = ObjectGet(name, OBJPROP_PRICE1);
                        exit_price[i] = ObjectGet(name, OBJPROP_PRICE2);
                        desire_rr[i] = ObjectGet(name, OBJPROP_FIRSTLEVEL + 2);
                        zone_size[i] = entry_price[i] - exit_price[i];
                        freeze[i] = 0;
                    }
                    if (entry_price[i] != 0 && exit_price[i] != 0 && desire_rr[i] != 0 && zone_size[i] != 0) {
                        if (_fcmp(Ask, entry_price[i]) <= 0 && _fcmp(Bid, exit_price[i]) >= 0) {
                            freeze[i] = 1;
                        }
                        if (_fcmp(Bid, exit_price[i]) <= 0 && freeze[i] == 1) {
                            ObjectSet(name, OBJPROP_COLOR, pointless_color);
                            ObjectSet(name, OBJPROP_LEVELCOLOR, pointless_color);
                            ObjectSet(name, OBJPROP_LEVELWIDTH, 2);
                            ObjectSet(name, OBJPROP_FIBOLEVELS, 2);
                            continue;
                        }
                        if (_fcmp(Ask, entry_price[i] + pending_pips * point) >= 0 && freeze[i] == 1) {
                            ObjectSet(name, OBJPROP_COLOR, pointless_color);
                            ObjectSet(name, OBJPROP_LEVELCOLOR, pointless_color);
                            ObjectSet(name, OBJPROP_LEVELWIDTH, 2);
                            ObjectSet(name, OBJPROP_FIBOLEVELS, 2);
                            type = OP_BUY;
                            price = Ask;
                            stpo_price = exit_price[i] - hidden_pips * point;
                            take_price = entry_price[i] + (desire_rr[i] - 1) * zone_size[i] + hidden_pips * point;
                            temp_send_lot = CalculateDynamicDeltaSwansonLot(price, exit_price[i]);
                            send_trade = true;
                            break;
                        }
                    }
                } else if (ObjectGet(name, OBJPROP_COLOR) == supply_color) {
                    if (_fcmp(entry_price[i], ObjectGet(name, OBJPROP_PRICE1)) != 0 ||
                            _fcmp(exit_price[i], ObjectGet(name, OBJPROP_PRICE2)) != 0) {
                        entry_price[i] = ObjectGet(name, OBJPROP_PRICE1);
                        exit_price[i] = ObjectGet(name, OBJPROP_PRICE2);
                        desire_rr[i] = ObjectGet(name, OBJPROP_FIRSTLEVEL + 2);
                        zone_size[i] = entry_price[i] - exit_price[i];
                        freeze[i] = 0;
                    }
                    if (entry_price[i] != 0 && exit_price[i] != 0 && desire_rr[i] != 0 && zone_size[i] != 0) {

                        if (_fcmp(Ask, entry_price[i]) <= 0 && _fcmp(Bid, exit_price[i]) >= 0) {
                            freeze[i] = 1;
                        }
                        if (_fcmp(Ask, exit_price[i]) >= 0 && freeze[i] == 1) {
                            ObjectSet(name, OBJPROP_COLOR, pointless_color);
                            ObjectSet(name, OBJPROP_LEVELCOLOR, pointless_color);
                            ObjectSet(name, OBJPROP_LEVELWIDTH, 2);
                            ObjectSet(name, OBJPROP_FIBOLEVELS, 2);
                            continue;
                        }
                        if (_fcmp(Bid, entry_price[i] - pending_pips * point) <= 0 && freeze[i] == 1) {
                            ObjectSet(name, OBJPROP_COLOR, pointless_color);
                            ObjectSet(name, OBJPROP_LEVELCOLOR, pointless_color);
                            ObjectSet(name, OBJPROP_LEVELWIDTH, 2);
                            ObjectSet(name, OBJPROP_FIBOLEVELS, 2);
                            type = OP_SELL;
                            price = Bid;
                            stpo_price = exit_price[i] + hidden_pips * point;
                            take_price = entry_price[i] - (desire_rr[i] - 1) * zone_size[i] - hidden_pips * point;
                            temp_send_lot = CalculateDynamicDeltaSwansonLot(price, exit_price[i]);
                            send_trade = true;
                            break;
                        }
                    }
                }
            }
        }
    }
    if (send_trade) {
        while (temp_send_lot > 0) {
            if (temp_send_lot > MarketInfo(symbol, MODE_MAXLOT)) {
                send_lot = MarketInfo(symbol, MODE_MAXLOT);
                temp_send_lot -= MarketInfo(symbol, MODE_MAXLOT);
            } else {
                send_lot = temp_send_lot;
                temp_send_lot = 0;
            }
            if (ticket == 0) {
                ticket = OrderSendReliable(symbol, type, send_lot, price, slippage, stpo_price, take_price, trade_comment, magic_number, 0, CLR_NONE);
            }
            if (ticket != 0) {
                if (type == OP_SELL) {
                    stpo_price -= hidden_pips * Point;
                    take_price += hidden_pips * Point;
                    DrawHiddenTakeProfit(ticket, take_price);
                    DrawHiddenStopLoss(ticket, stpo_price);
                }
                if (type == OP_BUY) {
                    stpo_price += hidden_pips * Point;
                    take_price -= hidden_pips * Point;
                    DrawHiddenTakeProfit(ticket, take_price);
                    DrawHiddenStopLoss(ticket, stpo_price);
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
                    Print("Sell price ", price, " trigger ", trigger, " stop ", stop, " take ", take);
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
                        DrawHiddenTakeProfit(ticket, take + hidden_pips * point);
                        DrawHiddenStopLoss(ticket, trigger);
                    }
                }
                if (trigger < Bid) {
                    Print("Trigger is buy signal");
                    if (Bid - trigger > max_stop * point) {
                        ObjectDelete(name);
                        Print("Error: stop " + (trigger - Ask) + " > " + (max_stop * point) + " max_stop ");
                        return;
                    }
                    type = OP_BUY;
                    price = Ask;
                    stop = trigger - hidden_pips * point;
                    take = price + (price - trigger) * 3 +  hidden_pips * point;
                    temp_send_lot = CalculateDynamicDeltaSwansonLot(price, trigger);
                    Print("Buy price ", price, " trigger ", trigger, " stop ", stop, " take ", take);
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
                        DrawHiddenTakeProfit(ticket, take - hidden_pips * point);
                        DrawHiddenStopLoss(ticket, trigger);
                    }
                }
            }
        }
    }
}

void CountOpenTrades() {
    open_trades = 0;
    ArrayResize(orders, 0);
    if (OrdersTotal() > 0) {
        ArrayResize(orders, OrdersTotal());
        for (int i = OrdersTotal() - 1; i >= 0; i--) {
            if (OrderSelect(i, SELECT_BY_POS)) {
                if (OrderSymbol() == symbol && OrderMagicNumber() == magic_number &&
                        (OrderType() == OP_BUY || OrderType() == OP_SELL)) {
                    open_trades++;
                    orders[i][0] = OrderTicket();
                    orders[i][1] = NormalizeDouble(OrderOpenPrice(), digits);
                    orders[i][2] = NormalizeDouble(OrderStopLoss(), digits);
                    orders[i][3] = NormalizeDouble(OrderTakeProfit(), digits);
                    orders[i][4] = OrderLots();
                }
            }
        }
    } else {
        ArrayResize(orders, 0);
    }
    ArrayResize(orders, open_trades);
}

double CalculateRR() {
    static int total_history;
    static double rr = 1.0;
    int local_multiplier, local_digits;
    if (total_history != OrdersHistoryTotal()) {
        total_history = OrdersHistoryTotal();
        for (int i = 0; i > total_history; i++) {
            if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
                if (OrderType() == 6 || OrderType() == 7) {
                    continue;
                }
                local_digits = MarketInfo(OrderSymbol(), MODE_DIGITS);
                local_multiplier = pip_mult_tab[local_digits];
                double pips_profit = 0.0;
                double pips_loss = 0.0;
                int trades_win = 0;
                int trades_loss = 0;
                if (OrderProfit() > 0) {
                    trades_win++;
                    pips_profit += MathAbs((OrderClosePrice() -
                        OrderOpenPrice()) / MarketInfo(OrderSymbol(),
                        MODE_POINT) / local_multiplier);
                } else if (OrderProfit() < 0) {
                    trades_loss++;
                    pips_loss += MathAbs((OrderClosePrice() -
                        OrderOpenPrice()) / MarketInfo(OrderSymbol(),
                        MODE_POINT) / local_multiplier);
                }
            }
        }
        double average_profit = 0;
        double average_loss = 0;
        if (pips_profit > 0 && trades_win > 0) {
            average_profit = pips_profit / trades_win;
        }
        if (pips_loss > 0 && trades_loss > 0) {
            average_loss = pips_loss / trades_loss;
        }
        if (average_loss > 0 && average_profit > 0) {
            rr = average_loss / average_profit;
        }
    }
    return (rr);
}


//End Indicator module
////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////
//Pending trade price lines module.
void DrawHiddenStopLoss(int ticket, double price) {
    string sl_name = StringConcatenate(ticket, "_sl_line");
    if (ObjectFind(sl_name) == -1) {
        ObjectCreate(sl_name, OBJ_HLINE, 0, Time[0], price);
        ObjectSet(sl_name, OBJPROP_COLOR, supply_color);
        ObjectSet(sl_name, OBJPROP_WIDTH, 1);
        ObjectSet(sl_name, OBJPROP_STYLE, STYLE_SOLID);
    }
}


void DrawHiddenTakeProfit(int ticket, double price) {
    string tp_name = StringConcatenate(ticket, "_tp_line");
    if (ObjectFind(tp_name) == -1) {
        ObjectCreate(tp_name, OBJ_HLINE, 0, Time[0], price);
        ObjectSet(tp_name, OBJPROP_COLOR, demand_color);
        ObjectSet(tp_name, OBJPROP_WIDTH, 1);
        ObjectSet(tp_name, OBJPROP_STYLE, STYLE_SOLID);
    }
}


void DeletePendingPriceLines(int ticket) {
    string tp_name = StringConcatenate(ticket, "_tp_line");
    string sl_name = StringConcatenate(ticket, "_sl_line");
    if (ObjectFind("_sl_line") != -1) {
        ObjectDelete("_sl_line");
    }
    if (ObjectFind("_tp_line") != -1) {
        ObjectDelete("_tp_line");
    }
}

void DeleteOrphanPriceLines() {
    int total_objects = ObjectsTotal();
    int ticket;
    if (total_objects > 0) {
        for (int i = 0; i < total_objects; i++) {
            string name = ObjectName(i);
            if (ObjectType(name) == OBJ_HLINE) {
                string line_name = ObjectName(i);
                int tp_index = StringFind(line_name, "_tp_line", 0);
                int sl_index = StringFind(line_name, "_sl_line", 0);
                if (sl_index != -1) {
                    ticket = StrToInteger(StringSubstr(line_name, 0, sl_index));
                    if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
                        if (OrderCloseTime() != 0) {
                            Print("Found orphan stop line order ticket " + ticket);
                            ObjectDelete(line_name);
                        }
                    }
                }
                if (tp_index != -1) {
                    ticket = StrToInteger(StringSubstr(line_name, 0, tp_index));
                    if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
                        if (OrderCloseTime() != 0) {
                            Print("Found orphan take line order ticket " + ticket);
                            ObjectDelete(line_name);
                        }
                    }
                }
            }
        }
    }
}

bool CheckMarginLevel() {
    if (use_margin_check && AccountMargin() > 0) {
        double ml = NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2);
        if (ml < minimum_margin_percen) {
            //string screen_message = StringConcatenate ( "There is insufficient margin percent to allow trading. ", DoubleToStr ( ml, 2 ), "%" );
            //ObjectMakeLabel ( StringConcatenate ( sd, "margin_level_message" ), screen_message, font_size, font_type, Red, 30, 30, 0, 1 );
            DisplayUserFeedback();
            return (false);
        } else {
            ObjectDelete(StringConcatenate(PREFIX, "_margin_level_message"));
        }
    }
    return (true);
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
    //----
    LookForTradeClosure();
    TrailingStop();
    DragDropLine();
    if (use_sd) {
        GetFibo();
    }
    if (force_trade_closure) {
        CloseAllTrades();
        return (0);
    }
    CountOpenTrades();
    if (CheckMarginLevel()) {
        if (use_sd) {
            SupplyDemandTrading();
        }
        if (use_sas) {
            SasTrading();
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
    string screen_message = StringConcatenate("Supply&Demand semi-auto trading robot by Huxley on ", symbol);
    ObjectMakeLabel(StringConcatenate(PREFIX, "ea_name"), screen_message, font_size * 1.2, "ArialBlack", supply_color, data_disp_gap_size, temp_offset, 0, 0);
    temp_offset += 2 * data_disp_offset;
    double i;
    int m, s, k;
    m = Time[0] + Period() * 60 - CurTime();
    i = m / 60.0;
    s = m % 60;
    m = (m - m % 60) / 60;
    if (magic_number != 0) {
        screen_message = StringConcatenate("Magic number: ", magic_number);
        ObjectMakeLabel(StringConcatenate(PREFIX, "magic_number_message"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
    }
    if (trade_comment != " ") {
        screen_message = StringConcatenate("Trade comment: ", trade_comment);
        ObjectMakeLabel(StringConcatenate(PREFIX, "trade_comment_message"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
    }
    screen_message = StringConcatenate("Max spreed = ", max_spreed, ": Spread = ", MarketInfo(symbol, MODE_SPREAD));
    ObjectMakeLabel(StringConcatenate(PREFIX, "spreed_message"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
    temp_offset += data_disp_offset * 2;
    //if (use_trailing_stop) {
    //    temp_offset += data_disp_offset;
    //    screen_message = "Trailing stop";
    //    ObjectMakeLabel(StringConcatenate(PREFIX, "trailing_stop"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
    //    temp_offset += data_disp_offset;
    //    screen_message = StringConcatenate("Strart from ", start_tp_percent, "%");
    //    ObjectMakeLabel(StringConcatenate(PREFIX, "strart_stop"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
    //    temp_offset += data_disp_offset;
    //    screen_message = StringConcatenate("End on ", stop_tp_percent, "%");
    //    ObjectMakeLabel(StringConcatenate(PREFIX, "stop_stop"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
    //    temp_offset += data_disp_offset;
    //}
    //Running total of trades
    if (use_label_box) {
        //if ( ObjectFind ( "[[LabelBorder]]" ) == -1 ) {
        //ObjectMakeLabel( "[[LabelBorder]]", "c", 210, "Webdings", label_border, 10, 15, 0 );
        //}
        int count = temp_offset / data_disp_offset / 3;
        temp_offset = 20;
        for (int cc = count - 1; cc >= 0; cc--) {
            string name = StringConcatenate("[", PREFIX, "label_box", cc, "]");
            if (ObjectFind(name) == -1) {
                ObjectMakeLabel(name, "ggggggggg", 34, "Webdings", label_box, data_disp_gap_size - (data_disp_gap_size / 2), temp_offset, 0, 0);
            }
            temp_offset += 45;
        }
    }
}
