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
extern double takeProfit_Ratio = 0; // TP Target (multiple of SL)
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
double rsi_1 = 0;
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
//--- if long manual entry detected
   if( numOpenExpert == 0 && CountOrders(_Symbol,OP_BUY,magicNumber) > 0 ){
      numOpenLong = 1;
      flag_TradeOpen = 1;
      TradeManagerLong();
   } 

//--- if short manual entry detected
   if( numOpenExpert == 0 && CountOrders(_Symbol,OP_SELL,magicNumber) > 0 ){
      numOpenShort = 1;
      flag_TradeOpen = 1;
      TradeManagerShort();
   } 
   
//--- load Order variables
   LoadOrderCounters();
   
//--- check for manual exit
   if( flag_TradeOpen == 1 && numOpenExpert == 0) CheckManualExit();



//--- load indicator variables
   LoadIndicatorVariables();

//--- run comments
   GenerateComments(250,10);

//--- if new bar adjust stops
   if( NewBar() ){  
      ManagePositions();
   }

//--- check signal for entries
   if( flag_StopNewTrades == true ) return;
   if( signal > 0 ){
      EnterLongPosition();
   }
   if( signal < 0 ){
      EnterShortPosition();
   }   
   
   Sleep(50);
}

//+------------------------------------------------------------------+
//| Expert Specific Functions                                        |
//+------------------------------------------------------------------+

void LoadOrderCounters(){
   numOpenGlobal = CountOrders("",-1,-1);
   numOpenSymbol = CountOrders(_Symbol,-1,-1);
   numOpenLong = CountOrders(_Symbol,OP_BUY,magicNumber);
   numOpenShort = CountOrders(_Symbol,OP_SELL,magicNumber); 
   numOpenExpert = numOpenLong+numOpenShort;
   if( numOpenExpert > 0 )flag_TradeOpen = 1;  
}

void LoadIndicatorVariables(){
   ma_fast_1 = iMA(_Symbol,timeFrame,maFast,0,MODE_SMMA,PRICE_CLOSE,1);
   ma_slow_1 = iMA(_Symbol,timeFrame,maSlow,0,MODE_EMA,PRICE_CLOSE,1);
   rsi_0 = iRSI(_Symbol,timeFrame,rsiPeriod,PRICE_CLOSE,0);
   rsi_1 = iRSI(_Symbol,timeFrame,rsiPeriod,PRICE_CLOSE,1);
   close_1 = iClose(_Symbol,timeFrame,1);
   high_1 = iHigh(_Symbol,timeFrame,1);
   low_1 = iLow(_Symbol,timeFrame,1);
   trailingStopLong = ma_slow_1 - stopLoss_AdjustPips * _Point;
   trailingStopShort = ma_slow_1 + stopLoss_AdjustPips * _Point;
   signal = Signal();
}

int Signal(){
   if( ma_fast_1 > ma_slow_1 && rsi_0 >= rsiBuyLevel && rsi_1 >= rsiBuyLevel){
      return(1);
   }
   if( ma_fast_1 < ma_slow_1 && rsi_0 <= rsiSellLevel && rsi_1 <= rsiSellLevel){
      return(-1);
   }
   return(0);
}

void ManagePositions(){
//--- load indicators and position counter   
   RefreshRates(); 
   if(numOpenLong > 0){
      TradeManagerLong();
      return;
   }
   if(numOpenShort > 0){
      TradeManagerShort();
      return;
   }
}

void GenerateComments(int _xPixels, int _yPixels){   
   string com;
   com+="\n\n=========================";   
   com+="\n MA & RSI Trend Following System";
   com+="\n=========================";
   com+="\n System Settings";
   com+="\n=========================";
   com+="\n\n-New Trades Allowed? = " + (string)allowNewTrades;
   com+="\n\n-Max Open Trades = " + IntegerToString(maxGlobalPositions);
   com+="\n\n-Num Open Positions = " + IntegerToString(numOpenGlobal);
   com+="\n\n-Fixed Lot Size = " + DoubleToString(fixedLotSize,2);
   com+="\n\n-SL_Adjust_Pips = " + DoubleToString(stopLoss_AdjustPips,0);
   com+="\n\n-TP_Target = " + DoubleToString(takeProfit_Ratio,2);
   com+="\n\n-Money at Risk (%)= " + DoubleToString(riskPct,2);
   com+="\n\n=========================";
   com+="\n Indicator Settings";
   com+="\n=========================";
   com+="\n\n-MA_Fast_Period = " + IntegerToString(maFast);
   com+="\n\n-MA_SLow_Period = " + IntegerToString(maSlow);
   com+="\n\n-RSI_Period = " + IntegerToString(rsiPeriod,2);
   com+="\n\n-RSI_BuyLevel = "  + DoubleToString(rsiBuyLevel,2);
   com+="\n\n-RSI_SellLevel = "  + DoubleToString(rsiSellLevel,2);
   com+="\n\n=========================";
   if(showIndicators){
   com+="\n Indicator Values Troubleshooting";
   com+="\n=========================";   
   com+="\n\n-timeFrame = " + (string) timeFrame;   
   com+="\n\n-rsi[0] = " + DoubleToString(rsi_0,2);
   com+="\n\n-rsi[1] = " + DoubleToString(rsi_1,2);
   com+="\n\n-ma_Fast[1] = " + DoubleToString(ma_fast_1,_Digits);
   com+="\n\n-ma_Slow[1] = " + DoubleToString(ma_slow_1,_Digits);
   com+="\n\n-EntrySignal = " + IntegerToString(signal);
   com+="\n\n-trailingStopLong[1] = " + DoubleToString(trailingStopLong,_Digits);
   com+="\n\n-trailingStopShort[1] = " + DoubleToString(trailingStopShort,_Digits);
   com+="\n\n-flag_TradeOpen = " + IntegerToString(flag_TradeOpen);     
   } 
   
   Comment(com);
}

