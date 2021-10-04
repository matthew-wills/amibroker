//+------------------------------------------------------------------+
//|                                                   myTemplate.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Import Structures Classes and Include Files                      |
//+------------------------------------------------------------------+  
MqlTick  m_tick;
MqlRates m_rates;

// remove after final itteration and paste in all functions needed
//#include <myFunctionsPro.mqh>

//+------------------------------------------------------------------+
//| User Inputs                                                      |
//+------------------------------------------------------------------+
extern string     GENERAL_SETTINGS     = "----- general settings -----";
extern bool sendAlerts = false; // Generate Alerts 
extern bool sendEmails = false; // Send Email Alerts
extern bool sendNotification = false; // Send Notificaitons

extern bool tradingAllowed = true;
extern bool immediateEntry = false;
extern int magicNumber = 0;// Expert Magic Number
extern ENUM_TIMEFRAMES timeFrame = PERIOD_CURRENT;// Time Frame
extern bool runOnTimer = false;

extern string     MONEY_MANAGEMENT_SETTINGS     = "----- money management settings -----";
extern double fixedLotSize = 0.01; // Fixed Lot Size
extern bool useTrendFilter = true; // Use trend filter
extern bool oneTradePerTrend = true; // Allow only 1 trade per change of trend

extern string     INDICATOR_SETTINGS     = "----- indicator settings -----";
extern string GT3_Fast_TimeFrame = "M5";
extern int    GT3_Fast_HighLowPeriod = 10;
extern int    GT3_Fast_ClosePeriod   = 0;
extern double GT3_Fast_Hot           = 0.7;
extern bool GT3_Fast_OriginalT3      = True;

extern string GT3_Slow_TimeFrame = "M15";
extern int    GT3_Slow_HighLowPeriod = 10;
extern int    GT3_Slow_ClosePeriod   = 0;
extern double GT3_Slow_Hot           = 0.7;
extern bool GT3_Slow_OriginalT3      = True;

extern string     TAKE_PROFIT_SETTINGS    = "----- Take Profit -----";
//takeProfit_Price
extern double takeProfit_Points = 0;              // TakeProfit_Price

extern string     STOPLOSS_SETTINGS    = "----- Stop Loss -----";
//stoploss_Price
extern double stopLoss_Points = 0;                  // StopLoss_Price 
      
//stopLoss_Candle
extern double stopLoss_Candle_Points = 0;                       //StopLoss_Candle_Price
extern ENUM_TIMEFRAMES stopLoss_Candle_TimeFrame = PERIOD_M5;   //StopLossCandle_TimeFrame

//stopLoss_Gann
extern bool stopLoss_Gann_OnOff = false;           // StopLoss_GANN (on/off)
extern int stopLoss_Gann_Candles = 1;              //StopLoss_GANN NumCandles

extern string     TRAILING_STOPS    = "----- Trailing Stops -----";
//trailingStop
extern bool trailingStop_PointsOnOff = false;           // TrailingStop_Price (on/off)
extern double trailingStop_Points = 0;                  // TrailingStop_Price (Gap)
extern double trailingStop_Points_MinStep = 0;          // TrailingStop_Price (Min Step) 

//trailingStopCandle
extern bool trailingStop_CandleOnOff = false;                            // TrailingStop_Candle (on/off)
extern ENUM_TIMEFRAMES trailingStopCandle_timeFrame = PERIOD_CURRENT;    // TrailingStop_Candle TimeFrame
extern int trailingStop_Candle_NumCandles = 20;                          // TrailingStop_Candle Number of Candles
extern double trailingStop_Candle_Points = 0;                            // TrailingStop_Candle Price Below Candle

int maxSlippage = 30;// Max Acceptable Slippage 

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+
// Position Counters
int numOpenShort = 0;
int numOpenLong = 0;
int numOpenExpert = 0;

// StopLevels
double orderOpenPrice = 0;
double TP_Price = 0;
double SL_Price = 0;
double SL_Candle_Price = 0;
double SL_Gann_Price = 0;
double TS_Price = 0;
double TS_Candle_Price = 0;


// Indicators
double GT3_Fast_1 = 0;
double GT3_Slow_1 = 0;
double GT3_Fast_2 = 0;
double GT3_Slow_2 = 0;
int signal = 0;

