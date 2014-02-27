//+-------------------------------------------------------------------+
//|                  Just A Rather Very Intelligent System by Huxley  |
//|                                         Copyright   2014, Huxley  |
//+-------------------------------------------------------------------+
#property copyright "Copyright 2014, Huxley"
#include <wrb_analysis.mqh>
#include <hxl_utils.mqh>
#include <hxl_money_management.mqh>
#include <gsl_math.mqh>
#include <LibGMT.mqh>
#include <LibOrderReliable4.mqh>
#include <hanover --- function header (np).mqh>
#include <hanover --- extensible functions (np).mqh>
#define _name "j.a.r.v.i.s"


extern string  gen = "----general inputs----";
extern int     main_timeframe = 0;
extern int     magic_number = 0;
extern string  trade_comment = "";
extern bool    criminal_is_ecn = true;
extern double  max_spreed = 2;
extern int     hidden_pips = 5;
extern double  pending_pips = 5;

extern string  tmm = "----Trade management module----";
extern double  max_stop = 30.0;
extern double  max_dd = 0.2;
extern double  max_risk = 0.04;
extern int     slippage = 3;
extern bool    use_trailing_stop = true;
extern double  move_to_be_at_rr = 1.0;
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
extern color   label_box = C'188,182,167';
extern color   label_border = Black;
extern color   text_color = C'100,77,82';
extern string  font_type = "Cantarell";
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
int            tf, digits, multiplier;
double         tickvalue, point;
string         pip_description = " pips";
bool           force_trade_closure;


//Money Managemet
double balance_array[];

double candle[][6];
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
    //----
    symbol = Symbol();
    if (main_timeframe == 0) {
        tf = Period();
    } else {
        tf = main_timeframe;
    }
    digits = MarketInfo(symbol, MODE_DIGITS);
    multiplier = pip_mult_tab[digits];
    point = MarketInfo(symbol, MODE_POINT);
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
    CountOpenTrades();
    InitTrades();
    PendingToFibo();
    GetFibo();
    UpdateBalanceArray(balance_array);
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
    //FiboToPending();
    if (ObjectsTotal() > 0) {
        for (int i = ObjectsTotal() - 1; i >= 0; i--) {
            string name = ObjectName(i);
            if (StringFind(name, _name) != -1) {
                ObjectDelete(name);
            }
        }
    }
    DeinitTrades();
    //----
    return (0);
}


