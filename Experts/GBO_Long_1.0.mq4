//+------------------------------------------------------------------+
//|                                                          GBO.mq4 |
//|                                                                  |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright ""
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

string expertName = "GBO_Long";

extern string     SYSTEM_SETTIGNS      = "----- System Settings -----";
extern int magicNumber = 123;                  //Magic Number
extern double lots = 0.01;                      //Position Size (lots)

extern string     ALERT_SETTINGS      = "----- Alert Settings -----";
extern bool alertsON = true;                    // Sound Alert (on/off)
extern bool emailON = true;                     // Email Alert (on/off)

extern string     CONDITION_1_SETTINGS      = "----- Condition 1 Settings -----";
extern ENUM_TIMEFRAMES primaryTimeFrame = PERIOD_CURRENT;                           // Primary TimeFrame
extern double condition1_Limit = 0;                                                 // Breakout Limit

extern string     CONDITION_2_SETTINGS      = "----- Condition 2 Settings -----";
extern ENUM_TIMEFRAMES secondaryTimeFrame = PERIOD_M1;   // Secondary TimeFrame
extern double condition2_UpperLimit = 0;                 // Condition 2 UpperLimit
extern double condition2_LowerLimit = 0;                 // Condition 2 LowerLimit
extern double condition2_2_Limit = 0;                    // Condition 2.2 LimitPrice      

extern string     ORDER_EXPIRY_TIME_LIMIT      = "----- Order Expiry Time Setting -----";
extern int operationTimeLimit = 1440;                     // Order Expiry Time Limit (minutes)

extern string     TAKE_PROFIT_SETTINGS    = "----- Take Profit -----";
//takeProfit_Price
extern bool takeProfitOnOff = false;            //TakeProfit (on/off)
extern double takeProfitPrice = 0;              // TakeProfit_Price

extern string     STOPLOSS_SETTINGS    = "----- Stop Loss -----";
//stoploss_Price
extern bool stopLoss_PriceOnOff = false;           // StopLoss_Price (on/off)
extern double stopLoss_Price = 0;                  // StopLoss_Price 
      
//stopLoss_Candle
extern bool stopLoss_CandleOnOff = false;                //StopLoss_Candle (on/off)
extern double stopLoss_Candle_Price = 0;                 //StopLoss_Candle_Price
ENUM_TIMEFRAMES stopLoss_Candle_TimeFrame = PERIOD_M5;   //StopLossCandle_TimeFrame

extern string     TRAILING_STOP    = "----- Trailing Stop -----";
//trailingStop
extern bool trailingStop_PriceOnOff = false;          // TrailingStop_Price (on/off)
extern double trailingStop_Price = 0;                 // TrailingStop_Price (Gap)
extern double trailingStop_Price_MinStep = 0;         // TrailingStop_Price (Min Step) 

//trailingStopCandle
extern bool trailingStopCandleOnOff = false;                        // TrailingStop_Candle (on/off)
extern ENUM_TIMEFRAMES trailingStopCandle_timeFrame = PERIOD_M1;    // TrailingStop_Candle TimeFrame
extern int trailingStopNumCandles = 1;                               //TrailingStop_Candle Number of Candles
extern double trailingStopCandlePrice = 0;                          //TrailingStop_Candle Price Below Candle

//--- Global Variables
string operationMode = "";
int tradeOpenedFlag = 0;
    
int slippage = 1;
int cycleCounter = 0;
int minuteCounter = -1; 

//timeKeepers for new Bars
datetime primaryTimeFrame_time;
datetime secondaryTimeFrame_time;

// Text Variables
string newLine = "\n";

// Aux Variables for sycronization 
double c2_1 = 0, c2_2 = 0;

double trailingStop_Price_AUX = trailingStop_Price;                 
double trailingStop_Price_MinStep_AUX = trailingStop_Price_MinStep;         

ENUM_TIMEFRAMES tralingStopCandle_timeFrame_AUX = trailingStopCandle_timeFrame;
int trailingStopNumCandles_AUX = trailingStopNumCandles;                           
double trailingStopCandlePrice_AUX = trailingStopCandlePrice;