// Flags
int flag_NewTradeAllowed = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   EventSetTimer( 1 );  
   if(immediateEntry == true) flag_NewTradeAllowed = 1;
   
   Comment("Expert Initialized");

return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   Comment("Expert Removed - Please See Log For Details");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   if(!runOnTimer)
   {
      Comment("Running on Tester");
      ExpertMain();
   }
}

//+------------------------------------------------------------------+
//| Expert timer function                                             |
//+------------------------------------------------------------------+
void OnTimer()
{
//---
   if(runOnTimer){
      ExpertMain();
   }
}  
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert Specific functions                                        |
//+------------------------------------------------------------------+

void ExpertMain(){
   
   Load_Position_Counters();
   Load_Indicator_Variables();
   
   if(numOpenLong > 0){
   //--- manage the open long position
      TradeManagerLong();
   }
   if(numOpenShort > 0){
   //--- manage the open short position   
      TradeManagerShort();
   }
   
   if(numOpenExpert == 0){
      ClearStopVariables();
   }   
   
   GenerateComments();  
//--- if new bar forms on selected timeFrame
   if(NewBar(_Symbol,timeFrame)){
      if(numOpenExpert == 0 && signal == 1){
         if(oneTradePerTrend)flag_NewTradeAllowed = 0;
         if(flag_NewTradeAllowed==1)EnterLongPosition();
      }
      if(numOpenExpert == 0 && signal == -1){
         if(oneTradePerTrend)flag_NewTradeAllowed = 0;
         if(flag_NewTradeAllowed == 1)EnterShortPosition();
      }         
   }
}

void Load_Position_Counters(){
   numOpenLong = CountOrders(_Symbol,OP_BUY,magicNumber);
   numOpenShort = CountOrders(_Symbol,OP_SELL,magicNumber); 
   numOpenExpert = numOpenLong+numOpenShort;
}

void Load_Indicator_Variables(){
   GT3_Slow_1 = iCustom(_Symbol,PERIOD_CURRENT,"GANNIMEDE_IND1",GT3_Slow_TimeFrame,GT3_Slow_HighLowPeriod,GT3_Slow_ClosePeriod,GT3_Slow_Hot,GT3_Slow_OriginalT3,2,1);
   GT3_Slow_2 = iCustom(_Symbol,PERIOD_CURRENT,"GANNIMEDE_IND1",GT3_Slow_TimeFrame,GT3_Slow_HighLowPeriod,GT3_Slow_ClosePeriod,GT3_Slow_Hot,GT3_Slow_OriginalT3,2,2);   
   GT3_Fast_1 = iCustom(_Symbol,PERIOD_CURRENT,"GANNIMEDE_IND1",GT3_Fast_TimeFrame,GT3_Fast_HighLowPeriod,GT3_Fast_ClosePeriod,GT3_Fast_Hot,GT3_Fast_OriginalT3,2,1);
   GT3_Fast_2 = iCustom(_Symbol,PERIOD_CURRENT,"GANNIMEDE_IND1",GT3_Fast_TimeFrame,GT3_Fast_HighLowPeriod,GT3_Fast_ClosePeriod,GT3_Fast_Hot,GT3_Fast_OriginalT3,2,2);
   
   signal = Signal();
   
   if(trendChangeDetected()){
      flag_NewTradeAllowed = 1;
   }
}

int Signal(){  
   if(!useTrendFilter){ // not using trend filter
      if(GT3_Fast_1 == 1){ // buy signal
         return(1);
      }
      if(GT3_Fast_1 == -1){ // sell signal
         return(-1);
      }      
   }
   
   if(!oneTradePerTrend){ // not limiting trades to one per trend
      if(GT3_Slow_1 == 1 && GT3_Fast_1 == 1){
         return(1);
      }
      
      if(GT3_Slow_1 == -1 && GT3_Fast_1 == -1){
         return(-1);
      }
   }
   
   if(flag_NewTradeAllowed == 1 ){
      if(GT3_Slow_1 == 1 && GT3_Fast_1 == 1){
         return(1);
      }
      
      if(GT3_Slow_1 == -1 && GT3_Fast_1 == -1){
         return(-1);
      }
   }
   // no signal found return 0
   return(0);
}

bool trendChangeDetected(){
   if( GT3_Slow_1 != GT3_Slow_2){
      return(true);
   }
   return(false);
}

