#property copyright "Copyright 2014 Huxley"
#property link      "email:   huxley_source@gmail_com"


void UpdateBalanceArray(double& balance_array[]) {
	static int total_history;
	double curr_balance = 0.0;
	if (OrdersHistoryTotal() != total_history) {
		total_history = OrdersHistoryTotal();
		ArrayResize(balance_array, 1);
		if (total_history > 0) {
			for (int i = 0; i < total_history; i++) {
			    if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
                    if (OrderProfit() + OrderCommission() != 0.0) {
                        curr_balance += OrderProfit();
    			        curr_balance += OrderCommission();
                        curr_balance += OrderSwap();
                        ArrayResize(balance_array, ArraySize(balance_array) + 1);
                        balance_array[i] = curr_balance;
                    }
			    }
			}
		}
	}
	if (ArraySize(balance_array) == 0) {
		ArrayResize(balance_array, 1);
		balance_array[0] = AccountBalance();
	}
}


double HighestEq(double& balance_array[], int count = 5) {
	static double highest_eq;
	static int total_history;
	if (OrdersHistoryTotal() != total_history) {
        total_history = OrdersHistoryTotal();
		if (total_history > 0) {
			count = MathMin(total_history, count + 1);
			for (int i = total_history - count - 1; i < total_history - 1; i++) {
                highest_eq = MathMax(highest_eq, balance_array[i]);
			}
		}
	}
	if (highest_eq == 0.0) {
		highest_eq = AccountBalance();
	}
	return (highest_eq);
}


double DrownDownPercent(double& balance_array[], int count = 5) {
	double highest_eq = HighestEq(balance_array, count);
	double diff = highest_eq - balance_array[ArraySize(balance_array) - 1];
	if (highest_eq > 0) {
		return (diff / highest_eq);
	} else {
		return (0.0);
	}
}


double DrownDownCash(double& balance_array[], int count = 5) {
	double highest_eq = HighestEq(balance_array, count);
	return (highest_eq - balance_array[ArraySize(balance_array) - 1]);
}


double DrawDownHighToPeak(int count = 5) {
	static int pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
	static double dd_pip;
	static int total_history;
	double tmp_pip = 0.0;
	if (OrdersHistoryTotal() != total_history) {
		total_history = OrdersHistoryTotal();
		if (total_history > 0) {
			count = MathMin(total_history, count);
			for (int i = total_history - count - 1; i < total_history; i++) {
				if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
					if (OrderType() == 6 || OrderType() == 7) {
						count++;
					}
					if (OrderProfit() < 0) {
						int local_digits = MarketInfo(OrderSymbol(), MODE_DIGITS);
						int local_multiplier = pip_mult_tab[local_digits];
						tmp_pip += MathAbs(OrderOpenPrice() - OrderClosePrice()) / MarketInfo(OrderSymbol(), MODE_POINT) / local_multiplier;
					} else {
						dd_pip = MathMax(dd_pip, tmp_pip);
						tmp_pip = 0.0;
					}
				}
			}
		}
	}
	dd_pip = MathMax(dd_pip, tmp_pip);
	return (dd_pip);
}


double CalculateRR() {
    static int pip_mult_tab[] = {1, 10, 1, 10, 1, 10, 100, 1000};
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


double DynamicDeltaLot(string symbol, double stop_pip, double max_dd, double max_risk, double& balance_array[]) {
    static int total_history;
    static int total_orders;
    static double dd;
    static double min_lot_size;
    static double high_eq;
    static double curr_balance;
    static double average_risk_reward;
    static double lot_size;

    if (total_history != OrdersHistoryTotal() || total_orders != OrdersTotal()) {
	    total_history = OrdersHistoryTotal();
	    total_orders = OrdersTotal();
	    dd = DrawDownHighToPeak();
	    min_lot_size = MarketInfo(symbol, MODE_MINLOT);
	    high_eq = HighestEq(balance_array);
	    curr_balance = balance_array[ArraySize(balance_array) - 1];
	    for (int j = 0; j < ArraySize(balance_array); j++){
	    }
	    average_risk_reward = CalculateRR();

	    if (dd > 0.0) {
	        double delta = dd / 5;
	    } else {
	        delta = stop_pip / 5;
	    }
	    if (delta > 0) {
	        double step1 = curr_balance * max_dd / delta / 100 / MarketInfo(symbol, MODE_TICKVALUE);
	        Print("DDSM step1 ", step1);
	        double step2 = MathMax((curr_balance - high_eq) / delta / 100, 0) / MarketInfo(symbol, MODE_TICKVALUE);
	        Print("DDSM step2 ", step2);
	        double step3 = MathMax((high_eq - curr_balance) / (average_risk_reward * delta) / 100, 0) / MarketInfo(symbol, MODE_TICKVALUE);
	        Print("DDSM step3 ", step3);
	        double lot_delta = (max_dd * curr_balance / delta / 100 + MathMax((curr_balance - high_eq) / delta / 100, 0) - MathMax((high_eq - curr_balance) / (average_risk_reward * delta) / 100, 0)) / MarketInfo(symbol, MODE_TICKVALUE);
	        Print("DDSM lot_delta ", lot_delta);
	        double lot_risk = curr_balance * max_risk / stop_pip / MarketInfo(symbol, MODE_TICKVALUE);
	        Print("DDSM lot_risk ", lot_risk);
	        double lot_max = AccountFreeMargin() / stop_pip / MarketInfo(symbol, MODE_TICKVALUE);
	        Print("DDSM lot_max ", lot_max);
	        lot_size = MathMin(MathMin(MathMin(lot_delta, lot_risk), lot_max), MarketInfo(symbol, MODE_MAXLOT));
	        lot_size = MathFloor(lot_size / MarketInfo(symbol, MODE_LOTSTEP)) * MarketInfo(symbol, MODE_LOTSTEP);
	        lot_size = MathMax(lot_size, MarketInfo(symbol, MODE_MINLOT));
	        Print("DDSM lot_size ", lot_size);
	    }
	}
    return (lot_size);
}
