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
#include <myFunctionsPro.mqh>

//+------------------------------------------------------------------+
//| User Inputs                                                      |
//+------------------------------------------------------------------+
extern string     GENERAL_SETTINGS     = "----- general settings -----";
extern bool allowTrading = true; // Allow EA to Trade
bool sendAlerts = false; // Generate Alerts 
bool sendEmails = false; // Send Email Alerts
bool sendNotification = false; // Send Notificaitons

extern int magicNumber = 0;// Expert Magic Number
extern ENUM_TIMEFRAMES timeFrame = PERIOD_CURRENT;// Time Frame

extern string     MONEY_MANAGEMENT_SETTINGS     = "----- money management settings -----";
extern double risk = 2; // % risk per trade

extern string     INDICATOR_SETTINGS     = "----- indicator settings -----";
extern int entryBars = 20;
extern int exitBars = 10;

extern bool atrStopOnOff = false;
extern int atrPeriod = 20;
extern double atrMultiplier = 2;

int maxSlippage = 30000;// Max Acceptable Slippage 

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+
double orderOpenPrice = 0;
double atrStopLong = -1;
double atrStopShort = -1;

int numOpenShort = 0;
int numOpenLong = 0;
int numOpenExpert = 0;

double close_1 = -1;
double atr_1 = -1;
double entryHHV = -1;
double exitHHV = -1;
double entryLLV = -1;
double exitLLV = -1;
int signal = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   EventSetTimer( 1 );  
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

   Load_Indicator_Variables();
   Load_Position_Counters();  
      
   //--- run main expert function
   ExpertMain();

}

//+------------------------------------------------------------------+
//| Expert timer function                                             |
//+------------------------------------------------------------------+
void OnTimer()
{
//---

}  
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert Specific functions                                        |
//+------------------------------------------------------------------+

void Load_Indicator_Variables(){
   close_1 = iClose(_Symbol,timeFrame,1);
   atr_1 = iATR(_Symbol,timeFrame,atrPeriod,1);
   
   entryHHV = HHV(_Symbol,timeFrame,entryBars,2);
   entryLLV = LLV(_Symbol,timeFrame,entryBars,2);
   exitHHV = HHV(_Symbol,timeFrame,exitBars,2);
   exitLLV = LLV(_Symbol,timeFrame,exitBars,2);
   
   signal = checkSignal();
}

int checkSignal(){
   if(close_1 >= entryHHV) return(1);
   if(close_1 <= entryLLV) return(-1);
   return(0);
}

void Load_Position_Counters(){
   numOpenLong = CountOrders(_Symbol,OP_BUY,magicNumber);
   numOpenShort = CountOrders(_Symbol,OP_SELL,magicNumber); 
   numOpenExpert = numOpenLong+numOpenShort;
}

void ExpertMain(){
   GenerateComments();  
   //--- if new bar forms on selected timeFrame
   if(NewBar(_Symbol,timeFrame)){
      //--- check for entries    
      if( numOpenExpert == 0){      
         if(signal == 1){
            if(allowTrading == true) EnterLongPosition();
            if(sendNotification == true) AlertUser("Buy Signal Detected",sendAlerts,sendEmails,sendNotification);
         }        
         if(signal == -1){
            if(allowTrading == true)EnterShortPosition();
            if(sendNotification == true) AlertUser("Short Signal Detected",sendAlerts,sendEmails,sendNotification);
         }
      }
      //--- check for exits          
      if(numOpenLong != 0){
         TradeManagerLong();
         return;
      }
      
      if(numOpenShort != 0){
         TradeManagerShort();
         return;
      }         
   }
}

void GenerateComments(){   
   string com = "";
   com+="\n=========================";
   com+="\n System Settings";
   com+="\n=========================";
   com+="\n-Risk / trade $ = " + DoubleToString(risk,2);
   com+="\n=========================";
   com+="\n Indicator Values ";
   com+="\n=========================";   
   com+="\n-timeFrame = " + (string) timeFrame;   
   com+="\n-close[1] = " + DoubleToString(close_1,_Digits);
   com+="\n-Long Entry Parameters";
   com+="\n-HHV[20] = " + DoubleToString(entryHHV,_Digits);
   com+="\n-LLV[10] = " + DoubleToString(exitLLV,_Digits);
   com+="\n-atrStopLong = " + DoubleToString(atrStopLong,_Digits);
   com+="\n\n-Short Entry Parameters";
   com+="\n-HHV[10] = " + DoubleToString(exitHHV,_Digits);
   com+="\n-LLV[20] = " + DoubleToString(entryLLV,_Digits);
   com+="\n-atrStopShort = " + DoubleToString(atrStopShort,_Digits);
   
   Comment(com);
}   

