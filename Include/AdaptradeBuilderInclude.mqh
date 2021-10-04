//+------------------------------------------------------------------+
//|                                      AdaptradeBuilderInclude.mqh |
//|                       Copyright © 2012 - 2014 Adaptrade Software |
//|                                         http://www.Adaptrade.com |
//+------------------------------------------------------------------+
#property copyright   "2014, Adaptrade Software"
#property link        "http://www.Adaptrade.com"

#define NEARZERO 0.000001    // Zero-comparison value for doubles
#define MAXORDERS 50         // Maximum size for trade positions arrays

#import "stdlib.ex4"
   string ErrorDescription(int error_code);
#import

#import "AdaptradeBuilderLib.ex4"
   int TimeHHMM(int iShift);
   double DayOpen();
   double DayHigh();
   double DayLow();
   double DayClose();
   double TotalProfit(string symbol, int StratOrderID);
   double LargestLoss(string symbol, int StratOrderID, double SharesPerLot);
   int TradeEntries(string symbol, int StratOrderID, int iShift);
   double tanh(double x);
#import

// Global variables for current open position; should only have 1 open trade at a time for symbol/strategy
int OpenTicket;                  // Order ticket number for current open trade
double OpenEntryPrice;           // Entry price of current open trade
datetime OpenEntryTime;          // Entry time of current open trade
double OpenStopPrice;            // Stop price of current open trade
double OpenTargetPrice;          // Target (take profit) price of current open trade
double OpenLots;                 // Lot size for current open trade
int NLongOrders, NShortOrders;   // Number of current open long, short trades

// Global variables for current pending orders; used to cancel pending orders after 1 bar
int NPending = 0;                // Number of pending orders
int PendingTicket[MAXORDERS];    // Ticket numbers for pending orders
datetime PendingTime[MAXORDERS]; // Bar times pending orders were placed

//----------------------------------------------------------------------------------------------------
// Function to ensure that only one position is open at a time
//----------------------------------------------------------------------------------------------------

