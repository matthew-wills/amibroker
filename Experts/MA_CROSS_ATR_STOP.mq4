//+------------------------------------------------------------------+
//|                                            MA_CROSS_ATR_STOP.mq4 |
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

#include <myFunctionsPro.mqh>
//+------------------------------------------------------------------+
//| User Inputs                                                      |
//+------------------------------------------------------------------+
extern bool sendAlerts = false; // Generate Alerts 
extern bool sendEmails = false; // Send Email Alerts
extern bool allowNewTrades = true; // Allow New Trades

extern int magicNumber = 1234567890;// Magic Number
extern ENUM_TIMEFRAMES timeFrame = PERIOD_CURRENT;// Time Frame

extern int maxOpenGlobal = 20; // Max Open Trades In This Terminal
extern int maxOpenSymbol = 1; //Max Open Trades On This Symbol

extern double defaultLots = 0.01; //Default Position Size
extern double riskPct = 1;// Risk % of Account Balance

extern int maFastPeriod = 50; //Fast Moving Average Period
extern ENUM_MA_METHOD maFastType = MODE_SMA; // Fast Moving Average Type
extern int maFastShift = 0; //Fast Moving Average Shift

extern int maSlowPeriod = 200; //Slow Moving Average Period
extern ENUM_MA_METHOD maSlowType = MODE_SMA; // Slow Moving Average Type
extern int maSlowShift = 0; //Slow Moving Average Shift

extern int atrStopPeriod = 14; //ATR Stop Period
extern double atrStopMultiple = 3; //ATR Stop Multiple 

extern int maxSlippage = 30;// Max Acceptable Slippage 

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+

//--- Flags

//--- Position Counters
int numOpenGlobal = 0;
int numOpenSymbol = 0;
int numOpenLong = 0;
int numOpenShort = 0;

//--- Indicators
double maFast_1 = 0;
double maFast_2 = 0;
double maSlow_1 = 0;
double maSlow_2 = 0;
double signal = 0;
double atrStopLong = 0;
double atrStopShort = 0;   

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---start timer
   EventSetTimer( 1 );  
//--- refresh all indcators and counters
   Load_Indicators();
   Load_Position_Counters();
//--- report successful 
   Comment("Expert Initialized Successfully");

return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//--- report expert removed
   Comment("Expert Removed - Please See Log For Details");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   Executor();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTimer()
{
//---
   Executor();
}  
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert Main Function                                             |
//+------------------------------------------------------------------+
void Executor(){
//---
   if(NewBar(_Symbol,timeFrame)){
   //--- run main operation
      Load_Indicators();
      Load_Position_Counters();
   
      if(numOpenLong > 0){
      //--- manage the open long position
         TradeManagerLong();
         return;
      }
      if(numOpenShort > 0){
      //--- manage the open short position   
         TradeManagerShort();
         return;
      }
      if(signal == 1){
         EnterLongPosition();
         return;
      }
      if(signal == -1){
         EnterShortPosition();
         return;
      }         
   }
   
   if(NewMinute()){
   //--- refresh comments
   
   }
}

//+------------------------------------------------------------------+
//| Expert Specific Functions                                        |
//+------------------------------------------------------------------+

void Load_Indicators(){
   maFast_1 = iMA(_Symbol,timeFrame,maFastPeriod,maFastShift,maFastType,PRICE_CLOSE,1);
   maFast_2 = iMA(_Symbol,timeFrame,maFastPeriod,maFastShift,maFastType,PRICE_CLOSE,2);
   maSlow_1 = iMA(_Symbol,timeFrame,maSlowPeriod,maSlowShift,maSlowType,PRICE_CLOSE,2);
   maSlow_2 = iMA(_Symbol,timeFrame,maSlowPeriod,maSlowShift,maSlowType,PRICE_CLOSE,2);
   atrStopLong = iClose(_Symbol,timeFrame,1) - atrStopMultiple * iATR(_Symbol,timeFrame,atrStopPeriod,1);
   atrStopShort = iClose(_Symbol,timeFrame,1) + atrStopMultiple * iATR(_Symbol,timeFrame,atrStopPeriod,1);
   signal = CheckSignal();
}