void CheckManualExit(){
//--- check for manual exit on every tick
   if( flag_TradeOpen == 1 && manualExitStopsNewTrades){
      if( !OrderClosedByStop(_Symbol,magicNumber) ){
         flag_StopNewTrades = true;
         AlertUser("Manual Exit Detected. Expert Removed From Chart",sendAlerts,sendEmails,sendNotification);
         ExpertRemove();   
      }
   }
}

void EnterLongPosition(){
   if( !allowNewTrades ) return;
   if( numOpenGlobal >= maxGlobalPositions ) return;
   if( numOpenSymbol > 0) return;
   
   double stopLoss = MathMin( trailingStopLong, low_1 - stopLoss_AdjustPips * _Point );
   double stopLossPips = MathAbs(Ask - stopLoss);
   double takeProfit = Ask + stopLossPips * takeProfit_Ratio;
   double tickValue = MarketInfo(_Symbol,MODE_TICKVALUE);
   double riskAmmount = AccountBalance() * riskPct * 0.01;
   double lots = 0;
   if( ((stopLossPips) / _Point * tickValue) != 0 ){
      lots = riskAmmount / ((stopLossPips) / _Point * tickValue);   
   }
   
   if(riskPct == 0) lots = fixedLotSize;
   if(takeProfit_Ratio == 0) takeProfit = 0;
   
   if(!EnterPosition(_Symbol,OP_BUY,lots,Ask,maxSlippage,stopLoss,takeProfit,magicNumber,"") ){
      AlertUser("Long Entry Failed",sendAlerts,sendEmails,sendNotification);       
      return;
   }
}

void EnterShortPosition(){
   if( !allowNewTrades ) return;
   if( numOpenGlobal >= maxGlobalPositions ) return;
   if( numOpenSymbol > 0) return;
   
   double stopLoss = MathMax( trailingStopShort, high_1 + stopLoss_AdjustPips * _Point );
   double stopLossPips = MathAbs(Bid - stopLoss);
   double takeProfit = Bid - stopLossPips * takeProfit_Ratio;
   double tickValue = MarketInfo(_Symbol,MODE_TICKVALUE);
   double riskAmmount = AccountBalance() * riskPct * 0.01;
   double lots = 0;
   if( ((stopLossPips) / _Point * tickValue) != 0 ){
      lots = riskAmmount / ((stopLossPips) / _Point * tickValue);   
   }
    
   if(riskPct == 0) lots = fixedLotSize;
   if(takeProfit_Ratio == 0) takeProfit = 0;
   
   if(!EnterPosition(_Symbol,OP_SELL,lots,Bid,maxSlippage,stopLoss,takeProfit,magicNumber,"") ){
      AlertUser("Short Entry Failed",sendAlerts,sendEmails,sendNotification);       
      return;
   }   
}

void TradeManagerLong(){
//--- adjust trailing stop
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){  
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      if( OrderSymbol() != _Symbol ) continue;      
      if( OrderMagicNumber() != magicNumber ) continue;
      if( OrderType() != OP_BUY ) continue;
   
      double currentOpenPrice = OrderOpenPrice();
      double currentStopLoss = OrderStopLoss();
      double currentTakeProfit = OrderTakeProfit();         
      
      if( ( currentStopLoss == NULL || trailingStopLong > currentStopLoss ) ){
         currentStopLoss = trailingStopLong;
      }
      
      if(currentTakeProfit == NULL && takeProfit_Ratio != 0){
         currentTakeProfit = currentOpenPrice + takeProfit_Ratio * MathAbs(currentOpenPrice - currentStopLoss);
      }
      
      if( takeProfit_Ratio == 0){
         currentTakeProfit = 0;
      }
      
      if(currentStopLoss != OrderStopLoss() || currentTakeProfit != currentTakeProfit){
         RefreshRates();
         if( OrderModify( OrderTicket(), OrderOpenPrice(), trailingStopLong, currentTakeProfit, 0 ) ) return;
         Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError() );     
      }   
   }
   return;
}

void TradeManagerShort(){
//--- adjust trailing stop
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){  
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      if( OrderSymbol() != _Symbol ) continue;      
      if( OrderMagicNumber() != magicNumber ) continue;
      if( OrderType() != OP_SELL ) continue;
      

      double currentOpenPrice = OrderOpenPrice();   
      double currentTakeProfit = OrderTakeProfit();
      double currentStopLoss = OrderStopLoss();
              
      if( ( currentStopLoss == NULL || trailingStopShort < currentStopLoss ) && close_1 < trailingStopShort){
         currentStopLoss = trailingStopShort;
      }
      
      if(currentTakeProfit == NULL && takeProfit_Ratio != 0){
         currentTakeProfit = currentOpenPrice - takeProfit_Ratio * MathAbs(currentOpenPrice - currentStopLoss);
      }
      
      if( takeProfit_Ratio == 0){
         currentTakeProfit = 0;
      }
          
      if(currentStopLoss != OrderStopLoss() || currentTakeProfit != currentTakeProfit){
         RefreshRates();
         if( OrderModify( OrderTicket(), OrderOpenPrice(), trailingStopShort, currentTakeProfit, 0 ) ) return;
         Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError() );     
      }
   }
   return;
}
               ////////////////////////////////////////////////////////////////////////
               //+------------------------------------------------------------------+//
               //|                     my Include Functions                         |//
               //+------------------------------------------------------------------+//  
               ////////////////////////////////////////////////////////////////////////

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