void ManageOrders(string symbol, int StratOrderID, double Slippage)
//
// This function manages the current orders for pending trades, as well as for open positions.
// It is designed to ensure that only one trade is open at a time for the given symbol
// and strategy and that orders remain in effect for only one bar. If more than one trade is open in 
// either direction (long, short), it closes all but the most recent. If both long and short trades 
// are open, it closes the oldest trade. After execution, only one trade should be open. If any trade 
// was not successfully closed, it should be picked up and closed on the next call. 
//   Pending orders (stop and limit entries) are also tracked here. The ticket number and bar time at
// which the order was placed are stored in global variables. Whenever a new pending order is detected,
// the time of placement is recorded. Any pending orders that are still open after 1 bar are deleted.
// 
// This function should be called on every tick.
// 
{    
    int LongTickets[MAXORDERS], ShortTickets[MAXORDERS];          // Order ticket numbers for current open long, short trades
    double LongOpenPrices[MAXORDERS], ShortOpenPrices[MAXORDERS]; // Open prices for current long, short trades
    datetime LongOpenTimes[MAXORDERS], ShortOpenTimes[MAXORDERS]; // Open times for current long, short trades
    double LongStopPrices[MAXORDERS], ShortStopPrices[MAXORDERS]; // Stop prices for current long, short trades
    double LongTargPrices[MAXORDERS], ShortTargPrices[MAXORDERS]; // Target (take-profit) prices for current long, short trades
    double LongSizes[MAXORDERS], ShortSizes[MAXORDERS];           // Lot sizes for current open long, short trades
    
    int LongTicket, ShortTicket;     // Order ticket number for current open long, short trades
    double LongLots, ShortLots;      // Lot size for current open long, short trades

    NLongOrders = 0;
    NShortOrders = 0;
    
    // Find and store data for all current open trades and record pending orders with their times of placement
    int NewNPend = 0;                // Number of pending orders
    int NewPendTicket[MAXORDERS];    // Ticket numbers for pending orders
    datetime NewPendTime[MAXORDERS]; // Bar times pending orders were placed
    int j;
    bool Found;
    
    for (int i = 0; i < OrdersTotal(); i++) {
       if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
           if (OrderSymbol() == symbol && OrderMagicNumber() == StratOrderID) {
               if (OrderType() == OP_BUY) {
                   LongTickets[NLongOrders] = OrderTicket();
                   LongOpenPrices[NLongOrders] = OrderOpenPrice();
                   LongOpenTimes[NLongOrders] = OrderOpenTime();
                   LongStopPrices[NLongOrders] = OrderStopLoss();
                   LongTargPrices[NLongOrders] = OrderTakeProfit();
                   LongSizes[NLongOrders] = OrderLots();
                   NLongOrders++;
               }
               else if (OrderType() == OP_SELL) {
                   ShortTickets[NShortOrders] = OrderTicket();
                   ShortOpenPrices[NShortOrders] = OrderOpenPrice();
                   ShortOpenTimes[NLongOrders] = OrderOpenTime();
                   ShortStopPrices[NShortOrders] = OrderStopLoss();
                   ShortTargPrices[NShortOrders] = OrderTakeProfit();
                   ShortSizes[NShortOrders] = OrderLots();
                   NShortOrders++;
               }
               else {
                   NewPendTicket[NewNPend] = OrderTicket();
                   
                   // Look for order in global array of pending orders
                   j = 0;
                   Found = false;
                   while (j < NPending && !Found) {
                       if (NewPendTicket[NewNPend] == PendingTicket[j])
                           Found = true;
                       else
                           j++;
                   }
                   if (Found)
                       NewPendTime[NewNPend] = PendingTime[j];   // Retain order placement time
                   else
                       NewPendTime[NewNPend] = Time[0];          // Order placement time for new order
                       
                   NewNPend++;
               }
           }
       }
    }
    
    // Copy current pending orders to global arrays
    ArrayCopy(PendingTicket, NewPendTicket);
    ArrayCopy(PendingTime, NewPendTime);
    NPending = NewNPend;
        
    // Delete any pending order if they've been open for 1 bar or more
    for (i = 0; i < NPending; i++) {
        if (Time[0] > PendingTime[i]) {
            if (!OrderDelete(PendingTicket[i])) {
                string err = ErrorDescription(GetLastError());
                Alert("Order ", PendingTicket[i], " could not be deleted: ", err);
                Print("Order ", PendingTicket[i], " could not be deleted: ", err);
            }
        }
    }

    // Close all long trades but most recent
    if (NLongOrders > 1) {
        for (i = 0; i < NLongOrders - 1; i++) {
            OpenTicket = LongTickets[i];
            OpenLots = LongSizes[i];
            ExitLongMarket(Slippage);
        }
    }
    
    // Record most recent long trade; should be only one open
    if (NLongOrders > 0) {
        LongTicket = LongTickets[NLongOrders - 1];
        LongLots = LongSizes[NLongOrders - 1];
    }
    
    // Close all short trades but most recent
    if (NShortOrders > 1) {
        for (i = 0; i < NShortOrders - 1; i++) {
            OpenTicket = ShortTickets[i];
            OpenLots = ShortSizes[i];
            ExitShortMarket(Slippage);
        }
    }
    
    // Record most recent short trade; should be only one open
    if (NShortOrders > 0) {
        ShortTicket = ShortTickets[NShortOrders - 1];
        ShortLots = ShortSizes[NShortOrders - 1];
    }
    
    // If there is both a long trade and a short trade open, close the first one that was opened
    if (NLongOrders > 0 && NShortOrders > 0) {
        if (LongTicket < ShortTicket) {            // Select order for long trade and close it
            OpenTicket = LongTicket;
            OpenLots = LongLots;
            ExitLongMarket(Slippage);
            NLongOrders = 0;
        }
        else  {                                    // Select order for short trade and close it
            OpenTicket = ShortTicket;
            OpenLots = ShortLots;
            ExitShortMarket(Slippage);
            NShortOrders = 0;
        }
    }
    
    // Store trade info for open trade, if any
    if (NLongOrders > 0) {  // Current open position is long, so select long trade info
        OpenTicket = LongTickets[NLongOrders - 1];
        OpenEntryPrice = LongOpenPrices[NLongOrders - 1];
        OpenEntryTime = LongOpenTimes[NLongOrders - 1];
        OpenStopPrice = LongStopPrices[NLongOrders - 1];
        OpenTargetPrice = LongTargPrices[NLongOrders - 1];
        OpenLots = LongSizes[NLongOrders - 1];
        NLongOrders = 1;
    }
    else if (NShortOrders > 0) {  // Current open position is short, so select short trade info
        OpenTicket = ShortTickets[NShortOrders - 1];
        OpenEntryPrice = ShortOpenPrices[NShortOrders - 1];
        OpenEntryTime = ShortOpenTimes[NShortOrders - 1];
        OpenStopPrice = ShortStopPrices[NShortOrders - 1];
        OpenTargetPrice = ShortTargPrices[NShortOrders - 1];
        OpenLots = ShortSizes[NShortOrders - 1];
        NShortOrders = 1;
    }
}