void Load_Position_Counters(){
   numOpenGlobal = CountOrders(NULL,-1,-1);
   numOpenLong = CountOrders(_Symbol,OP_BUY,magicNumber);
   numOpenShort = CountOrders(_Symbol,OP_SELL,magicNumber);
}

int CheckSignal(){
   if( maFast_1 > maSlow_1 && maFast_2 <= maSlow_2){
      return(1);
   }
   if(maFast_1 < maSlow_1 && maFast_2 >= maSlow_2){
      return(-1);
   }
   return(0);
}

void EnterLongPosition(){
   if(!allowNewTrades)return;
   if(numOpenGlobal >= maxOpenGlobal )return;
   if(numOpenLong > 0)return;
   
   RefreshRates();
   
   double lots = defaultLots;
   if(riskPct != 0){
      lots = MoneyManagementCalculator(_Symbol,riskPct,Bid,atrStopLong);
   }    
   EnterPosition(_Symbol,OP_BUY,lots,Ask,maxSlippage,atrStopLong,0,magicNumber,"");
}

void EnterShortPosition(){
   if(!allowNewTrades)return;
   if(numOpenGlobal >= maxOpenGlobal )return;
   if(numOpenShort > 0)return;
 
   RefreshRates();
   
   double lots = defaultLots;
   if(riskPct != 0){
      lots = MoneyManagementCalculator(_Symbol,riskPct,Bid,atrStopLong);
   }      
   EnterPosition(_Symbol,OP_SELL,lots,Bid,maxSlippage,atrStopShort,0,magicNumber,"");
}

double MoneyManagementCalculator(string _symbol, double _riskPct, double _entryPrice, double _stopPrice){
   double riskAmmount = AccountBalance() * _riskPct * 0.01;
   double tickValue = SymbolInfoDouble(_symbol,SYMBOL_TRADE_TICK_VALUE);
   double stopLossPips = MathAbs(_entryPrice - _stopPrice);
   double lots = riskAmmount / ((stopLossPips) / _Point * tickValue);
   return(lots);
}

void TradeManagerLong(){
//--- adjust trailing stop
   TrailingStop(_Symbol,OP_BUY,atrStopLong,magicNumber);
}

void TradeManagerShort(){
//--- adjust trailing stop
   TrailingStop(_Symbol,OP_SELL,atrStopShort,magicNumber);
}

void TrailingStop(string _symbol, ENUM_ORDER_TYPE _orderType, double _trailingStopLevel, int _magicNumber){
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){  
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      
      if( OrderSymbol() != _Symbol ) continue;      
      if( OrderMagicNumber() != magicNumber ) continue;
      if( OrderType() != _orderType ) continue;
      
      int orderTicket = OrderTicket();
      double currentOpenPrice = OrderOpenPrice();
      double currentStopLoss = OrderStopLoss();
      double currentTakeProfit = OrderTakeProfit();         
      
      if(_orderType == OP_BUY){
         RefreshRates();
         if( ( currentStopLoss == NULL || _trailingStopLevel > currentStopLoss ) && Bid > _trailingStopLevel){
            currentStopLoss = _trailingStopLevel;
         }        
         if( currentStopLoss != OrderStopLoss() ){
            
            if( ModifyPosition(_symbol, orderTicket, currentStopLoss, currentTakeProfit) ) return;
            Print( "TrailingStopLong() Failed" );     
         } 
      }
           
      if(_orderType == OP_SELL){
         if( ( currentStopLoss == NULL || _trailingStopLevel < currentStopLoss ) && Ask < _trailingStopLevel){
            currentStopLoss = _trailingStopLevel;
         }        
         if( currentStopLoss != OrderStopLoss() ){
            RefreshRates();
            if( ModifyPosition(_symbol, orderTicket, currentStopLoss, currentTakeProfit) ) return;
            Print( "TrailingStopLong() Failed" );     
         }       
      }
   }
}


////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+//
//|                     my Include Functions                         |//
//+------------------------------------------------------------------+//  
////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+