// Global Stop Variables
double orderOpenPrice = 0;
double TS_Price_Value= 0;
double TS_Candle_Value = 0;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(1);
   
   stopLoss_Candle_TimeFrame = primaryTimeFrame; //StopLossCandle_TimeFrame
   
   CHECKINPUTDATA();
   
   primaryTimeFrame_time = iTime(Symbol(),primaryTimeFrame,0);
   secondaryTimeFrame_time = iTime(Symbol(),secondaryTimeFrame,0);
   
   operationMode = "ENTRY_MANAGER";
   //operationMode = "TRADE_MANAGER";
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  
   Comment("Expert removed... Please see log for reason");
//--- destroy timer
   EventKillTimer();
   
  }

//+------------------------------------------------------------------+
//| Expert Main Function                                             |
//+------------------------------------------------------------------+
void OnTimer()
{
//---
   cycleCounter += 1;
   if(cycleCounter > 4) cycleCounter = 1;
   
   if(NewMinute())
   {
      minuteCounter += 1;
   }
   
   if( CountSystemOrdersLong(magicNumber) > 0 && operationMode != "TRADE_MANAGER")
   {
      operationMode = "TRADE_MANAGER"; // Order is already open set operation mode to TRADE_MANAGER
      Print("An order is already open ... operation mode changing to TRADE_MANAGER");
   }
   
   if(operationMode == "TRADE_MANAGER")
   { 
      TRADE_MANAGER();
      return; 
   }
   
   if( operationMode == "ENTRY_MANAGER" )
   {
      ENTRY_MANAGER();
      return;
   }
   
   if( operationMode == "CONDITION2_CHECK")
   {
      CONDITION2_CHECK();
      return;
   }   
   
}

//+------------------------------------------------------------------+
//| Expert Specific Functions                                        |
//+------------------------------------------------------------------+


void CHECKINPUTDATA()
{
   if(lots < SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN))
   {
      AlertUser("Position size (Lots) less than broker minimum... Expert will terminate");
      TerminateEA();
   }
   if(lots > SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX))
   {
      AlertUser("Position size (Lots) greater than broker maximum... Expert will terminate");
      TerminateEA();
   }
   
   // Check correct timeframe settings
   int pTF = primaryTimeFrame; 
   int sTF = secondaryTimeFrame;
   if( primaryTimeFrame == 0 )
   {
      pTF = ChartPeriod();
   }
   if( secondaryTimeFrame == 0)
   {
      sTF = ChartPeriod();
   }
   
   if(pTF < sTF)
   {
      AlertUser("Primary timeFrame must be greater than Secondary timeFrame... Expert will terminate");
      TerminateEA();
   }
   
   if(condition2_LowerLimit>condition2_UpperLimit)
   {
      AlertUser("condition2_lower_limit must be less than condition2_upper_limit... Expert will terminate");
      TerminateEA();
   }
   
   if(takeProfitOnOff == true && takeProfitPrice<condition1_Limit)
   {
      AlertUser("takeProfitPrice cannot be less than BreakoutPrice... Expert will terminate");
      TerminateEA();
   }
   
   if(stopLoss_PriceOnOff==true && stopLoss_Price > condition1_Limit)
   {
      AlertUser("stopLossPrice cannot be greater than BreakoutPrice... Expert will terminate");
      TerminateEA();
   }
   
   if(stopLoss_CandleOnOff==true && stopLoss_Candle_Price > condition1_Limit)
   {
      AlertUser("stopLoss_candle_price cannot be greater than BreakoutPrice... Expert will terminate");
      TerminateEA();
   }
   
}