//----------------------------------------------------------------------------------------------------
// Function to return the direction of the current open position, if any
//----------------------------------------------------------------------------------------------------

int CurrentPosition()
//
// Use current open trade data, set in AdjustPositions, to determine the current open position.
// Returns: 0 - flat, no position
//          1 - long position
//         -1 - short position
// This assumes only one position is open at a time for the current symbol and strategy.
//
{
    int Pos;

    if (NLongOrders > 0)
        Pos = 1;
    else if (NShortOrders > 0)
        Pos = -1;
    else
        Pos = 0;
    
    return (Pos);
}

//----------------------------------------------------------------------------------------------------
// Functions to place entry orders
//----------------------------------------------------------------------------------------------------

void EnterLongMarket(string symbol, double Lots, double InitialStop, int MarketPosition, 
                     double Slippage, int StratOrderID)
{
    double StopPrice = 0;
    
    if (InitialStop > NEARZERO)
        StopPrice = Ask - InitialStop;
        
    if (MarketPosition < 0)
        ExitShortMarket(Slippage);  // Close short position before going long
        
    if (MarketPosition != 1) {      // Only buy if not already long
        if (OrderSend(symbol, OP_BUY, Lots, Ask, Slippage, StopPrice, 0, "EnMark-L", StratOrderID, 0, Blue) < 0) {
            string err = ErrorDescription(GetLastError());
            Alert("Long entry order at market could not be placed: ", err);
            Print("Long entry order at market could not be placed: ", err);
        }
    }
}

void EnterShortMarket(string symbol, double Lots, double InitialStop, int MarketPosition,
                      double Slippage, int StratOrderID)
{
    double StopPrice = 0;
    
    if (InitialStop > NEARZERO)
        StopPrice = Ask + InitialStop;
        
    if (MarketPosition > 0)
        ExitLongMarket(Slippage);    // Close long position before going short
        
    if (MarketPosition != -1) {      // Only sell if not already short
        if (OrderSend(symbol, OP_SELL, Lots, Bid, Slippage, StopPrice, 0, "EnMark-S", StratOrderID, 0, Red) < 0) {
            string err = ErrorDescription(GetLastError());
            Alert("Short entry order at market could not be placed: ", err);
            Print("Short entry order at market could not be placed: ", err);
        }
    }
}

void EnterLongStop(string symbol, double Lots, double InitialStop, int MarketPosition,
                   double EntPrL, double Slippage, int StratOrderID)
{
    double StopPrice = 0;
    
    if (InitialStop > NEARZERO)
        StopPrice = EntPrL - InitialStop;
                
    if (MarketPosition != 1) {      // Only buy this bar if not already long
        
        double MinDist = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT);
        double HighPrice = MarketInfo(symbol, MODE_ASK);
        
        if (EntPrL - HighPrice <= MinDist) { // Place it as a market order if stop price is already near or below market
            EnterLongMarket(symbol, Lots, InitialStop, MarketPosition, Slippage, StratOrderID);
            Print("Long stop entry placed as market order. EntPrL = ", EntPrL, " HighPrice = ", HighPrice, " MinDist = ", MinDist);
        }
        else if (OrderSend(symbol, OP_BUYSTOP, Lots, EntPrL, Slippage, StopPrice, 0, "EnStop-L", StratOrderID, 0, Blue) < 0) {
            string err = ErrorDescription(GetLastError());
            Alert("Long stop entry order at ", EntPrL, " could not be placed: ", err);
            Print("Long stop entry order at ", EntPrL, " could not be placed: ", err);
        }
    }
}

