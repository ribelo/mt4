//+------------------------------------------------------------------+
//|                                            LibOrderReliable4.mqh |
//|                                    Copyright © 2010, Matt Kennel |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, Matt Kennel"
#property link      "http://www.metaquotes.net"


#import "LibOrderReliable4.ex4"
// LibOrderReliable.mq4 should be in your experts/libararies folder
// LibOrderReliable.mqh (this file) should be in your experts/include folder

/*        LibOrderReliable4 BASIC instructions.
 *
 *  To make a given EA more reliable, do the following:
 *     Put this file and LibOrderReliable4.mq4 in the appropriate directories.
 *     Compile LibOrderReliable4.mq4
 *
 *     Add #include <LibOrderReliable4.mqh> to the top of your EA.
 *
 *     Do the following search & replaces in your code:
 *
 *     OrderSend(    -> OrderSendReliable(
 *     OrderModify(  -> OrderModifyReliable(
 *     OrderClose(   -> OrderCloseReliable(
 *     OrderDelete(  -> OrderDeleteReliable(
 *     GetLastError( -> GetLastErrorReliable(
 *
 *  To the init() routine, add a call
 *     O_R_Config_use2step( use2step )
 *  with use2step a bool variable saying whether orders should be placed in 1 step (false) or 2 steps (true)
 *  2step is necessary for many ECN's, and should work even with 1-step broker/dealers, but may be slightly
 *  less reliable in that case.  
 *
 *  More ADVANCED:  check your code and logic to see if you want to use OrderSendReliableMKT versions.
 */



int OrderSendReliable(string symbol, int cmd, double volume, double price,
                         int slippage, double stoploss, double takeprofit,
                         string comment, int magic, datetime expiration = 0,
                        color arrow_color = CLR_NONE);
                        
int OrderSendReliableMKT(string symbol, int cmd, double volume, double price,
                         int slippage, double stoploss, double takeprofit,
                         string comment, int magic, datetime expiration = 0,
                         color arrow_color = CLR_NONE);

int OrderSendReliable1Step(string symbol, int cmd, double volume, double price,
                           int slippage, double stoploss, double takeprofit,
                           string comment, int magic, datetime expiration = 0,
                           color arrow_color = CLR_NONE);

int OrderSendReliable2Step(string symbol, int cmd, double volume, double price,
                           int slippage, double stoploss, double takeprofit,
                           string comment, int magic, datetime expiration = 0,
                           color arrow_color = CLR_NONE);

int OrderSendReliableMKT1Step(string symbol, int cmd, double volume, double price,
                           int slippage, double stoploss, double takeprofit,
                           string comment, int magic, datetime expiration = 0,
                           color arrow_color = CLR_NONE);

int OrderSendReliableMKT2Step(string symbol, int cmd, double volume, double price,
                           int slippage, double stoploss, double takeprofit,
                           string comment, int magic, datetime expiration = 0,
                           color arrow_color = CLR_NONE);
                        
bool OrderModifyReliable(int ticket, double price, double stoploss,
                         double takeprofit, datetime expiration,
                         color arrow_color = CLR_NONE);

bool OrderCloseReliable(int ticket, double volume, double price,
                        int slippage, color arrow_color = CLR_NONE);
                        
bool OrderCloseReliableMKT(int ticket, double volume, double price,
						   int slippage, color arrow_color = CLR_NONE);
						   
bool OrderDeleteReliable(int ticket);

int GetLastErrorReliable();

void O_R_Config_use2step(bool use2step); 

void O_R_Config_UseInBacktest(bool use);

void O_R_Sleep(double mean_time, double max_time);


                        