void EnterLongPosition(){
   AlertUser("Long Entry Signal",sendAlerts,sendEmails,sendNotification);
   if(tradingAllowed)EnterPosition(_Symbol,OP_BUY,fixedLotSize,Ask,maxSlippage,0,0,magicNumber,"");
}

void EnterShortPosition(){
   AlertUser("Short Entry Signal",sendAlerts,sendEmails,sendNotification);
   if(tradingAllowed)EnterPosition(_Symbol,OP_SELL,fixedLotSize,Bid,maxSlippage,0,0,magicNumber,"");
}

void TradeManagerLong(){
//--- Initialize Stops
   if(orderOpenPrice == 0){
      orderOpenPrice = OpenPrice(_Symbol,magicNumber);
      if(takeProfit_Points != 0)        TP_Price = orderOpenPrice + takeProfit_Points * _Point;
      if(stopLoss_Points != 0)          SL_Price = orderOpenPrice - stopLoss_Points * _Point;
      if(stopLoss_Candle_Points != 0)   SL_Candle_Price = orderOpenPrice - stopLoss_Candle_Points * _Point;
      if(stopLoss_Gann_OnOff)           SL_Gann_Price = LLV(_Symbol,PERIOD_CURRENT,stopLoss_Gann_Candles);
      if(trailingStop_PointsOnOff)      TS_Price = orderOpenPrice - trailingStop_Points * _Point;
      if(trailingStop_CandleOnOff)      TS_Candle_Price = LLV(_Symbol,trailingStopCandle_timeFrame,trailingStop_Candle_NumCandles) - trailingStop_Candle_Points * _Point;
   }

   RefreshRates();
   
//--- check immediate stop conditions   
   //Check takeProfit_Price
   if( takeProfit_Points !=0 && TP_Price != 0 && Bid > TP_Price){
      ExitOrderLong("takeProfit");
   }
   //Check stopLoss_Price
   if( stopLoss_Points != 0 && SL_Price != 0 && Bid < SL_Price ){
      ExitOrderLong("stopLoss");
   }
   //Check trailingStopPrice
   if(trailingStop_PointsOnOff && TS_Price != 0 && Bid < TS_Price){
      ExitOrderLong("trailingStop_Price");
   }
//--- check NewBar stop conditions
   if(NewBar(_Symbol,timeFrame)){   
      //check stopLossCandle
      if( stopLoss_Points != 0 && SL_Candle_Price != 0 && Bid < SL_Candle_Price ){
         ExitOrderLong("stopLoss_Candle");
      }
      //check GannStop
      if( stopLoss_Gann_OnOff && SL_Gann_Price != 0 && iClose(_Symbol,PERIOD_CURRENT,1) < SL_Gann_Price){
         ExitOrderLong("gannStop_Exit");
      }            
      //check trailingStopCandle
      if(trailingStop_CandleOnOff && TS_Candle_Price != 0 && iClose(_Symbol,trailingStopCandle_timeFrame,1) < TS_Candle_Price){
         ExitOrderLong("trailingStop_Candle");
      }
      //check for exit signal
      if(!useTrendFilter && GT3_Fast_1 == -1){
         ExitOrderLong("exitSignal");
         if(useTrendFilter == false){
            EnterShortPosition();
         }
      }
      if(useTrendFilter == true && signal == 0){
         ExitOrderLong("exitSignal");
      }
           
   }
   
//--- Update Trailing Stop Levels  
   //Trailing Stop Price
   if(trailingStop_PointsOnOff){
      if( Bid - trailingStop_Points * _Point > TS_Price + trailingStop_Points_MinStep * _Point ){
         TS_Price = (Bid - trailingStop_Points * _Point);
      }
   }
   //Trailing Stop Candle
   if(trailingStop_CandleOnOff){
      if( LLV(_Symbol,trailingStopCandle_timeFrame,trailingStop_Candle_NumCandles) - trailingStop_Candle_Points * _Point > TS_Candle_Price ){
         TS_Candle_Price = LLV(_Symbol,trailingStopCandle_timeFrame,trailingStop_Candle_NumCandles) - trailingStop_Candle_Points * _Point;
      }
   }    
   return;
}

