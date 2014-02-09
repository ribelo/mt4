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
