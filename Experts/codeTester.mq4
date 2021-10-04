//+------------------------------------------------------------------+
//|                                                MA_RSI_System.mq4 |
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
MqlTick  m_tick;               // structure of tick;

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+
//--- External Inputs
extern string     GENERAL_SETTINGS     = "----- general settings -----";
extern bool sendAlerts = false; // Generate Alerts
extern bool showIndicators = true; // Show Indicator Values in Comments
extern bool allowNewTrades = true; // Allow New Trades
extern bool manualExitStopsNewTrades = true; // Manual Exit Will Remove Expert

bool sendEmails = false; //
bool sendNotification = false;

extern ENUM_TIMEFRAMES timeFrame = PERIOD_CURRENT; // Set timeFrame for Expert
extern int magicNumber = NULL;

extern string     INDICATOR_SETTINGS     = "----- indicator settings -----";
extern int maFast = 3; // MA Fast Period
extern int maSlow = 15; // MA Slow Period
extern int rsiPeriod = 14; //RSI Period
extern int rsiBuyLevel = 60; // RSI Buy Level
extern int rsiSellLevel = 40; // RSI Sell Period

extern string     MONEY_MANAGEMENT_SETTINGS     = "----- money management settings -----";
extern int maxGlobalPositions = 10; // Max Open Trades
extern double fixedLotSize = 0.01; // Fixed Lot Size
extern double stopLoss_AdjustPips = 0; // Stop Loss Adjust Pips
extern double takeProfit_Ratio = 4; // TP Target (multiple of SL)
extern double riskPct = 0.5;// Money at Risk (% of account)

int maxSlippage = 30;

//--- Global Variables
int flag_TradeOpen = 0;
int flag_FirstCandle = 0;
int flag_StopNewTrades = false;

int numOpenGlobal = 0;
int numOpenSymbol = 0;
int numOpenShort = 0;
int numOpenLong = 0;
int numOpenExpert = 0;

double ma_fast_1 = 0;
double ma_slow_1 =  0;
double rsi_0 =  0;
int signal = 0;
double close_1 = 0;
double low_1 =  0;
double high_1 = 0;
double trailingStopLong =  0;
double trailingStopShort =  0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---  
   //---start timer
   EventSetTimer( 1 );  
   Comment("Expert initialized ... waiting for new tick");
   
//---
return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   Comment("Expert Removed... please see log for reason");

}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick(){
   Executor();
}

//+------------------------------------------------------------------+
//| Expert Main Function                                             |
//+------------------------------------------------------------------+
void Executor(){

//--- if new bar adjust stops

     TradeManagerLong();

   Sleep(1000);
}

//+------------------------------------------------------------------+
//| Expert Specific Functions                                        |
//+------------------------------------------------------------------+


void TradeManagerLong(){
//--- adjust trailing stop
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){  
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      if( OrderSymbol() != _Symbol ) continue;      
      if( OrderType() != OP_BUY ) continue;
      
      RefreshRates();
      if( ModifyPosition(_Symbol,OrderTicket(),1.11590,OrderTakeProfit())) return;
      Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError() );     

   }
   return;
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

               ////////////////////////////////////////////////////////////////////////
               //+------------------------------------------------------------------+//
               //|                     my Include Functions                         |//
               //+------------------------------------------------------------------+//  
               ////////////////////////////////////////////////////////////////////////


// This function returns true when a new bar is placed on the chart
bool NewBar(){
   static datetime lastBarOpenTime;
   datetime thisBarOpenTime = Time[0];
   if( thisBarOpenTime != lastBarOpenTime ){
      lastBarOpenTime = thisBarOpenTime;
      return(true);
   }  
   return(false);
}

int CountOrders( string _symbol = "", int nOrderType = -1, int _magicNumber = -1 ){
   int nOrderCount = 0;
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      if( _magicNumber != -1 && OrderMagicNumber() != _magicNumber )continue;
      if( _symbol != "" && OrderSymbol() != _symbol ) continue; 
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

bool EnterPosition( string _symbol, int _orderType, double _lots, double _price, int _slippage, double _stopLoss, double _takeProfit, int _magicNumber, string _label )
{
   double lots = RoundVolume( _symbol, _lots );
   double entry_price = RoundPrice(_symbol, _price );   
   double stoploss = RoundPrice( _symbol, _stopLoss  );
   double takeprofit = RoundPrice( _symbol, _takeProfit);
  
   RefreshRates();
   if( !OrderSend( _symbol, _orderType, _lots, _price, _slippage, stoploss, takeprofit, _label, _magicNumber, 0, NULL ) )
   {
     ErrorReport( GetLastError() );
     return(false);
   }
   return(true);
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
         while( RefreshRates() == false )                            //Till a new tick
             Sleep( 1 );                                             //pause in Loop 
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
         Print( "Common Error." );                                   // Terminate the functin
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