void ENTRY_MANAGER()
{
   //--- Check if time limit reached
   if( minuteCounter > operationTimeLimit )
   {
      AlertUser("No orders opened and time limt has expired... Removing Expert");
      TerminateEA();
   }
    
   //--- Check for Condition 1 Entry
   // Has new bar formed on Primary TimeFrame
   if( iTime(Symbol(),primaryTimeFrame,0) != primaryTimeFrame_time ) 
   {
      primaryTimeFrame_time = iTime(Symbol(),primaryTimeFrame,0);
      //Print("primary timeFrame newBar detected ... Checking for Breakout(COND1)");
      // reset secondary time frame keep so new bar isnt detected instantly with condition 2
      secondaryTimeFrame_time = iTime(Symbol(),secondaryTimeFrame,0);
      
      // Check for price above condition 1 order entry price
      if(iClose(Symbol(),primaryTimeFrame,1) > condition1_Limit)
      {
         OpenOrderLong("Breakout");
         return;
      }
      
      // Check if we need to activate condition 2 Check
      if(iClose(Symbol(),primaryTimeFrame,1) > condition2_LowerLimit && iClose(Symbol(),primaryTimeFrame,1) < condition2_UpperLimit)
      {
         // once function is called values for condition 2 should be locked
         c2_1 = condition2_LowerLimit;
         c2_2 = condition2_2_Limit;
         
         AlertUser("Im Checking!");
         operationMode = "CONDITION2_CHECK";
         return; 
      }      
   }
   
   Comment(
      newLine, "GBO SYSTEM - LONG",Animation(cycleCounter),
      newLine, "TIME RUNNING / TIME LIMIT (minutes) = ", minuteCounter, " / ",operationTimeLimit,
      newLine,
      newLine, "I'M LOOKING FOR A BREAKOUT", 
      newLine,
      newLine, "BREAKOUT PRICE = ", DoubleToString(condition1_Limit,Digits),
      newLine,
      newLine, "CONDITION 2 BOUNDARIES",
      newLine, "UPPER   = ", DoubleToString(condition2_UpperLimit,Digits),
      newLine, "LOWER  = ", DoubleToString(condition2_LowerLimit,Digits)
   );
}

//--- 
void CONDITION2_CHECK()
{
   
   // Has a new bar formed on secondary timeframe
   if( iTime(Symbol(),secondaryTimeFrame,0) != secondaryTimeFrame_time ) 
   {
      secondaryTimeFrame_time = iTime(Symbol(),secondaryTimeFrame,0);
      //Print("secondary timeFrame newBar detected");
   
      if( iLow(Symbol(),secondaryTimeFrame,1) > c2_1)
      {
         OpenOrderLong("Check Result Positive 2.1");
         return;
      }    
      
      if(iClose(Symbol(),secondaryTimeFrame,1) > c2_2)
      {
         OpenOrderLong("Check Result Positive 2.2");
         return;
      }
      
      // else Condition2 Check result is Negative
      AlertUser("Check Result was Negative... Waiting for next candle on primary timeFrame");
      operationMode = "ENTRY_MANAGER";
   }
   
   Comment(
      newLine, "GBO SYSTEM LONG",Animation(cycleCounter),
      newLine,
      newLine, "I'M CHECKING", 
      newLine,
      newLine, "CONDITION 2.1 MINIMUM PRICE = ", DoubleToString(condition2_LowerLimit,5),
      newLine, "CONDITION 2.2 MINIMUM PRICE = ", DoubleToString(condition2_2_Limit,5)     
   );
}