void TradeManagerShort(){
//--- Initialize Stops
   if(orderOpenPrice == 0){
      orderOpenPrice = OpenPrice(_Symbol,magicNumber);
      if(takeProfit_Points != 0)        TP_Price = orderOpenPrice - takeProfit_Points * _Point;
      if(stopLoss_Points != 0)          SL_Price = orderOpenPrice + stopLoss_Points * _Point;
      if(stopLoss_Candle_Points != 0)   SL_Candle_Price = orderOpenPrice + stopLoss_Candle_Points * _Point;
      if(stopLoss_Gann_OnOff)           SL_Gann_Price = HHV(_Symbol,PERIOD_CURRENT,stopLoss_Gann_Candles);
      if(trailingStop_PointsOnOff)      TS_Price = orderOpenPrice + trailingStop_Points * _Point;
      if(trailingStop_CandleOnOff)      TS_Candle_Price = HHV(_Symbol,trailingStopCandle_timeFrame,trailingStop_Candle_NumCandles) + trailingStop_Candle_Points * _Point;
   }

   RefreshRates();
   
//--- check immediate stop conditions   
   //Check takeProfit_Price
   if( takeProfit_Points !=0 && TP_Price != 0 && Ask < TP_Price){
      ExitOrderShort("takeProfit");
   }
   //Check stopLoss_Price
   if( stopLoss_Points != 0 && SL_Price != 0 && Ask > SL_Price ){
      ExitOrderShort("stopLoss");
   }
   //Check trailingStopPrice
   if(trailingStop_PointsOnOff && TS_Price != 0 && Ask > TS_Price){
      ExitOrderShort("trailingStop_Price");
   }
//--- check NewBar stop conditions
   if(NewBar(_Symbol,timeFrame)){   
      //check stopLossCandle
      if( stopLoss_Points != 0 && SL_Candle_Price != 0 && Ask > SL_Candle_Price ){
         ExitOrderShort("stopLoss_Candle");
      }
      //check GannStop
      if( stopLoss_Gann_OnOff && SL_Gann_Price != 0 && iClose(_Symbol,PERIOD_CURRENT,1) > SL_Gann_Price){
         ExitOrderShort("gannStop_Exit");
      }        
      //check trailingStopCandle
      if(trailingStop_CandleOnOff && TS_Candle_Price != 0 && iClose(_Symbol,trailingStopCandle_timeFrame,1) > TS_Candle_Price){
         ExitOrderShort("trailingStop_Candle");
      }
      //check for exit signal
      if(!useTrendFilter && GT3_Fast_1 == 1){
         ExitOrderShort("exitSignal");
         if(useTrendFilter == false){
            EnterLongPosition();
         }
      }
      if(useTrendFilter == true && signal == 0)  {
         ExitOrderShort("exitSignal");
      }   
   }
   
//--- Update Trailing Stop Levels  
   //Trailing Stop Price
   if(trailingStop_PointsOnOff){
      if( Ask + trailingStop_Points * _Point < TS_Price - trailingStop_Points_MinStep * _Point ){
         TS_Price = (Ask + trailingStop_Points * _Point);
      }
   }
   //Trailing Stop Candle
   if(trailingStop_CandleOnOff){
      if( HHV(_Symbol,trailingStopCandle_timeFrame,trailingStop_Candle_NumCandles) + trailingStop_Candle_Points * _Point < TS_Candle_Price ){
         TS_Candle_Price = HHV(_Symbol,trailingStopCandle_timeFrame,trailingStop_Candle_NumCandles) + trailingStop_Candle_Points * _Point;
      }
   }    
   return;
}

void ExitOrderLong(string comment){  
   AlertUser(StringConcatenate("Attempting to exit LONG position at market - ",comment),sendAlerts,sendEmails,sendNotification);
   ExitPosition(_Symbol,OP_BUY,maxSlippage,magicNumber);
}

void ExitOrderShort(string comment){  
   AlertUser(StringConcatenate("Attempting to exit SHORT position at market - ",comment),sendAlerts,sendEmails,sendNotification);
   ExitPosition(_Symbol,OP_SELL,maxSlippage,magicNumber);
}

void ClearStopVariables(){
   orderOpenPrice = 0;
   TP_Price = 0;
   SL_Price = 0;
   SL_Gann_Price = 0;
   SL_Candle_Price = 0;
   TS_Price = 0;
   TS_Candle_Price = 0;
}