void EnterShortStop(string symbol, double Lots, double InitialStop, int MarketPosition,
                    double EntPrS, double Slippage, int StratOrderID)
{
    double StopPrice = 0;
    
    if (InitialStop > NEARZERO)
        StopPrice = EntPrS + InitialStop;
            
    if (MarketPosition != -1) {      // Only sell this bar if not already short
    
        double MinDist = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT);
        double LowPrice = MarketInfo(symbol, MODE_BID);
        
        if (LowPrice - EntPrS <= MinDist) {  // Place it as a market order if stop price is already near or above market
            EnterShortMarket(symbol, Lots, InitialStop, MarketPosition, Slippage, StratOrderID);
            Print("Short stop entry placed as market order. EntPrS = ", EntPrS, " LowPrice = ", LowPrice, " MinDist = ", MinDist);
        }
        else if (OrderSend(symbol, OP_SELLSTOP, Lots, EntPrS, Slippage, StopPrice, 0, "EnStop-S", StratOrderID, 0, Red) < 0) {
            string err = ErrorDescription(GetLastError());
            Alert("Short stop entry order at ", EntPrS, " could not be placed: ", err);
            Print("Short stop entry order at ", EntPrS, " could not be placed: ", err);
        }
    }
}

void EnterLongLimit(string symbol, double Lots, double InitialStop, int MarketPosition,
                    double EntPrL, double Slippage, int StratOrderID)
{
    double StopPrice = 0;
    
    if (InitialStop > NEARZERO)
        StopPrice = EntPrL - InitialStop;
                   
    if (MarketPosition != 1) {      // Only buy this bar if not already long
    
        double MinDist = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT);
        double LowPrice = MarketInfo(symbol, MODE_BID);
    
        if (LowPrice - EntPrL <= MinDist) {   // Place it as a market order if limit price is already near or above market
            EnterLongMarket(symbol, Lots, InitialStop, MarketPosition, Slippage, StratOrderID);
        }
        else if (OrderSend(symbol, OP_BUYLIMIT, Lots, EntPrL, Slippage, StopPrice, 0, "EnLimit-L", StratOrderID, 0, Blue) < 0) {
            string err = ErrorDescription(GetLastError());
            Alert("Long limit entry order at ", EntPrL, " could not be placed: ", err);
            Print("Long limit entry order at ", EntPrL, " could not be placed: ", err);
        }
    }
}

void EnterShortLimit(string symbol, double Lots, double InitialStop, int MarketPosition,
                     double EntPrS, double Slippage, int StratOrderID)
{
    double StopPrice = 0;
    
    if (InitialStop > NEARZERO)
        StopPrice = EntPrS + InitialStop;
                
    if (MarketPosition != -1) {      // Only sell this bar if not already short
    
        double MinDist = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT);
        double HighPrice = MarketInfo(symbol, MODE_ASK);
        
        if (EntPrS - HighPrice <= MinDist) {   // Place it as a market order if limit price is already near or below market
            Print("Short limit entry placed as market order. EntPrs = ", EntPrS, " HighPrice = ", HighPrice, " MinDist = ", MinDist);
            EnterShortMarket(symbol, Lots, InitialStop, MarketPosition, Slippage, StratOrderID);
        }
        else if (OrderSend(symbol, OP_SELLLIMIT, Lots, EntPrS, Slippage, StopPrice, 0, "EnLimit-S", StratOrderID, 0, Red) < 0) {
            string err = ErrorDescription(GetLastError());
            Alert("Short limit entry order at ", EntPrS, " could not be placed: ", err);
            Print("Short limit entry order at ", EntPrS, " could not be placed: ", err);
        }
    }
}

//----------------------------------------------------------------------------------------------------
// Functions to place exit orders.
//----------------------------------------------------------------------------------------------------

void ExitLongMarket(double Slippage)
{
    if (!OrderClose(OpenTicket, OpenLots, Bid, Slippage, White)) {
        string err = ErrorDescription(GetLastError());
        Alert("Market exit order for long trade could not be placed: ", err);
        Print("Market exit order for long trade could not be placed: ", err);
    }
}