//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
void TRADE_MANAGER()
{
   //if position closed manually remove expert
   if( CountSystemOrdersLong(magicNumber) == 0 && tradeOpenedFlag > 0)
   {
      AlertUser("the open position has closed ... removing expert");
      TerminateEA();
   }
   
   // Has TP or SL been modified manually - if so remove expert
   if(OpenTakeProfit(Symbol(),magicNumber) != 0)
   {
      AlertUser("A manual Take Profit has been detected ... removing expert");
      TerminateEA();  
   }
   
   if(OpenStopLoss(Symbol(),magicNumber) != 0)
   {
      AlertUser("A manual Stop Loss has been detected ... removing expert");
      TerminateEA();  
   }
   
   if( trailingStop_Price != trailingStop_Price_AUX || trailingStop_Price_MinStep != trailingStop_Price_MinStep_AUX )
   {
      AlertUser("Trailing Stop Price settings have been modified. I am re-initializing the trailing stop");
      
      trailingStop_Price_AUX = trailingStop_Price;                 
      trailingStop_Price_MinStep_AUX = trailingStop_Price_MinStep;
      
      TS_Price_Value = trailingStop_PriceOnOff*(orderOpenPrice - trailingStop_Price);  
    
   }
   
   if(tralingStopCandle_timeFrame_AUX != trailingStopCandle_timeFrame || trailingStopNumCandles_AUX != trailingStopNumCandles || trailingStopCandlePrice_AUX != trailingStopCandlePrice)
   {
      AlertUser("Trailing Stop Price settings have been modified. I am re-initializing the trailing stop");
      
      tralingStopCandle_timeFrame_AUX = trailingStopCandle_timeFrame;
      trailingStopNumCandles_AUX = trailingStopNumCandles;                           
      trailingStopCandlePrice_AUX = trailingStopCandlePrice;
      
      TS_Candle_Value = trailingStopCandleOnOff*(LowestLowValue(Symbol(),trailingStopCandle_timeFrame,trailingStopNumCandles,1) - trailingStopCandlePrice); 
   }
   
   // has an open trade been detected - if so initialize all stop variables
   if( orderOpenPrice == 0)
   {
      orderOpenPrice = OpenPriceLong(Symbol(),magicNumber);
      TS_Price_Value = trailingStop_PriceOnOff*(orderOpenPrice - trailingStop_Price);
      TS_Candle_Value = trailingStopCandleOnOff*(LowestLowValue(Symbol(),trailingStopCandle_timeFrame,trailingStopNumCandles,1) - trailingStopCandlePrice);      
   }
   
   RefreshRates();
   
   //--- check stop conditions
   
   //Check takeProfit_Price
   if( takeProfitOnOff == true)
   {
      if( Bid > takeProfitPrice)
      {
         ExitOrderLong("takeProfit");
      }
   }   
   
   //Check stopLoss_Price
   if( stopLoss_PriceOnOff == true )
   {
      if( Bid < stopLoss_Price )
      {
         ExitOrderLong("stopLoss_Price");
      }
   }
   //Check trailingStop_Price
   if(trailingStop_PriceOnOff == true)
   {
      if( Bid < TS_Price_Value)
      {
         ExitOrderLong("trailingStop_Price");    
      }
   }
   //Check trailingStop_Candle
   if(trailingStopCandleOnOff == true)
   {
      if( Bid < TS_Candle_Value)
      {
         ExitOrderLong("trailingStop_Candle");
      }
   }
   
   //Check Stop Loss (new Candle)
   if( stopLoss_CandleOnOff == true)
   {
      if( iTime(Symbol(),primaryTimeFrame,0) != primaryTimeFrame_time ) // has new candle formed
      {
         primaryTimeFrame_time = iTime(Symbol(),primaryTimeFrame,0);
         Print("newBar detected ... Checking stoploss_Candle");
         
         if(iClose(Symbol(),primaryTimeFrame,1) < stopLoss_Candle_Price)
         {
            ExitOrderLong("stopLoss_Candle");
         }
      }   
   }
     
   //--- Update Trailing Stop Levels
   
   //Trailing Stop Price
   if( Bid - trailingStop_Price > TS_Price_Value + trailingStop_Price_MinStep )
   {
      TS_Price_Value = trailingStop_PriceOnOff*(Bid - trailingStop_Price);
   }
   
   
   //Trailing Stop Candle
   
   if( LowestLowValue(Symbol(),trailingStopCandle_timeFrame,trailingStopNumCandles+1,1) - trailingStopCandlePrice > TS_Candle_Value )
   {
      TS_Candle_Value = trailingStopCandleOnOff * (LowestLowValue(Symbol(),trailingStopCandle_timeFrame,trailingStopNumCandles+1,1) - trailingStopCandlePrice);
   }
   
   
   Comment(
      newLine, "GBO SYSTEM LONG",Animation(cycleCounter),
      newLine,
      newLine, "I'M MANAGING THE TRADE", 
      newLine,
      newLine, "TAKE PROFIT",
      newLine, "PRICE  = ", DoubleToString(takeProfitPrice,Digits),OnOff(takeProfitOnOff),
      newLine,
      newLine, "STOP LOSS",
      newLine, "PRICE    = ", DoubleToString(stopLoss_Price,Digits), OnOff(stopLoss_PriceOnOff),
      newLine, "CANDLE  = ", DoubleToString(stopLoss_Candle_Price,Digits), OnOff(stopLoss_CandleOnOff),
      newLine,
      newLine, "TRAILING STOP",
      newLine, "PRICE    = ", DoubleToString(TS_Price_Value,Digits), OnOff(trailingStop_PriceOnOff),
      newLine, "CANDLE  = ", DoubleToString(TS_Candle_Value,Digits), OnOff(trailingStopCandleOnOff) 
      );
   return;
}


