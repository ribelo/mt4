#property copyright "Copyright Ã‚Â© 2014 Huxley"
#property link      "email:   huxley_source@gmail_com"


void UpdateBalanceArray(double& balance_array[]) {
	static int total_history;
	double curr_balance = 0.0;
	if (OrdersHistoryTotal() != total_history) {
		total_history = OrdersHistoryTotal();
		ArrayResize(balance_array, total_history);
		if (total_history > 0) {
			for (int i = 0; i < total_history; i++) {
			    if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
			        curr_balance += OrderProfit();
			        balance_array[i] = curr_balance;

			    }
			}
		}
	}
}


double CalculateHighestEq(double& balance_array[], int count = 5) {
	static double highest_eq;
	static int total_history;
	if (OrdersHistoryTotal() != total_history) {
		total_history = OrdersHistoryTotal();
		if (total_history > 0) {
			count =  MathMin(total_history, count);
			for (int i = total_history - count - 1; i < total_history; i++) {
				highest_eq = MathMax(highest_eq, balance_array[i]);
			}
		}
	}
	return (highest_eq);
}


double CalculateDrownDownPercent(double& balance_array[], int count = 5) {
	double highest_eq = CalculateHighestEq(balance_array, count);
	double diff = highest_eq - balance_array[ArraySize(balance_array) - 1];
	return diff / highest_eq);
}


double CalculateDrownDownCash(double& balance_array[], int count = 5) {
	double highest_eq = CalculateHighestEq(balance_array, count);
	double diff = highest_eq - balance_array[ArraySize(balance_array) - 1];
	return diff / highest_eq);
}


double CalculateDynamicDeltaLot(double open_price, double stop_price) {
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
        double lot_size = MathMin(MathMin(MathMin(lot_delta, lot_risk), lot_max), MarketInfo(symbol, MODE_MAXLOT));
        lot_size = MathFloor(lot_size / MarketInfo(symbol, MODE_LOTSTEP)) * MarketInfo(symbol, MODE_LOTSTEP);
        lot_size = MathMax(lot_size, MarketInfo(symbol, MODE_MINLOT));
        Print("lot_size ", lot_size);
    }
    return (lot_size);
}