void GenerateComments(){   
   string com = "";
   com+="\n=========================";
   com+="\n    SYSTEM SETTINGS";
   com+="\n=========================";
   com+="\n-FIXED LOT SIZE = " + DoubleToString(fixedLotSize,2);
   com+="\n-USE TREND FILTER = " + (string)useTrendFilter;
   com+="\n-ONE TRADE PER TREND = " + (string)oneTradePerTrend;
   com+="\n=========================";
   com+="\n    INDICATOR VARIABLES";
   com+="\n=========================";   
   com+="\n-EA TIMEFRAME = " + (string) timeFrame;
   com+="\n-GT3_FAST = " + (string) GT3_Fast_1;  
   com+="\n-GT3_SLOW = " + (string) GT3_Slow_1;
   com+="\n-ENTRY_SIGNAL = " + (string) signal;
   if(oneTradePerTrend)     com+="\n-FLAG_NEW_TRADE_ALLOWED = " + (string) flag_NewTradeAllowed;
   
   if(numOpenExpert != 0){
      com+="\n=========================";
      com+="\n    STOP VARIABLES";
      com+="\n=========================";  
      if(TP_Price != 0)          com+="\n-TAKE_PROFIT_PRICE = " + DoubleToString(TP_Price,_Digits);
      if(SL_Price != 0)          com+="\n-STOP_LOSS_PRICE = " + DoubleToString(SL_Price,_Digits);
      if(SL_Candle_Price != 0)   com+="\n-STOP_LOSS_CANDLE_PRICE = " + DoubleToString(SL_Candle_Price,_Digits);
      if(TS_Price != 0)          com+="\n-TRAILING_STOP_PRICE = " + DoubleToString(TS_Price,_Digits);
      if(TS_Candle_Price != 0)   com+="\n-TRAILING_STOP_CANDLE_PRICE = " + DoubleToString(TS_Candle_Price,_Digits);
   }
      
   Comment(com);
}   

////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+//
//|                     my Include Functions                         |//
//+------------------------------------------------------------------+//  
////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//|                                               myFunctionsPro.mqh |
//|                                                    Matthew Wills |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Matthew Wills"
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
// This function returns true when a new bar is placed on the chart
bool NewBar(string _symbol, ENUM_TIMEFRAMES _timeFrame){
   static datetime lastBarOpenTime = 0;
   datetime thisBarOpenTime = iTime(_symbol,_timeFrame,0);//Time[0];  
   if( lastBarOpenTime == 0 ){
      lastBarOpenTime = thisBarOpenTime;  
      return(false);
   }
   if( thisBarOpenTime != lastBarOpenTime ){
      lastBarOpenTime = thisBarOpenTime;
      return(true);
   }  
   return(false);
}

bool NewBarOnChart(){
   static datetime lastBarOpenTime = 0;
   datetime thisBarOpenTime = Time[0];  
   if( lastBarOpenTime == 0 ){
      lastBarOpenTime = thisBarOpenTime;  
      return(false);
   }
   if( thisBarOpenTime != lastBarOpenTime ){
      lastBarOpenTime = thisBarOpenTime;
      return(true);
   }  
   return(false);
}

bool NewMinute(){
    static datetime LastMinute = -1;
    datetime ThisMinute = TimeMinute( TimeGMT() );
    if( ThisMinute != LastMinute ){
        LastMinute = ThisMinute;
        return ( true );
    }
    return ( false );
}

int CountOrders( string _symbol = "all_Symbols", int nOrderType = -1, int _magicNumber = -1 ){
   int nOrderCount = 0;
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      if( _magicNumber != -1 && OrderMagicNumber() != _magicNumber )continue;
      if( _symbol != "all_Symbols" && OrderSymbol() != _symbol ) continue; 
      if( nOrderType != -1 && OrderType() != nOrderType )continue;
      nOrderCount++;
   }
   return( nOrderCount );
}

double RoundPrice( string _symbol, double _price ){
   double tickSize = MarketInfo( _symbol, MODE_TICKSIZE );
   return(NormalizeDouble(MathCeil( _price / tickSize)*tickSize,(int)MarketInfo( _symbol, MODE_DIGITS)));
}

double RoundVolume( string _symbol, double Lots ){
   double maxVolume = MarketInfo( _symbol, MODE_MAXLOT );
   double minVolume = MarketInfo( _symbol, MODE_MINLOT );
   double minVolumeStep = MarketInfo( _symbol, MODE_LOTSTEP );
   if( Lots < minVolume ){
      Print( "Volume is less than minimum order... I will submit minimum volume for the order" );
      return(minVolume);
   }   
   if( Lots > maxVolume ){
      Print( "Volume is greater than maximum order... I will submit maximum volume for the order" );
      return(maxVolume);
   }
   return( MathRound( Lots / minVolumeStep ) * minVolumeStep );
}