void timer() {
    while (true) {
        Sleep(250);
        if (IsStopped() || !IsExpertEnabled()) {
            return;
        }
        RefreshRates();
        start();
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////
//TRADE MANAGEMENT MODULE


void InitTrades() {
    double old_stop, new_stop, old_take, new_take;
    for (int i = open_trades - 1; i >= 0; i--) {
        int ticket = orders[i][0];
        if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            if (OrderSymbol() == symbol) {
                if (OrderMagicNumber() == magic_number) {
                    old_stop = NormalizeDouble(OrderStopLoss(), digits);
                    old_take = NormalizeDouble(OrderTakeProfit(), digits);
                    if (OrderType() == OP_BUY) {
                        new_stop = NormalizeDouble(old_stop - hidden_pips * point, digits);
                        new_take = NormalizeDouble(old_take + hidden_pips * point, digits);
                    } else if (OrderType() == OP_SELL) {
                        new_stop = NormalizeDouble(old_stop + hidden_pips * point, digits);
                        new_take = NormalizeDouble(old_take - hidden_pips * point, digits);
                    }
                    OrderModifyReliable(ticket, OrderOpenPrice(), new_stop, new_take, 0, CLR_NONE);
                }
            }
        }
    }
}


void DeinitTrades() {
    double old_stop, new_stop, old_take, new_take;
    for (int i = open_trades - 1; i >= 0; i--) {
        int ticket = orders[i][0];
        if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            if (OrderSymbol() == symbol) {
                if (OrderMagicNumber() == magic_number) {
                    old_stop = NormalizeDouble(OrderStopLoss(), digits);
                    old_take = NormalizeDouble(OrderTakeProfit(), digits);
                    if (OrderType() == OP_BUY) {
                        new_stop = NormalizeDouble(old_stop + hidden_pips * point, digits);
                        new_take = NormalizeDouble(old_take - hidden_pips * point, digits);
                    } else if (OrderType() == OP_SELL) {
                        new_stop = NormalizeDouble(old_stop - hidden_pips * point, digits);
                        new_take = NormalizeDouble(old_take + hidden_pips * point, digits);
                    }
                    OrderModifyReliable(ticket, OrderOpenPrice(), new_stop, new_take, 0, CLR_NONE);
                }
            }
        }
    }
}


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
                            if (_fcmp(old_stop, 0.0) > 0) {
                                Print("Order " + ticket + " sl does not exist, so I create a new one");
                                DrawHiddenStopLoss(ticket, old_stop + hidden_pips * point);
                            }
                        }
                        if (ObjectFind(ticket + "_tp_line") != -1) {
                            if (_fcmp(old_take, new_take) != 0) {
                                Print("Order " + ticket + " tp trigger has been moved so i move tp line");
                                Print("Order " + ticket + " old_take ", old_take," new_take ", new_take, " fcmp ", _fcmp(old_take, new_take));
                                OrderModifyReliable(ticket, OrderOpenPrice(), new_stop, new_take, 0, CLR_NONE);
                            }
                        } else {
                            if (_fcmp(old_take, 0.0) > 0) {
                                Print("Order " + ticket + " tp does not exist, so I create a new one");
                                DrawHiddenTakeProfit(ticket, old_take - hidden_pips * Point);
                            }
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
                            if (_fcmp(old_stop, 0.0) > 0) {
                                Print("Order " + ticket + " sl does not exist, so I create a new one");
                                DrawHiddenStopLoss(ticket, old_stop - hidden_pips * point);
                            }
                        }
                        if (ObjectFind(ticket + "_tp_line") != -1) {
                            if (_fcmp(old_take, new_take) != 0) {
                                Print("Order " + ticket + " tp trigger has been moved so i move tp line");
                                Print("Order " + ticket + " old_take ", old_take," new_take ", new_take, " fcmp ", _fcmp(old_take, new_take));
                                OrderModifyReliable(ticket, OrderOpenPrice(), new_stop, new_take, 0, CLR_NONE);
                            }
                        } else {
                            if (_fcmp(old_take, 0.0) > 0) {
                                Print("Order " + ticket + " tp does not exist, so I create a new one");
                                DrawHiddenTakeProfit(ticket, old_take + hidden_pips * Point);
                            }
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
                    send_lot = DynamicDeltaLot(symbol, MathAbs(entry_price - exit_price), max_dd, max_risk, balance_array);
                    if (_fcmp(_ask(symbol), entry_price) > 0) {
                        type = OP_BUYLIMIT;
                    } else if (_fcmp(_ask(symbol), entry_price) < 0) {
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
                    send_lot = DynamicDeltaLot(symbol, MathAbs(entry_price - exit_price), max_dd, max_risk, balance_array);
                    if (_fcmp(_bid(symbol), entry_price) < 0) {
                        type = OP_SELLLIMIT;
                    } else if (_fcmp(_bid(symbol), entry_price) > 0) {
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
    static int total_orders;
    if (total_orders != OrdersTotal()) {
        total_orders = OrdersTotal();
        for (int i = total_orders - 1; i >=0; i--) {
            OrderSelect(i, MODE_TRADES);
            type = OrderType();
            ticket = OrderTicket();
            string name = "Fibo " + ticket;
            if (type == OP_BUYLIMIT || type == OP_BUYSTOP) {
                entry_price = OrderOpenPrice();
                exit_price = OrderStopLoss();
                desire_price = OrderTakeProfit();
                desire_rr = (desire_price - entry_price) / (entry_price - exit_price);
                if (exit_price > 0 && desire_price > 0) {
                    ObjectCreate(name, OBJ_FIBO, 0, iTime(symbol, tf, 10),
                                 entry_price, iTime(symbol, tf, 0), exit_price);
                    ObjectSet(name, OBJPROP_FIBOLEVELS, 3);
                    ObjectSet(name, OBJPROP_FIRSTLEVEL, 0);
                    ObjectSet(name, OBJPROP_FIRSTLEVEL + 1, 1);
                    ObjectSet(name, OBJPROP_FIRSTLEVEL + 2, desire_rr + 1);
                    ObjectSet(name, OBJPROP_COLOR, demand_color);
                    OrderDeleteReliable(ticket);
                }
            } else if (type == OP_SELLLIMIT || type == OP_SELLSTOP) {
                entry_price = OrderOpenPrice();
                exit_price = OrderStopLoss();
                desire_price = OrderTakeProfit();
                desire_rr = (entry_price - desire_price) / (exit_price - entry_price);
                if (exit_price > 0 && desire_price > 0) {
                    ObjectCreate(name, OBJ_FIBO, 0, iTime(symbol, tf, 10),
                                 entry_price, iTime(symbol, tf, 0), exit_price);
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
}


double Support() {
    static int last_time;
    static double support;
    if (last_time != iTime(symbol, tf, 0)) {
        last_time = iTime(symbol, tf, 0);
        support = _support(candle, 1, true, 1, 5, iBars(symbol, tf));
    }
    return (support);
}

double Resistance() {
    static int last_time;
    static double resistance;
    if (last_time != iTime(symbol, tf, 0)) {
        last_time = iTime(symbol, tf, 0);
        resistance = _resistance(candle, 1, true, 1, 5, iBars(symbol, tf));
    }
    return (resistance);
}

void TrailingStop() {
    double support, resistance, old_sl_price, new_sl_price, be_trigger, commission_pip;
    string sl_name;
    for (int i = open_trades - 1; i >= 0; i--) {
        int ticket = orders[i][0];
        if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            if (OrderSymbol() == symbol) {
                if (OrderMagicNumber() == magic_number) {
                    support = Support();
                    resistance = Resistance();
                    sl_name = StringConcatenate(ticket, "_sl_line");
                    old_sl_price = NormalizeDouble(ObjectGet(sl_name, OBJPROP_PRICE1), digits);
                    commission_pip = MathAbs(OrderCommission() + OrderSwap()) / MarketInfo(symbol, MODE_TICKVALUE) * OrderLots();
                    if (OrderType() == OP_BUY) {
                        if (old_sl_price < OrderOpenPrice() && move_to_be_at_rr > 0) {
                            be_trigger = OrderOpenPrice() + commission_pip + (OrderOpenPrice() - old_sl_price) * move_to_be_at_rr;
                            new_sl_price = MathMax(be_trigger, support);
                        } else {
                            new_sl_price = support;
                        }
                        if (_fcmp(old_sl_price, support) < 0 && new_sl_price != 0.0) {
                            ObjectMove(sl_name, 0, iTime(symbol, tf, 0), new_sl_price);
                            Print("Order " + ticket + " trailing stop move sl line to ", new_sl_price);
                        }
                    } else if (OrderType() == OP_SELL) {
                        if (old_sl_price > OrderOpenPrice() && move_to_be_at_rr > 0) {
                            be_trigger = OrderOpenPrice() - commission_pip - (old_sl_price - OrderOpenPrice()) * move_to_be_at_rr;
                            new_sl_price = MathMin(be_trigger, resistance);
                        } else {
                            new_sl_price = resistance;
                        }
                        if (_fcmp(old_sl_price, new_sl_price) > 0 && new_sl_price != 0.0) {
                            ObjectMove(sl_name, 0, iTime(symbol, tf, 0), new_sl_price);
                            Print("Order " + ticket + " trailing stop move sl line to ", new_sl_price);
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
                    double take = NormalizeDouble(ObjectGet(ticket + "_tp_line",
                                                  OBJPROP_PRICE1), digits);
                    double stop = NormalizeDouble(ObjectGet(ticket + "_sl_line",
                                                  OBJPROP_PRICE1), digits);
                    if (OrderType() == OP_BUY) {
                        if (_ask(symbol) >= take && take > 0) {
                            OrderCloseReliable(ticket, OrderLots(),
                                               OrderClosePrice(), 1000, CLR_NONE);
                            SendNotification(ticket + " order close at tp with profit " +
                                             DoubleToStr(OrderProfit() + OrderCommission() +
                                             OrderSwap(), 2));
                        }
                        if (_bid(symbol) <= stop && stop > 0) {
                            OrderCloseReliable(ticket, OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
                            SendNotification(ticket + " order close at sl with profit " +
                                             DoubleToStr(OrderProfit() + OrderCommission() +
                                             OrderSwap(), 2));
                        }
                    }
                    if (OrderType() == OP_SELL) {
                        if (_bid(symbol) <= take && take > 0) {
                            OrderCloseReliable(ticket, OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
                            SendNotification(ticket + " order close at tp with profit " +
                                             DoubleToStr(OrderProfit() + OrderCommission() +
                                             OrderSwap(), 2));
                        }
                        if (_ask(symbol) >= stop && stop > 0) {
                            OrderCloseReliable(ticket, OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
                            SendNotification(ticket + " order close at sl with profit " +
                                             DoubleToStr(OrderProfit() + OrderCommission() +
                                             OrderSwap(), 2));
                        }
                    }
                }
            }
        }
    }
}

bool IsTradingAllowed() {
    if (MarketInfo(symbol, MODE_SPREAD) > max_spreed) {
        return (false);
    }
    if (!CheckMarginLevel()) {
        return (false);
    }
    return (true);
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
                                ObjectCreate(label_name, OBJ_TEXT, 0, iTime(symbol, tf, 0), label_price);
                            }
                            ObjectSetText(label_name, text_color, info_text_size, font_type, demand_color);
                            ObjectSet(label_name, OBJPROP_PRICE1, label_price);
                            ObjectSet(label_name, OBJPROP_TIME1, iTime(symbol, tf, 0));
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
                                ObjectCreate(label_name, OBJ_TEXT, 0, iTime(symbol, tf, 0), label_price);
                            }
                            ObjectSetText(label_name, text_color, info_text_size, font_type, supply_color);
                            ObjectSet(label_name, OBJPROP_PRICE1, label_price);
                            ObjectSet(label_name, OBJPROP_TIME1, iTime(symbol, tf, 0));
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
    static double entry_price[], exit_price[], desire_rr[], zone_size[];
    static bool freeze[];
    static int total_objects;
    double price, stpo_price, take_price, lot_size;
    string name;
    int type, ticket;
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
                        if (_fcmp(_ask(symbol), entry_price[i]) <= 0 &&
                                _fcmp(_bid(symbol), exit_price[i]) >= 0 &&
                                freeze[i] == 0) {
                            freeze[i] = 1;
                            SendNotification("Price enter demand zone " + name);
                        }
                        if (_fcmp(_bid(symbol), exit_price[i]) <= 0 && freeze[i] == 1) {
                            ObjectSet(name, OBJPROP_COLOR, pointless_color);
                            ObjectSet(name, OBJPROP_LEVELCOLOR, pointless_color);
                            ObjectSet(name, OBJPROP_LEVELWIDTH, 2);
                            ObjectSet(name, OBJPROP_FIBOLEVELS, 2);
                            SendNotification("Price broke through demand zone " + name);
                            continue;
                        }
                        if (_fcmp(_ask(symbol), entry_price[i] + pending_pips * point) >= 0 && freeze[i] == 1) {
                            if (ObjectSet(name, OBJPROP_COLOR, pointless_color)) {
                                ObjectSet(name, OBJPROP_LEVELCOLOR, pointless_color);
                                ObjectSet(name, OBJPROP_LEVELWIDTH, 2);
                                ObjectSet(name, OBJPROP_FIBOLEVELS, 2);
                                type = OP_BUY;
                                price = NormalizeDouble(MarketInfo(symbol, MODE_ASK), MarketInfo(symbol, MODE_DIGITS));
                                stpo_price = exit_price[i] - hidden_pips * point;
                                take_price = entry_price[i] + (desire_rr[i] - 1) * zone_size[i] + hidden_pips * point;
                                lot_size = DynamicDeltaLot(symbol, MathAbs(price - exit_price[i]), max_dd, max_risk, balance_array);
                                ticket = OrderSendReliableMKT(symbol, type, lot_size, price, slippage, stpo_price, take_price, trade_comment, magic_number, 0, CLR_NONE);
                                SendNotification("Demand zone fired buy order " + name);
                            }
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

                        if (_fcmp(_ask(symbol), entry_price[i]) <= 0 &&
                                _fcmp(_bid(symbol), exit_price[i]) >= 0 &&
                                freeze[i] == 0) {
                            freeze[i] = 1;
                            SendNotification("Price enter supply zone " + name);
                        }
                        if (_fcmp(_ask(symbol), exit_price[i]) >= 0 && freeze[i] == 1) {
                            ObjectSet(name, OBJPROP_COLOR, pointless_color);
                            ObjectSet(name, OBJPROP_LEVELCOLOR, pointless_color);
                            ObjectSet(name, OBJPROP_LEVELWIDTH, 2);
                            ObjectSet(name, OBJPROP_FIBOLEVELS, 2);
                            SendNotification("Price broke through supply zone " + name);
                            continue;
                        }
                        if (_fcmp(_bid(symbol), entry_price[i] - pending_pips * point) <= 0 && freeze[i] == 1) {
                            if (ObjectSet(name, OBJPROP_COLOR, pointless_color)) {
                                ObjectSet(name, OBJPROP_LEVELCOLOR, pointless_color);
                                ObjectSet(name, OBJPROP_LEVELWIDTH, 2);
                                ObjectSet(name, OBJPROP_FIBOLEVELS, 2);
                                type = OP_SELL;
                                price = _bid(symbol);
                                stpo_price = exit_price[i] + hidden_pips * point;
                                take_price = entry_price[i] - (desire_rr[i] - 1) * zone_size[i] - hidden_pips * point;
                                lot_size = DynamicDeltaLot(symbol, MathAbs(price - exit_price[i]), max_dd, max_risk, balance_array);
                                ticket = OrderSendReliableMKT(symbol, type, lot_size, price, slippage, stpo_price, take_price, trade_comment, magic_number, 0, CLR_NONE);
                                SendNotification("Supply zone fired sell order " + name);
                            }
                            break;
                        }
                    }
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
                if (trigger > _ask(symbol)) {
                    Print("Trigger is sell signal");
                    if (trigger - _ask(symbol) > max_stop * point && max_stop > 0) {
                        ObjectDelete(name);
                        Print("Error: stop " + (trigger - _ask(symbol)) + " > " + (max_stop * point) + " max_stop ");
                        Print(max_stop);
                        Print(point);
                        Print(trigger - _ask(symbol) > max_stop * point);
                        return;
                    }
                    type = OP_SELL;
                    price = _bid(symbol);
                    stop = trigger + hidden_pips * point;
                    take = price - (trigger - price) * 3 - hidden_pips * point;
                    temp_send_lot = DynamicDeltaLot(symbol, MathAbs(price - trigger), max_dd, max_risk, balance_array);
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
                                ticket = OrderSendReliableMKT(symbol, type, send_lot, price, slippage, stop, take, trade_comment, temp_magic_number, 0, CLR_NONE);
                            }
                        }
                    }
                    if (ticket != 0) {
                        ObjectDelete(name);
                        DrawHiddenTakeProfit(ticket, take + hidden_pips * point);
                        DrawHiddenStopLoss(ticket, trigger);
                    }
                }
                if (trigger < _bid(symbol)) {
                    Print("Trigger is buy signal");
                    if (_bid(symbol) - trigger > max_stop * point) {
                        ObjectDelete(name);
                        Print("Error: stop " + (trigger - _ask(symbol)) + " > " + (max_stop * point) + " max_stop ");
                        return;
                    }
                    type = OP_BUY;
                    price = _ask(symbol);
                    stop = trigger - hidden_pips * point;
                    take = price + (price - trigger) * 3 +  hidden_pips * point;
                    temp_send_lot = DynamicDeltaLot(symbol, MathAbs(price - trigger), max_dd, max_risk, balance_array);
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
                                ticket = OrderSendReliableMKT(symbol, type, send_lot, price, slippage, stop, take, trade_comment, temp_magic_number, 0, CLR_NONE);
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


//End Indicator module
////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////
//Pending trade price lines module.
void DrawHiddenStopLoss(int ticket, double price) {
    string sl_name = StringConcatenate(ticket, "_sl_line");
    if (ObjectFind(sl_name) == -1) {
        ObjectCreate(sl_name, OBJ_HLINE, 0, iTime(symbol, tf, 0), price);
        ObjectSet(sl_name, OBJPROP_COLOR, supply_color);
        ObjectSet(sl_name, OBJPROP_WIDTH, 1);
        ObjectSet(sl_name, OBJPROP_STYLE, STYLE_SOLID);
    }
}


void DrawHiddenTakeProfit(int ticket, double price) {
    string tp_name = StringConcatenate(ticket, "_tp_line");
    if (ObjectFind(tp_name) == -1) {
        ObjectCreate(tp_name, OBJ_HLINE, 0, iTime(symbol, tf, 0), price);
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
            ObjectDelete(StringConcatenate(_name, "_margin_level_message"));
        }
    }
    return (true);
}

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
    string screen_message = StringUpper(_name + "   " + symbol + "   " + TFToStr(main_timeframe));
    ObjectMakeLabel(StringConcatenate(_name, "_ea_name"), screen_message, font_size * 1.2, "Cantarell Bold", supply_color, data_disp_gap_size, temp_offset, 0, 0);
    temp_offset += 2 * data_disp_offset;
    double i;
    int m, s, k;
    m = iTime(symbol, tf, 0) + Period() * 60 - CurTime();
    i = m / 60.0;
    s = m % 60;
    m = (m - m % 60) / 60;
    if (magic_number != 0) {
        screen_message = StringConcatenate("Magic number: ", magic_number);
        ObjectMakeLabel(StringConcatenate(_name, "_magic_number_message"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
    }
    if (trade_comment != " ") {
        screen_message = StringConcatenate("Trade comment: ", trade_comment);
        ObjectMakeLabel(StringConcatenate(_name, "_trade_comment_message"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
        temp_offset += data_disp_offset;
    }
    screen_message = "Money Management:";
    ObjectMakeLabel(StringConcatenate(_name, "_money_management"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
    temp_offset += data_disp_offset;
    screen_message = StringConcatenate("    Risk Reward: ", DoubleToStr(RiskReward(), 2));
    ObjectMakeLabel(StringConcatenate(_name, "_risk_reward"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
    temp_offset += data_disp_offset;
    screen_message = StringConcatenate("    Profitability: ", DoubleToStr(Profitability(), 2));
    ObjectMakeLabel(StringConcatenate(_name, "_profitability"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
    temp_offset += data_disp_offset;
    screen_message = StringConcatenate("    Drown Down: ", DoubleToStr(DrawDownHighToPeak(), 0));
    ObjectMakeLabel(StringConcatenate(_name, "_drown_down"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
    temp_offset += data_disp_offset;
    screen_message = StringConcatenate("    Max Lot: ", DynamicDeltaLot(symbol, max_stop, max_dd, max_risk, balance_array));
    ObjectMakeLabel(StringConcatenate(_name, "_max_lot"), screen_message, font_size, font_type, text_color, data_disp_gap_size, temp_offset, 0, 0);
    temp_offset += data_disp_offset * 2;

    //Running total of trades
    if (use_label_box) {
        //if ( ObjectFind ( "[[LabelBorder]]" ) == -1 ) {
        //ObjectMakeLabel( "[[LabelBorder]]", "c", 210, "Webdings", label_border, 10, 15, 0 );
        //}
        int count = temp_offset / data_disp_offset / 3;
        temp_offset = 20;
        for (int cc = count - 1; cc >= 0; cc--) {
            string name = StringConcatenate("[", _name, "label_box", cc, "]");
            if (ObjectFind(name) == -1) {
                ObjectMakeLabel(name, "ggggg", 30, "Webdings", label_box, data_disp_gap_size - (data_disp_gap_size / 2), temp_offset, 0, 0);
            }
            temp_offset += 40;
        }
    }
}

int start() {
    //----
    UpdateBalanceArray(balance_array);
    CountOpenTrades();
    LookForTradeClosure();
    PendingToFibo();
    TrailingStop();
    DragDropLine();
    GetFibo();
    if (IsTradeAllowed()) {
        SupplyDemandTrading();
        SasTrading();
    }
    DeleteOrphanPriceLines();
    DisplayUserFeedback();
    //----
    return (0);
}