double MoneyManagementCalculator(string _symbol, double _riskPct, double _entryPrice, double _stopPrice){
   double riskAmmount = AccountBalance() * _riskPct * 0.01;
   double tickValue = SymbolInfoDouble(_symbol,SYMBOL_TRADE_TICK_VALUE);
   double stopLossPips = MathAbs(_entryPrice - _stopPrice);
   double lots = riskAmmount / ((stopLossPips) / _Point * tickValue);
   return(lots);
}

void EnterLongPosition(){
   double posSize = MoneyManagementCalculator(_Symbol,risk,Ask,(close_1 - atrMultiplier*atr_1));
   RefreshRates();
   EnterPosition(_Symbol,OP_BUY,posSize,Ask,maxSlippage,0,0,magicNumber,"LongBreakout");
}

void EnterShortPosition(){
   double posSize = MoneyManagementCalculator(_Symbol,risk,Bid,(close_1 - atrMultiplier*atr_1));
   RefreshRates();
   EnterPosition(_Symbol,OP_SELL,posSize,Bid,maxSlippage,0,0, magicNumber,"ShortBreakout");
}

void TradeManagerLong(){
//--- Initialize Stops
   if(orderOpenPrice == 0){
      orderOpenPrice = OpenPrice(_Symbol,magicNumber);
      atrStopLong = close_1 - atrMultiplier * atr_1;
   }

//--- Adjust Stops
   atrStopLong = MathMax(atrStopLong,close_1 - atrMultiplier * atr_1);

//--- Check Stops

   //check LLV Stop
   if( close_1 < exitLLV ){
      ExitOrderLong("LLV Exit");
      if(sendNotification) AlertUser("Exit Long LLVSTOP Signal Detected",sendAlerts,sendEmails,sendNotification);
      return;
   }
   
   //check atrStop
   if( atrStopOnOff && atrStopLong != 0 && close_1 < atrStopLong){
      ExitOrderLong("atrStopLong");
      if(sendNotification) AlertUser("Exit Long ATRSTOP Signal Detected",sendAlerts,sendEmails,sendNotification);
   }                      
   return;
}

void TradeManagerShort(){
//--- Initialize Stops
   if(orderOpenPrice == 0){
      orderOpenPrice = OpenPrice(_Symbol,magicNumber);
      atrStopShort = close_1 + atrMultiplier * atr_1;
   }

//--- Adjust Stops
   atrStopShort = MathMin(atrStopShort,close_1 + atrMultiplier * atr_1);

//--- Check Stops

   //check LLV Stop
   if( close_1 > exitHHV ){
      ExitOrderShort("HHV Exit");
      if(sendNotification) AlertUser("Exit Short HHV STOP Signal Detected",sendAlerts,sendEmails,sendNotification);
      return;
   }
   
   //check atrStop
   if( atrStopOnOff && atrStopShort != 0 && close_1 > atrStopShort){
      ExitOrderShort("atrStopShort");
      if(sendNotification) AlertUser("Exit Long ATRSTOP Signal Detected",sendAlerts,sendEmails,sendNotification);
   }                      
   return;
}

void ExitOrderLong(string comment){  
   AlertUser(StringConcatenate("Attempting to exit LONG position at market - ",comment),sendAlerts,sendEmails,sendNotification);
   ClearStopVariables();
   ExitPosition(_Symbol,OP_BUY,maxSlippage,magicNumber);
}

void ExitOrderShort(string comment){  
   AlertUser(StringConcatenate("Attempting to exit SHORT position at market - ",comment),sendAlerts,sendEmails,sendNotification);
   ClearStopVariables();
   ExitPosition(_Symbol,OP_SELL,maxSlippage,magicNumber);   
}

void ClearStopVariables(){
   orderOpenPrice = 0;
   atrStopLong = 0;
   atrStopShort = 0;
}

////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+//
//|                     my Include Functions                         |//
//+------------------------------------------------------------------+//  
////////////////////////////////////////////////////////////////////////