bool EnterPosition( string _symbol, ENUM_ORDER_TYPE _orderType, double _lots, double _price, int _slippage, double _stopLoss, double _takeProfit, int _magicNumber, string _label )
{
   double lots = RoundVolume( _symbol, _lots );
   double entry_price = RoundPrice(_symbol, _price );   
   double stoploss = RoundPrice( _symbol, _stopLoss  );
   double takeprofit = RoundPrice( _symbol, _takeProfit);
  
   RefreshRates();
   
   if( OrderType() == OP_BUY ) _price = MarketInfo(_symbol,MODE_ASK);
   if( OrderType() == OP_SELL) _price = MarketInfo(_symbol,MODE_BID);

   if( !OrderSend( _symbol, _orderType, _lots, _price, _slippage, stoploss, takeprofit, _label, _magicNumber, 0, Green ) )
   {
     ErrorReport( GetLastError() );
     return(false);
   }
   return(true);
}

void ExitPosition(string _symbol, ENUM_ORDER_TYPE _orderType, int _maxSlippage, int _magicNumber){
   for( int i = OrdersTotal() - 1; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) )continue;  
      if( OrderSymbol() != _symbol )continue;
      if( OrderType() != _orderType )continue;
      if( OrderMagicNumber() != _magicNumber )continue;
      if( OrderType() == OP_BUY ){
         RefreshRates();
         if( OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(),MODE_BID), _maxSlippage, Red) )continue;
         Print( _symbol, " Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }
      if( OrderType() == OP_SELL ){
         RefreshRates();
         if( OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(),MODE_ASK), _maxSlippage, Red) )continue;
         Print( _symbol, " Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }     
   }
}

void ExitAllPositions(int _maxSlippage){
   for( int i = OrdersTotal() - 1; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) )continue;  
      if( OrderType() == OP_BUY ){
         RefreshRates();
         if( OrderClose( OrderTicket(), OrderLots(),MarketInfo(OrderSymbol(),MODE_BID), _maxSlippage, Red) )continue;
         Print( "Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }
      if( OrderType() == OP_SELL ){
         RefreshRates();
         if( OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(),MODE_ASK), _maxSlippage, Red) )continue;
         Print( "Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }     
   }     
}

void DeleteAllPendingOrders(){
   for( int i = OrdersTotal() - 1; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) )continue;  
      if( OrderType() != OP_BUY && OrderType() != OP_SELL )continue;
      if( OrderDelete(OrderTicket()) )continue;
      Print( "Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
   }
}

void DeletePendingOrder(string _symbol, ENUM_ORDER_TYPE _orderType, int _magicNumber){
   for( int i = OrdersTotal() - 1; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) )continue;  
      if( OrderSymbol() != _symbol )continue;
      if( OrderType() != _orderType )continue;
      if( OrderMagicNumber() != _magicNumber )continue;
      if( OrderDelete(OrderTicket()) )continue;
      Print( "Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
   }
}

bool ModifyPosition(string _symbol, int _ticket, double _stopLoss, double _takeProfit ){
   double takeProfit = RoundPrice(_symbol,_takeProfit);
   double stopLoss = RoundPrice(_symbol,_stopLoss);
   if( !OrderSelect(_ticket,SELECT_BY_TICKET) ){
      Print("Unable to ModifyPosition() ticket number not found");
      return(false);
   }
   if( takeProfit != OrderTakeProfit() || stopLoss != OrderStopLoss() ){
      if( !OrderModify( OrderTicket(), OrderOpenPrice(), stopLoss, takeProfit, 0 ) ){ 
         Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
         return(false);
      } 
   }
   return(true);
}

bool DateCheck(datetime _startDate, datetime _objectDate){
   if( _objectDate > _startDate){
      return(true);
   }
   else{
      return(false);
   }
}

int TotalTradesHistory( string _symbol, int _magicNumber, datetime _startDate ){
   int nTrades = 0;
   for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
      if( _symbol != "" && OrderSymbol() != _symbol )continue;
      if( _magicNumber != NULL && OrderMagicNumber() != _magicNumber ) continue;
      if ( DateCheck(_startDate, OrderCloseTime()) == false ) continue;   
      nTrades += 1;
   }
