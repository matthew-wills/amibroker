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
extern double posSize = 0.1;

extern string     INDICATOR_SETTINGS     = "----- indicator settings -----";
extern int maPeriod = 20;

int maxSlippage = 30000;// Max Acceptable Slippage 

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+

int numOpenShort = 0;
int numOpenLong = 0;
int numOpenExpert = 0;

double close_1 = -1;
double MA1 = -1;

double close_2 = -1;
double MA2 = -1;

double close_3 = -1;
double MA3 = -1;

double close_4 = -1;
double MA4 = -1;

double close_5 = -1;
double MA5 = -1;


double HHV1 = -1;
double LLV1 = -1;

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
   MA1 = iMA(_Symbol,timeFrame,maPeriod,0,MODE_SMMA,PRICE_CLOSE,1);
   
   close_2 = iClose(_Symbol,timeFrame,2);   
   MA2 = iMA(_Symbol,timeFrame,maPeriod,0,MODE_SMMA,PRICE_CLOSE,2);
   
   close_3 = iClose(_Symbol,timeFrame,3);   
   MA3 = iMA(_Symbol,timeFrame,maPeriod,0,MODE_SMMA,PRICE_CLOSE,3);
   
   close_4 = iClose(_Symbol,timeFrame,4);   
   MA4 = iMA(_Symbol,timeFrame,maPeriod,0,MODE_SMMA,PRICE_CLOSE,4);
   
   close_5 = iClose(_Symbol,timeFrame,5);   
   MA5 = iMA(_Symbol,timeFrame,maPeriod,0,MODE_SMMA,PRICE_CLOSE,5);
   
   HHV1 = HHV(_Symbol,timeFrame,maPeriod,5);
   LLV1 = LLV(_Symbol,timeFrame,maPeriod,5);
   
   signal = checkSignal();
}

int checkSignal(){
   if(close_1 >= MA1 && close_2 >= MA2 && close_3 >= MA3 && close_4 >= MA4 && close_5 >= MA5) return(1);
   if(close_1 <= MA1 && close_2 <= MA2 && close_3 <= MA3 && close_4 <= MA4 && close_5 <= MA5) return(-1);
   
   //if( close_1 >= HHV1 ) return(1);
   //if(  close_1 <= LLV1) return(-1);
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
         if(signal >= 0)return;
         ExitOrderLong("reverse");
         if(allowTrading == true)EnterShortPosition();        
      }
      
      if(numOpenShort != 0){
         if(signal <= 0)return;
         ExitOrderShort("reverse");
         if(allowTrading == true)EnterLongPosition(); 
      }         
   }
}

void GenerateComments(){   
   string com = "";
   com+="\n=========================";
   com+="\n System Settings";
   com+="\n=========================";
   com+="\n-Lots = " + DoubleToString(posSize,2);
   com+="\n=========================";
   com+="\n Indicator Values ";
   com+="\n=========================";   
   com+="\n-timeFrame = " + (string) timeFrame;   
   com+="\n-close[1] = " + DoubleToString(close_1,_Digits);
   com+="\n-MA[1] = " + DoubleToString(MA1,_Digits);
   
   Comment(com);
}   


void EnterLongPosition(){
   //double posSize = MoneyManagementCalculator(_Symbol,risk,Ask,(close_1 - atrMultiplier*atr_1));
   RefreshRates();
   EnterPosition(_Symbol,OP_BUY,posSize,Ask,maxSlippage,0,0,magicNumber,"LongBreakout");
}

void EnterShortPosition(){
//   double posSize = MoneyManagementCalculator(_Symbol,risk,Bid,(close_1 - atrMultiplier*atr_1));
   RefreshRates();
   EnterPosition(_Symbol,OP_SELL,posSize,Bid,maxSlippage,0,0, magicNumber,"ShortBreakout");
}

void ExitOrderLong(string comment){  
   AlertUser(StringConcatenate("Attempting to exit LONG position at market - ",comment),sendAlerts,sendEmails,sendNotification);
   ExitPosition(_Symbol,OP_BUY,maxSlippage,magicNumber);
}

void ExitOrderShort(string comment){  
   AlertUser(StringConcatenate("Attempting to exit SHORT position at market - ",comment),sendAlerts,sendEmails,sendNotification);
   ExitPosition(_Symbol,OP_SELL,maxSlippage,magicNumber);   
}


////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+//
//|                     my Include Functions                         |//
//+------------------------------------------------------------------+//  
////////////////////////////////////////////////////////////////////////