//-------------------------------------------------------------------------------------------

void OpenOrderLong(string comment)
{
   RefreshRates();   

   if( Ask > takeProfitPrice && takeProfitOnOff == true )
   {
      AlertUser("LONG Entry price was above takeprofit level. Trade will not execute... Expert will terminate");
      TerminateEA();
      return;
   }
   
   AlertUser( StringConcatenate("Attempting to BUY at Market - ",comment) );
   if(OrderSend_EnterLong(Symbol(),lots,Ask,slippage,0,0,magicNumber,comment) == 1)
   {
      AlertUser("Market LONG order was successful");
      tradeOpenedFlag = 1;
      operationMode = "TRADE_MANAGER";
      return;
   }
   else
   {
      AlertUser("Market LONG order was NOT successful - Please see Log for error");
      TerminateEA();
   } 
}

void OpenOrderShort(string comment)
{
   RefreshRates();   

   if( Bid < takeProfitPrice && takeProfitOnOff == true )
   {
      AlertUser("SHORT Entry price was below takeprofit level. Trade will not execute... Expert will terminate");
      TerminateEA();
      return;
   }
   
   AlertUser( StringConcatenate("Attempting to SHORT at Market - ",comment) );
   if(OrderSend_EnterShort(Symbol(),lots,Bid,slippage,0,0,magicNumber,comment) == 1)
   {
      AlertUser("Market SHORT order was successful");
      tradeOpenedFlag = 1;
      operationMode = "TRADE_MANAGER";
      return;
   }
   else
   {
      AlertUser("Market SHORT order was NOT successful - Please see Log for error");
      TerminateEA();
   } 
}

void ExitOrderLong(string comment)
{
   RefreshRates();
   
   AlertUser(StringConcatenate("Attempting to exit LONG position at market - ",comment));
   if(OrderSend_ExitLong(Symbol(),Bid,slippage,magicNumber) == 1)
   {
      AlertUser("Exit LONG order was successul... Expert will terminate");
      TerminateEA();
   }
   else
   {
      AlertUser("Exit LONG order failed... trying again");
   }
}

void ExitOrderShort(string comment)
{
   RefreshRates();
   
   AlertUser(StringConcatenate("Attempting to exit SHORT position at market - ",comment));
   if(OrderSend_ExitShort(Symbol(),Ask,slippage,magicNumber) == 1)
   {
      AlertUser("Exit SHORT order was successul... Expert will terminate");
      TerminateEA();
   }
   else
   {
      AlertUser("Exit SHORT order failed... trying again");
   }
}

//--- General Funtions


// This function returns the number of open orders matching system magic number
int CountSystemOrdersLong( int nMagic )
{
    int nOrderCount = 0;

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
        if( OrderSymbol() != Symbol()) continue;
        if( OrderMagicNumber() != nMagic ) continue;
        if( OrderType() != OP_BUY) continue;
        nOrderCount++;
    }

    return( nOrderCount );
}

// This function returns the number of open orders matching system magic number
int CountSystemOrdersShort( int nMagic )
{
    int nOrderCount = 0;

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
        if( OrderSymbol() != Symbol()) continue;
        if( OrderMagicNumber() != nMagic ) continue;
        if( OrderType() != OP_SELL) continue;
        nOrderCount++;
    }

    return( nOrderCount );
}