return( nTrades );
}

double LastTrade_Profit(string _symbol, int _magicNumber, datetime _startDate){
   double profit = 0;
   datetime orderCloseTime = 0;
   for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
      if( _symbol != "" && OrderSymbol() != _symbol ) continue;
      if( _magicNumber != NULL && OrderMagicNumber() != _magicNumber ) continue;
      if ( DateCheck(_startDate, OrderCloseTime()) == false ) continue;   
      if(OrderCloseTime() > orderCloseTime){
         orderCloseTime = OrderCloseTime();
         profit = OrderProfit();
      };
   }
   return(profit);
}

bool newTradeClosed(string _symbol, int _magicNumber, datetime _startDate){
   static double actNumTrades = -1;
   int currentNumTrades = TotalTradesHistory(_symbol,_magicNumber,_startDate);      
   if( currentNumTrades != actNumTrades && currentNumTrades > 0 ){
      actNumTrades = currentNumTrades;
      Print(_Symbol + " ... new trade found in history");
      return(true);
   }
   return(false);
}

void TrailingStop_Bars( string _symbol, int _magicNumber, int _timeFrame, int _bars ){
   double trailingStopValue = 0;
   
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){  
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      if( OrderSymbol() != _symbol ) continue;      
      if( OrderMagicNumber() != _magicNumber ) continue;
      if( OrderType() != OP_BUY && OrderType() != OP_SELL ) continue;

      
      double currentTakeProfit = OrderTakeProfit();
      double currentStopLoss = OrderStopLoss();
         
      if( OrderType() == OP_BUY ){
         trailingStopValue = LLV( _symbol, _timeFrame, _bars );
         Print("trailingStopValue = ", trailingStopValue);
         if( trailingStopValue <= currentStopLoss ) continue;
         RefreshRates();
         if( OrderModify( OrderTicket(), OrderOpenPrice(), trailingStopValue, currentTakeProfit, 0 ) ) continue;
         Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }
   
      if( OrderType() == OP_SELL )
      {
         trailingStopValue = HHV( _symbol, _timeFrame, _bars );
         if( trailingStopValue >= currentStopLoss ) continue;
         RefreshRates();
         if( OrderModify( OrderTicket(), OrderOpenPrice(), trailingStopValue, currentTakeProfit, 0 ) ) continue;
         Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }
   }
}

double OpenPrice( string _symbol, int _magicNumber ){
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      if( OrderSymbol() != _symbol )continue;
      if( OrderMagicNumber() != _magicNumber)continue;
      return(OrderOpenPrice());
   }
   return(0);
}

double HHV( string _symbol, int _timeFrame, int _bars){
   int shift = iHighest(_symbol, _timeFrame, MODE_HIGH,_bars,1);
   return( iHigh(_symbol, _timeFrame, shift) );
}

double LLV( string _symbol, int _timeFrame, int _bars){
   int shift = iLowest(_symbol, _timeFrame, MODE_LOW,_bars,1);
   return( iLow(_symbol, _timeFrame, shift) );
}

// This function returns true if the EA closed a trade on this bar
bool ExitBar( string _symbol, ENUM_TIMEFRAMES _timeFrame, int _magicNumber ){
   for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
      if( OrderSymbol() != _symbol ) continue;
      if( OrderMagicNumber() != _magicNumber )continue;
      if( iBarShift( _symbol, _timeFrame, OrderCloseTime() ) == 0 ) return(true);
   }
   return( false );
}  

void TerminateEA(){
   ExpertRemove();
}

void AlertUser(string _message, bool _sendAlert, bool _sendEmail, bool _sendNotification)
{
   string label = StringConcatenate(Symbol()," ");
   string completeMessage = StringConcatenate(label,_message);
   if(_sendAlert){
      Alert(completeMessage);
   }
   else{
      Print(completeMessage);
   }   
   if(_sendEmail){
      SendEmail("",completeMessage);
   }
   if(_sendNotification){
      SendNotification(completeMessage);
   }
}

void SendEmail( string _expertName, string _message )
{        
   string subject = StringConcatenate(
      "\n", _expertName, Symbol()
   );
   
   string body = StringConcatenate(subject,"\n",_message);
   SendMail(subject,body);
}