void ExitShortMarket(double Slippage)
{
    if (!OrderClose(OpenTicket, OpenLots, Ask, Slippage, White)) {
        string err = ErrorDescription(GetLastError());
        Alert("Market exit order for short trade could not be placed: ", err);
        Print("Market exit order for short trade could not be placed: ", err);
    }
}

void PlaceLongStop(string symbol, double LongStop, double Slippage)
{    
    if (MathAbs(LongStop - OpenStopPrice) > NEARZERO) {
    
        double MinDist = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT);
        double LowPrice = MarketInfo(symbol, MODE_BID);
        
        if (LowPrice - LongStop <= MinDist) {       // Exit at market if market is already near or below stop price
            ExitLongMarket(Slippage);
        }
        else if (!OrderModify(OpenTicket, OpenEntryPrice, LongStop, OpenTargetPrice, 0, Blue)) {
            string err = ErrorDescription(GetLastError());
            Alert("Exit stop order at ", LongStop, " for long trade could not be placed: ", err);
            Print("Exit stop order at ", LongStop, " for long trade could not be placed: ", err);
        }
    }   
}

void PlaceShortStop(string symbol, double ShortStop, double Slippage)
{        
    if (MathAbs(ShortStop - OpenStopPrice) > NEARZERO) {
    
        double MinDist = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT);
        double HighPrice = MarketInfo(symbol, MODE_ASK);
        
        if (ShortStop - HighPrice <= MinDist) {     // Exit at market if market is already near or above stop price 
            ExitShortMarket(Slippage);
        }
        else if (!OrderModify(OpenTicket, OpenEntryPrice, ShortStop, OpenTargetPrice, 0, Red)) {
            string err = ErrorDescription(GetLastError());
            Alert("Exit stop order at ", ShortStop, " for short trade could not be placed: ", err);
            Print("Exit stop order at ", ShortStop, " for short trade could not be placed: ", err);
        }
    }   
}

void PlaceLongTarget(string symbol, double TargLong, double Slippage)
{
    if (MathAbs(TargLong - OpenTargetPrice) > NEARZERO) {
    
        double MinDist = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT);
        double HighPrice = MarketInfo(symbol, MODE_ASK);
        
        if (TargLong - HighPrice <= MinDist) {     // Exit at market if market is already near or above target price 
            ExitLongMarket(Slippage);
        }
        else if (!OrderModify(OpenTicket, OpenEntryPrice, OpenStopPrice, TargLong, 0, Blue)) {
            string err = ErrorDescription(GetLastError());
            Alert("Exit target order at ", TargLong, " for long trade could not be placed: ", err);
            Print("Exit target order at ", TargLong, " for long trade could not be placed: ", err);
        }
    }   
}

void PlaceShortTarget(string symbol, double TargShort, double Slippage)
{
    if (MathAbs(TargShort - OpenTargetPrice) > NEARZERO) {
    
        double MinDist = MarketInfo(symbol, MODE_STOPLEVEL) * MarketInfo(symbol, MODE_POINT);
        double LowPrice = MarketInfo(symbol, MODE_BID);
        
        if (LowPrice - TargShort <= MinDist) {    // Exit at market if market is already near or below target price
            ExitShortMarket(Slippage);
        }
        if (!OrderModify(OpenTicket, OpenEntryPrice, OpenStopPrice, TargShort, 0, Red)) {
            string err = ErrorDescription(GetLastError());
            Alert("Exit target order at ", TargShort, " for short trade could not be placed: ", err);
            Print("Exit target order at ", TargShort, " for short trade could not be placed: ", err);
        }
    }   
}

double ExactPrice(double RawPrice, int RoundDir)
{
    double RoundPrice = RawPrice;

    double TickValue = MarketInfo(Symbol(), MODE_TICKSIZE);

    if (TickValue > 0) {
        double Remainder = MathMod(RawPrice, TickValue);
        if (MathAbs(Remainder) > 0) {
            if (RoundDir > 0) {
                RoundPrice  += (TickValue - Remainder);             // Round up
            }
            else {
                RoundPrice -= Remainder;                            // Round down
            }
        }
    }
    
    RoundPrice = NormalizeDouble(RoundPrice, Digits);
    return RoundPrice;
}