double OpenPriceLong( string symbol, int nMagic )
{
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
   {
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue; 
      if( OrderType() != OP_BUY)continue;      
      if( OrderSymbol() == symbol && OrderMagicNumber() == nMagic )
      {
         return( OrderOpenPrice() );
      }    
   }
   return( 0 );
}

double OpenPriceShort( string symbol, int nMagic )
{
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
   {
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue; 
      if( OrderType() != OP_SELL )continue;      
      if( OrderSymbol() == symbol && OrderMagicNumber() == nMagic )
      {
         return( OrderOpenPrice() );
      }    
   }
   return( 0 );
}

double OpenTakeProfit( string symbol, int nMagic )
{
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
   {
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;   
      {
         if( OrderSymbol() == symbol && OrderMagicNumber() == nMagic )
         {
             return( OrderTakeProfit() );
         }
      }
   }
   return( 0 );
}

double OpenStopLoss( string symbol, int nMagic )
{
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
   {
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;   
      {
         if( OrderSymbol() == symbol && OrderMagicNumber() == nMagic )
         {
             return( OrderStopLoss() );
         }
      }
   }
   return( 0 );
}

// Function returns the LLV of the Close given a start bar and a lookback
double LowestLowValue(string symbol, ENUM_TIMEFRAMES timeframe, int LookBack, int Start)
{
   int shift = iLowest(symbol,timeframe,MODE_LOW,LookBack,Start);
   double LLV = iLow(symbol,timeframe,shift);
   return(LLV);
}

// Function returns the LLV of the Close given a start bar and a lookback
double HighestHighValue(string symbol, ENUM_TIMEFRAMES timeframe, int LookBack, int Start)
{
   int shift = iHighest(symbol,timeframe,MODE_HIGH,LookBack,Start);
   double HHV = iHigh(symbol,timeframe,shift);
   return(HHV);
}

void TerminateEA()
{
   ExpertRemove();
}

void AlertUser(string message)
{
   string label = StringConcatenate(expertName," ",Symbol()," ");
   string completeMessage = StringConcatenate(label,message);
   //Comment(message);
   if(alertsON)
   {
      Alert(completeMessage);
   }
   else
   {
      Print(completeMessage);
   }   
   if(emailON)
   {
      SendEmail(completeMessage);
   }
}

void SendEmail( string message )
{        
      string subject = StringConcatenate
      (
         newLine, expertName, Symbol()
      );
      
      string body = StringConcatenate(subject,newLine,message);
      SendMail(subject,body);
}

//+------------------------------------------------------------------+

// This function returns true when a new Minute is Detected
bool NewMinute()
{
    static datetime LastMinute;
    datetime ThisMinute = TimeMinute( TimeGMT() );

    if( ThisMinute != LastMinute )
    {
        LastMinute = ThisMinute;
        return ( true );
    }
    else
        return ( false );
}

// Return Price Recognised by MT4
double NormPrice(double price, double ticksize, int digits)
{
   double P1 = MathRound( price / ticksize) * ticksize;
   double P2 = NormalizeDouble(P1, digits);
   return(P2);
}

int OrderSend_EnterLong( string symbol, double Lots, double Price, int Slippage, double StopLossPct, double TakeProfitPct, int nMagic, string Label )
{
    static double stoploss, takeprofit, ticksize;
    ticksize = MarketInfo( symbol, MODE_TICKSIZE );
    int digits = (int)MarketInfo( symbol, MODE_DIGITS );

    if( StopLossPct != 0 )
    {
        stoploss = NormalizeDouble( MathCeil( ( ( Price * ( 1 - StopLossPct * 0.01 ) ) / ticksize ) ) * ticksize, digits );
    }

    if( TakeProfitPct != 0 )
    {
        takeprofit = NormalizeDouble( MathCeil( ( ( Price * ( 1 + TakeProfitPct * 0.01 ) ) / ticksize ) ) * ticksize, digits );
    }

    RefreshRates();

    if( !OrderSend( symbol, OP_BUY, Lots, Price, Slippage, stoploss, takeprofit, Label, nMagic, 0, NULL ) )
    {
        ErrorReport(GetLastError());
        return(-1);
    }
    return(1);
}