bool OrderClosedByStop(string _symbol, int _magicNumber){
   datetime lastOrder_closeTime = 0;
   string lastOrder_comment = "";
   double lastOrder_closePrice = 0;
   double lastOrder_takeProfit = 0;
   double lastOrder_stopLoss = 0;
   int numOrdersSelected = 0;
   for( int i = 0; i <= OrdersHistoryTotal() - 1; i++ )
   {     
      if( !OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) ) continue;
      if( OrderSymbol() != _symbol )continue;
      if( OrderMagicNumber() != _magicNumber ) continue;
      numOrdersSelected += 1;
      if( OrderCloseTime() > lastOrder_closeTime ){
         lastOrder_comment = OrderComment();
         lastOrder_closePrice = OrderClosePrice();
         lastOrder_takeProfit = OrderTakeProfit();
         lastOrder_stopLoss = OrderStopLoss();    
      }
   }
   if(numOrdersSelected == 0 || lastOrder_comment == "[sl]" || lastOrder_comment == "[tp]"){
      //Print(" EA detected order closed by SL or TP ");
      return(true);
   }
   Print(" EA Detected last order not closed by SL or TP");
   return(false);     
}

void GenerateComment(int _xPixels, int _yPixels){   
   int currentTime = TimeHour(TimeCurrent())*100 + TimeMinute(TimeCurrent());   
   double accountBalance = AccountBalance();
   double equity = AccountEquity();
   double openPnL = equity - accountBalance;
   double loss = 0;
   double profit = 0;
   
   if(openPnL >= 0){
      profit = openPnL;
   }
   else{
      loss = -1 * openPnL;
   }  
   double profitPct = profit / accountBalance * 100;
   double lossPct = loss/accountBalance *100;   
   
   
   string com;
   com+="\n=========================";   
   com+="\n   ";
   com+="\n=========================";
   com+="\n                   Positive Profit";
   com+="\n=========================";
   com+="\n-Profit Money = ";
   com+="\n-Profit %       = ";
   com+="\n-Profit Equity = ";
   com+="\n=========================";
   
   CommentXY(com, _xPixels, _yPixels); 
}

void CommentXY( string Str, long x = 0, long y = 0 )
{
   /*--- set window size   
   //--- chart window size
   long x_distance;
   long y_distance;
  
   if(!ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,x_distance)){
      Print("Failed to get the chart width! Error code = ",GetLastError());
      return;
   }
   
   if(!ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,y_distance)){
      Print("Failed to get the chart height! Error code = ",GetLastError());
      return;
   }
   */
   long X = x;//x_distance - x;
   long Y = y;//y_distance - y;  
  
   string Shift = NULL; 
   StringInit(Shift, (int)X >> 2, ' '); 
   if(StringLen(Shift)){
      StringReplace(Str, "\n", "\n" + Shift);   
      Str = Shift + Str;
   }
   if(Y){
      StringInit(Shift, (int)Y / 14, '\n');   
      Str = Shift + Str;
   }    
   Comment(Str);  
}











int ErrorReport( int Error )
{
   switch( Error ){
   //Non Critical Errors
      case 4:{
         Print( "Trade server is busy. Trying once again.." );
         Sleep( 3000 );                                           // Simple Solution
         return( 1 );
      }                                                           // Exit the function
      
      case 135:{
         Print( "_price changed. Trying once again.." );
         RefreshRates();
         return( 1 );
      }
      
      case 136:{
         Print( "No _prices. Waiting for a new tick.." );  
         while( RefreshRates() == false )                         //Till a new tick
             Sleep( 1 );                                          //pause in Loop 
         return( 1 );
      }
      
      case 137:{
         Print( "Broker is Busy. Trying once again.." );
         Sleep( 3000 );
         return( 1 );
      }
      
      case 146:{
         Print( "Trading System is Busy. Trying once again.." );
         Sleep( 500 );
         return( 1 );
      }
      
      // Critical Errors
      case 2:{
         Print( "Common Error." );                                // Terminate the functin
         Sleep( 3000 );
         return( 1 );
      }                                                           // Exit the function
      
      case 5:{
         Print( "Old Terminal Version." );
         return( 0 );
      }
      
      case 64:{
         Print( "Account Blocked." );
         return( 0 );
      }
      
      case 133:{
         Print( "Trading Forbidden." );
         return( 0 );
      }
      
      case 134:{
         Print( "Not Enough Money to Execute Operation" );
         return( 0 );
      }
   }  
   return( 0 );
}