//+------------------------------------------------------------------+
//|                                         EMA_STOCH_PSAR_EA_v2.mq4 |
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

//+------------------------------------------------------------------+
//| User Inputs                                                      |
//+------------------------------------------------------------------+
extern string     GENERAL_SETTINGS     = "----- general settings -----";
bool sendAlerts = false; // Generate Alerts 
bool sendEmails = false; // Send Email Alerts
bool sendNotification = false; // Send Notificaitons

extern int magicNumber = 0;// Expert Magic Number
extern ENUM_TIMEFRAMES timeFrame = PERIOD_CURRENT;// Time Frame

extern string     MONEY_MANAGEMENT_SETTINGS     = "----- money management settings -----";
extern double fixedLotSize = 0.01; // Fixed Lot Size

extern string     INDICATOR_SETTINGS     = "----- indicator settings -----";
extern int rsiPeriod = 4;
extern int rsiBuyLevel = 20;
extern int rsiShortLevel = 80;

extern int takeProfit = 200; // takeProfit (points)
extern int stopLoss = 200; // stopLoss (points)

int maxSlippage = 30;// Max Acceptable Slippage 
//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+
double rsi = -1;
int signal = 0;

int numOpenShort = 0;
int numOpenLong = 0;
int numOpenExpert = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
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
   Load_Indicator_Variables();
   Load_Position_Counters();
      
   //--- run main expert function
   ExpertMain();
}

//+------------------------------------------------------------------+
//| Expert Specific functions                                        |
//+------------------------------------------------------------------+
void ExpertMain(){
//--- if new bar forms on selected timeFrame
   GenerateComments();  
   
   RefreshRates();
   if(NewBar(_Symbol,timeFrame)){
      
      if(signal == 1){
         EnterLongPosition();
      }
      if(signal == -1){
         EnterShortPosition();
      }
               
   }
}

void Load_Position_Counters(){
   numOpenLong = CountOrders(_Symbol,OP_BUY,magicNumber);
   numOpenShort = CountOrders(_Symbol,OP_SELL,magicNumber); 
   numOpenExpert = numOpenLong+numOpenShort;
}

void Load_Indicator_Variables(){
   rsi = iRSI(_Symbol,timeFrame,rsiPeriod,PRICE_CLOSE,0);
   signal = Signal();
}

int Signal(){
   if( rsi < rsiBuyLevel){
      return(1);
   }
   if( rsi > rsiShortLevel){
      return(-1);
   }
   return(0);
}

void EnterLongPosition(){
   EnterPosition(_Symbol,OP_BUY,fixedLotSize,Ask,maxSlippage,0, Ask + takeProfit*_Point,magicNumber,"");
}

void EnterShortPosition(){
   EnterPosition(_Symbol,OP_SELL,fixedLotSize,Bid,maxSlippage,0, Bid - takeProfit*_Point, magicNumber,"");
}

void GenerateComments(){   
   string com = "";
   com+="\n=========================";
   com+="\n System Settings";
   com+="\n=========================";
   com+="\n-Fixed Lot Size = " + DoubleToString(fixedLotSize,2);
   com+="\n-rsi_Period = " + DoubleToString(rsiBuyLevel,2);   
   com+="\n-rsi_Short = " + DoubleToString(rsiBuyLevel,2);
   com+="\n-rsi_Long = " + DoubleToString(rsiShortLevel,2);
   com+="\n-Take Profit Points = "  + IntegerToString(takeProfit);
   com+="\n-Stop Loss Points = "  + IntegerToString(stopLoss);
   com+="\n=========================";
   com+="\n Indicator Values ";
   com+="\n=========================";   
   com+="\n-rsi[0] = " + DoubleToString(rsi,_Digits);    
   com+="\n-Signal[0] = " + IntegerToString(signal); 
   Comment(com);
}   

////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+//
//|                     my Include Functions                         |//
//+------------------------------------------------------------------+//  
////////////////////////////////////////////////////////////////////////

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