int OrderSend_EnterShort( string symbol, double Lots, double Price, int Slippage, double StopLossPct, double TakeProfitPct, int nMagic, string Label )
{
    static double stoploss, takeprofit, ticksize;
    ticksize = MarketInfo( symbol, MODE_TICKSIZE );
    int digits = (int)MarketInfo( symbol, MODE_DIGITS );

    if( StopLossPct != 0 )
    {
        stoploss = NormalizeDouble( MathCeil( ( ( Price * ( 1 + StopLossPct * 0.01 ) ) / ticksize ) ) * ticksize, digits );
    }

    if( TakeProfitPct != 0 )
    {
        takeprofit = NormalizeDouble( MathCeil( ( ( Price * ( 1 - TakeProfitPct * 0.01 ) ) / ticksize ) ) * ticksize, digits );
    }

    RefreshRates();

    if( !OrderSend( symbol, OP_SELL, Lots, Price, Slippage, stoploss, takeprofit, Label, nMagic, 0, NULL ) )
    {
        ErrorReport(GetLastError());
        return(-1);
    }
    return(1);
}

int OrderSend_ExitLong( string symbol, double Price, int Slippage, int nMagic )
{
    for( int i = OrdersTotal() - 1; i >= 0 ; i-- )
    {
        if( ! OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) ) continue;
        if( OrderSymbol() != symbol )continue;
        if( OrderMagicNumber() != nMagic)continue;
        if( OrderType() != OP_BUY ) continue;

         if( ! OrderClose( OrderTicket(), OrderLots(), Price, Slippage) )
         {
             ErrorReport(GetLastError());
             return(-1);
         }
         else
         {
            return(1);
         }    
    }
    return(-1);
}

int OrderSend_ExitShort( string symbol, double Price, int Slippage, int nMagic )
{
    for( int i = OrdersTotal() - 1; i >= 0 ; i-- )
    {
        if( ! OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) ) continue;
        if( OrderSymbol() != symbol )continue;
        if( OrderMagicNumber() != nMagic)continue;
        if( OrderType() != OP_SELL ) continue;
         
         if( ! OrderClose( OrderTicket(), OrderLots(), Price, Slippage) )
         {
             ErrorReport(GetLastError());
             return(-1);
         }
         else
         {
            return(1);
         }    
    }
    return(-1);
}


int ErrorReport( int Error )
{
    switch( Error )
    {
        //Non Critical Errors
        case 4:
        {
            Print( "Trade server is busy." );
            Sleep( 3000 );                                              // Simple Solution
            return( 1 );
        }                                                           // Exit the function

        case 135:
        {
            Print( "Price changed " );
            RefreshRates();
            return( 1 );
        }

        case 136:
        {
            Print( "No Prices. Waiting for a new tick.." );

            while( RefreshRates() == false )                            //Till a new tick
                Sleep( 1 );                                              //pause in Loop

            return( 1 );
        }

        case 137:
        {
            Print( "Broker is Busy. " );
            Sleep( 3000 );
            return( 1 );
        }

        case 146:
        {
            Print( "Trading System is Busy. " );
            Sleep( 500 );
            return( 1 );
        }

        // Critical Errors
        case 2:
        {
            Alert( "Common Error." );                               // Terminate the functin
            Sleep( 3000 );
            return( 1 );
        }                                                           // Exit the function

        case 5:
        {
            Print( "Old Terminal Version." );
            return( 0 );
        }

        case 64:
        {
            Print( "Account Blocked." );
            return( 0 );
        }

        case 133:
        {
            Print( "Trading Forbidden." );
            return( 0 );
        }

        case 134:
        {
            Print( "Not Enough Money to Execute Operation" );
            return( 0 );
        }
    }

    return( 0 );
}

string OnOff(bool trueFalse)
{
   if(trueFalse == true)
   {
      return(" - On");
   }
   else
   {
      return(" - Off");
   }   
}

string Animation(int counter)
{
   if(counter == 0) return(" ");
   if(counter == 1) return(" . ");
   if(counter == 2) return(" .. ");
   if(counter == 3) return(" ... ");
   return("");
}