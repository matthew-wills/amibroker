//+------------------------------------------------------------------+
//|                                         EMA_STOCH_PSAR_EA_v1.mq4 |
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
extern int stoch_K_Period = 33;
extern int stoch_D_Period = 5;
extern int stoch_Slowing = 5;

extern double psar_Step = 0.02;
extern double psar_Maximum = 0.2;

extern int ema_Fast_Period = 5;
extern int ema_Slow_Period = 20;

int maxSlippage = 30;// Max Acceptable Slippage 
//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+
double psar_1 = -1;
double emaFast_1 = -1;
double emaSlow_1 = -1;
double stochMain_1 = -1;
double stochSignal_1 = -1;
double stochD_1 = -1;
double close_1 = -1;
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
   if(NewBar(_Symbol,timeFrame)){

      if(numOpenLong > 0){
      //--- manage the open long position
         TradeManagerLong();
      }
      if(numOpenShort > 0){
      //--- manage the open short position   
         TradeManagerShort();
      }
      if(numOpenLong == 0 && signal == 1){
         EnterLongPosition();
      }
      if(numOpenShort == 0 && signal == -1){
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
   emaFast_1 = iMA(_Symbol,timeFrame,ema_Fast_Period,0,MODE_EMA,PRICE_CLOSE,1);
   emaSlow_1 = iMA(_Symbol,timeFrame,ema_Slow_Period,0,MODE_EMA,PRICE_CLOSE,1);
   close_1 = iClose(_Symbol,timeFrame,1);
   psar_1 = iSAR(_Symbol,timeFrame,psar_Step,psar_Maximum,1);
   stochMain_1 = iStochastic(_Symbol,timeFrame,stoch_K_Period,stoch_D_Period,stoch_Slowing,MODE_SMA,0,MODE_MAIN,1);
   stochSignal_1 = iStochastic(_Symbol,timeFrame,stoch_K_Period,stoch_D_Period,stoch_Slowing,MODE_SMA,0,MODE_SIGNAL,1);
   signal = Signal();
}

int Signal(){
   if( emaFast_1 > emaSlow_1 && close_1 > psar_1 && stochMain_1 > stochSignal_1){
      return(1);
   }
   if( emaFast_1 < emaSlow_1 && close_1 < psar_1 && stochMain_1 < stochSignal_1 ){
      return(-1);
   }
   return(0);
}

void EnterLongPosition(){
   EnterPosition(_Symbol,OP_BUY,fixedLotSize,Ask,maxSlippage,0,0,magicNumber,"");
}

void EnterShortPosition(){
   EnterPosition(_Symbol,OP_SELL,fixedLotSize,Ask,maxSlippage,0,0,magicNumber,"");
}

void TradeManagerLong(){
   if(close_1 < psar_1){
      ExitPosition(_Symbol,OP_BUY,maxSlippage,magicNumber);
   }
}

void TradeManagerShort(){
   if(close_1 > psar_1){
      ExitPosition(_Symbol,OP_SELL,maxSlippage,magicNumber);
   }
}

void GenerateComments(){   
   string com = "";
   com+="\n=========================";
   com+="\n System Settings";
   com+="\n=========================";
   com+="\n-Fixed Lot Size = " + DoubleToString(fixedLotSize,2);
   com+="\n-MA_Fast_Period = " + IntegerToString(ema_Fast_Period);
   com+="\n-MA_SLow_Period = " + IntegerToString(ema_Slow_Period);
   com+="\n-PSAR_Step = " + DoubleToString(psar_Step,2);
   com+="\n-PSAR_Maximum = " + DoubleToString(psar_Maximum,2);
   com+="\n-Stochastic_K = "  + IntegerToString(stoch_K_Period);
   com+="\n-Stochastic_D = "  + IntegerToString(stoch_D_Period);
   com+="\n-Stochastic_Slowing = "  + IntegerToString(stoch_Slowing);
   com+="\n=========================";
   com+="\n Indicator Values Troubleshooting";
   com+="\n=========================";   
   com+="\n-timeFrame = " + (string) timeFrame;   
   com+="\n-close[0] = " + DoubleToString(close_1,_Digits);
   com+="\n-ema_Fast[1] = " + DoubleToString(emaFast_1,_Digits);
   com+="\n-ema_Slow[1] = " + DoubleToString(emaSlow_1,_Digits);
   com+="\n-psar[1] = " + DoubleToString(psar_1,_Digits);   
   com+="\n-Stoch_Main[1] = " + DoubleToString(stochMain_1,2);  
   com+="\n-Stoch_Main[1] = " + DoubleToString(stochSignal_1,2);        
   com+="\n-EntrySignal = " + IntegerToString(signal); 
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