//----------------------------------------------------------------------------------------------------
// Neural network output function
//----------------------------------------------------------------------------------------------------

// Global arrays for neural network function
#define MAXNNIN 32                  // Maximum number of neural network inputs
#define MAXNNLB 500                 // Maximum look-back length (NNLookBack)

double InputVals[MAXNNIN][MAXNNLB]; // Input values over previous NNLookBack bars
int iOldest = 0;                    // Location in InputVals of oldest value
int CurrentBar = 0;                 // Number of current bar being processed

double NNCompute(double& NNInputs[], double NumInputs, double& NNWeights[], 
                 int NumWeights, int NNLookBack)
//
// Evaluate the neural network function and return the output value.
// The inputs are recorded over the last NNLookBack bars,
// and the min and max values are found over that range. The
// min and max values are used to scale the inputs before applying the
// weights to calculate the output value.
//
// This function can accomodate up to MAXNNIN inputs and a look-back lenth
// (NNLookBack) of up to MAXNNLB bars. To handle larger networks, 
// these constants can be increased.
//
{
    double MinInput[];           // Minimum values of neural network inputs
    double MaxInput[];           // Maximum values of neural network inputs
    
    ArrayResize(MinInput, NumInputs);
    ArrayResize(MaxInput, NumInputs);

    // Collect prior input values
    CurrentBar++;
    
    //printf("Date/time = %s, CurrentBar = %d, iOldest = %d", TimeToStr(Time[0], TIME_DATE|TIME_MINUTES), CurrentBar, iOldest);
    
    if (CurrentBar <= NNLookBack) {
       for (int i = 0; i < NumInputs; i++) { 
          InputVals[i][CurrentBar - 1] = NNInputs[i];
       }
    }
    else {
       for (i = 0; i < NumInputs; i++) { 
           InputVals[i][iOldest] = NNInputs[i];
       }
       iOldest = MathMod(iOldest + 1, NNLookBack);
    }
        
    // Find the min and max input values over last NNLookBack bars
    for (i = 0; i < NumInputs; i++) {
        MinInput[i] = InputVals[i][0];
        MaxInput[i] = InputVals[i][0];
        
        for (int j = 1; j < MathMin(NNLookBack, CurrentBar); j++) {
            MinInput[i] = MathMin(MinInput[i], InputVals[i][j]);
            MaxInput[i] = MathMax(MaxInput[i], InputVals[i][j]);
        }
    }

    // Scale the neural network inputs to [-1, +1] 
    double ScaledInputs[];           // Scaled input values
    ArrayResize(ScaledInputs, NumInputs);  
    
    for (i = 0; i < NumInputs; i++) {
        if (MaxInput[i] - MinInput[i] > 0)
            ScaledInputs[i] = (2 * NNInputs[i] - (MaxInput[i] + MinInput[i]))/
                              (MaxInput[i] - MinInput[i]);
        else {
            ScaledInputs[i] = 0;
        }
        //printf("   InputVals[%d]: %f, Min: %f, Max: %f, Scaled: %f", i, NNInputs[i], MinInput[i], MaxInput[i], ScaledInputs[i]);
    }

    // Calculate the nodes in the hidden layer 
    int NHidden = 0;
    if (NumWeights > NumInputs)
        NHidden = NumWeights/(1 + NumInputs);
        
    double HiddenNodes[];           // Hidden nodes
    ArrayResize(HiddenNodes, NHidden);  
     
    int iWeight = NHidden;
    for (i = 0; i < NHidden; i++) {
        HiddenNodes[i] = 0;
        for (j = 0; j < NumInputs; j++) {
            HiddenNodes[i] += (NNWeights[iWeight] * ScaledInputs[j]);
            iWeight++;
        }
        HiddenNodes[i] = tanh(HiddenNodes[i]);
    }

    // Calculate output from hidden nodes 
    double NNOut = 0;
    for (i = 0; i < NHidden; i++) {
        NNOut += (NNWeights[i] * HiddenNodes[i]);   
    }

    if (NHidden < 1) {    // Special case of no hidden layer
       for (i = 0; i < NumInputs; i++) {
           NNOut += (NNWeights[i] * ScaledInputs[i]);
       }
    }
    
    return tanh(NNOut);
}