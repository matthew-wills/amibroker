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
enum SL_MODE{  ATR, // SL - defined with ATR
               POINTS // SL - defined by POINTS
            };
            
enum EA_MODE{  TF, //TF - Trend Following
               MR  // MR - Mean Reversion
            };            

string systemName = "Incrementum_IntraDay_Bias";

extern string     GENERAL_SETTINGS     = "----- general settings -----";
extern EA_MODE expertMode = TF; // EA Mode
extern bool allowTrading = true; // Allow EA to Trade
bool sendAlerts = false; // Generate Alerts 
bool sendEmails = false; // Send Email Alerts
extern bool sendNotification = true; // Send Notificaitons

extern int magicNumber = 123;// Expert Magic Number
extern ENUM_TIMEFRAMES timeFrame = PERIOD_H1;// Time Frame

extern string     MONEY_MANAGEMENT_SETTINGS     = "----- money management settings -----";
extern double defaultPosSize = 1;

extern string     DAY_FILTER     = "----- Day of Week Filter Settings -----";
extern bool trade_Monday = true;
extern bool trade_Tuesday = true;
extern bool trade_Wednesday = true;
extern bool trade_Thursday = true;
extern bool trade_Friday = true;

extern string     TIME_FILTER     = "----- Time Filter Settings -----";
extern bool trade_00 = true;
extern bool trade_01 = true;
extern bool trade_02 = true;
extern bool trade_03 = true;
extern bool trade_04 = true;
extern bool trade_05 = true;
extern bool trade_06 = true;
extern bool trade_07 = true;
extern bool trade_08 = true;
extern bool trade_09 = true;
extern bool trade_10 = true;
extern bool trade_11 = true;
extern bool trade_12 = true;
extern bool trade_13 = true;
extern bool trade_14 = true;
extern bool trade_15 = true;
extern bool trade_16 = true;
extern bool trade_17 = true;
extern bool trade_18 = true;
extern bool trade_19 = true;
extern bool trade_20 = true;
extern bool trade_21 = true;
extern bool trade_22 = true;
extern bool trade_23 = true;

extern string     INDICATOR_SETTINGS     = "----- indicator settings -----";

extern SL_MODE stopLossMode = ATR; // StopLoss Operation Mode
extern int atrPeriod = 1; // ATR Stop Period
extern double atrMultiplier = 1.0; // ATR Stop Multiplier

extern double slLong = 30; //Fixed StopLoss Long - (Set this to 0 to turn off)
extern double slShort = 20; //Fixed StopLoss Short - (Set this to 0 to turn off)

extern int nBarExitLong = 2; // Exit Long after X num of candles - (Set this to -1 to turn off)
extern int nBarExitShort = 2; // Exit Short after X num of candles - (Set this to -1 to turn off)
int maxSlippage = 30000;// Max Acceptable Slippage 

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+
double orderOpenPrice = 0;
double stopLossPointsLong = 0;
double stopLossPointsShort = 0;

int barsSinceEntry = -1;
int breakEvenFlag= 0;

int numOpenShort = 0;
int numOpenLong = 0;
int numOpenExpert = 0;

double close1 = -1;
double high2 = -1;
double low2 = -1;

int signal = 0;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   EventSetTimer( 1 ); 
   Load_Indicator_Variables();
    
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
   if(NewBar(_Symbol,timeFrame)){
      Load_Indicator_Variables();   
      Load_Position_Counters();      
      ExpertMain();
      GenerateComments();  
   }
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
   if( stopLossMode == ATR ){
      stopLossPointsLong = atrMultiplier * iATR(_Symbol,timeFrame,atrPeriod,1);
      stopLossPointsShort = atrMultiplier * iATR(_Symbol,timeFrame,atrPeriod,1);
   }
   else{
      stopLossPointsLong = slLong*_Point;
      stopLossPointsShort = slShort*_Point;
   }  
   close1 = iClose(_Symbol,timeFrame,1);
   high2 = iHigh(_Symbol,timeFrame,2);
   low2 = iLow(_Symbol,timeFrame,2);
   
   if( expertMode == TF ){
      if( close1 > high2 ){ 
         signal = 1;
      }
      else if( close1 < low2 ){
         signal = -1;
      }
      else{
         signal = 0;
      }
   }

   if( expertMode == MR ){
      if( close1 > high2 ){ 
         signal = -1;
      }
      else if( close1 < low2 ){
         signal = 1;
      }
      else{
         signal = 0;
      }
   }    
}

void Load_Position_Counters(){
   numOpenLong = CountOrders(_Symbol,OP_BUY,magicNumber);
   numOpenShort = CountOrders(_Symbol,OP_SELL,magicNumber); 
   numOpenExpert = numOpenLong+numOpenShort;
}

void ExpertMain(){
   //--- check for entries    
   if( numOpenExpert == 0){
      if(TimeDayOfWeek(TimeCurrent())==1 && trade_Monday==false)return;
      if(TimeDayOfWeek(TimeCurrent())==2 && trade_Tuesday==false)return;
      if(TimeDayOfWeek(TimeCurrent())==3 && trade_Wednesday==false)return;
      if(TimeDayOfWeek(TimeCurrent())==4 && trade_Thursday==false)return;
      if(TimeDayOfWeek(TimeCurrent())==5 && trade_Friday==false)return;
      
      if(signal == 1 ){
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

void GenerateComments(){   
   double posSize = defaultPosSize; 
   string stopLossModeLabel = "ATR";
   if (stopLossMode != ATR) stopLossModeLabel = "Fixed";
   
   string com = "";
   com+="\n====================";
   com+="\n "+systemName;
   com+="\n====================\n";
   if(expertMode == TF) com+="\n-EA_MODE = Trend Following";
   if(expertMode == MR) com+="\n-EA_MODE = Mean Reversion";
   com+="\n-timeFrame = " + (string) timeFrame; 
   com+="\n-positionSize (lots) = " + DoubleToString(posSize,2);
   if(stopLossMode == ATR) com+="\n-stopLossATR = " + (string)atrMultiplier + " * ATR(" + (string) atrPeriod+")";
   if(stopLossMode != ATR) com+="\n-stopLossPoints_Long = " + (string)slLong;
   if(stopLossMode != ATR) com+="\n-stopLossPoints_Short = " + (string)slShort;    
   com+="\n-stopLossLong = " + (string)slLong;
   com+="\n-stopLossShort = " + (string)slShort;
   com+="\n-TimeFilter = " + (string)TimeHour(iTime(_Symbol,timeFrame,1)) + " allow_Trade = "+(string)timeFilter();
   if(numOpenExpert!=0){
      com+="\n\n====================";
      com+="\n Open Position Info ";
      com+="\n====================\n"; 
      com+="\n-OrderOpenPrice = " + DoubleToString(orderOpenPrice,_Digits);
      com+="\n-BarsSinceEntry = " + IntegerToString(BarsSinceEntry(_Symbol,timeFrame,magicNumber));   
   }
   Comment(com);
}   

bool timeFilter(){
   int barTime = TimeHour(iTime(_Symbol,timeFrame,1));
   if( barTime == 00 && trade_00 == true ) return(true);
   if( barTime == 01 && trade_01 == true ) return(true);
   if( barTime == 02 && trade_02 == true ) return(true);
   if( barTime == 03 && trade_03 == true ) return(true);
   if( barTime == 04 && trade_04 == true ) return(true);
   if( barTime == 05 && trade_05 == true ) return(true);
   if( barTime == 06 && trade_06 == true ) return(true);
   if( barTime == 07 && trade_07 == true ) return(true);
   if( barTime == 08 && trade_08 == true ) return(true);
   if( barTime == 09 && trade_09 == true ) return(true);
   if( barTime == 10 && trade_10 == true ) return(true);
   if( barTime == 11 && trade_11 == true ) return(true);
   if( barTime == 12 && trade_12 == true ) return(true);
   if( barTime == 13 && trade_13 == true ) return(true);
   if( barTime == 14 && trade_14 == true ) return(true);
   if( barTime == 15 && trade_15 == true ) return(true);
   if( barTime == 16 && trade_16 == true ) return(true);
   if( barTime == 17 && trade_17 == true ) return(true);
   if( barTime == 18 && trade_18 == true ) return(true);
   if( barTime == 19 && trade_19 == true ) return(true);
   if( barTime == 20 && trade_20 == true ) return(true);
   if( barTime == 21 && trade_21 == true ) return(true);
   if( barTime == 22 && trade_22 == true ) return(true);
   if( barTime == 23 && trade_23 == true ) return(true);
   return(false);  
}

void EnterLongPosition(){
   double posSize = defaultPosSize;
   RefreshRates();
   //check time filter
   if(!timeFilter()) return;
   if(slLong != 0){EnterPosition(_Symbol,OP_BUY,posSize,Ask,maxSlippage,Ask-stopLossPointsLong,0,magicNumber,"LongBreakout");}
   else{EnterPosition(_Symbol,OP_BUY,posSize,Ask,maxSlippage,0,0,magicNumber,"LongBreakout");}

}

void EnterShortPosition(){   
   double posSize = defaultPosSize;
   RefreshRates();
   //check time filter
   if(!timeFilter()) return;
   if(slShort != 0){EnterPosition(_Symbol,OP_SELL,posSize,Bid,maxSlippage,Bid+stopLossPointsShort,0,magicNumber,"ShortBreakout");}
   else{EnterPosition(_Symbol,OP_SELL,posSize,Bid,maxSlippage,0,0,magicNumber,"ShortBreakout");}
}

void TradeManagerLong(){
//--- Check Stops 
   if( BarsSinceEntry(_Symbol,timeFrame,magicNumber) > nBarExitLong + 2 && nBarExitLong != -1){
      ExitOrderLong("nBarExit");
      if(sendNotification) AlertUser("ExitLong - BarsSinceEntry > nBarExit",sendAlerts,sendEmails,sendNotification); 
   }
   
   //check ReverseSignal Stop
   if( signal == -1 ){
      ExitOrderLong("ReverseSignal - Exit");
      if(sendNotification) AlertUser("ExitLong - Reverse Signal Detected",sendAlerts,sendEmails,sendNotification);
      EnterShortPosition();
      return;
   }                     
}

void TradeManagerShort(){
//--- Check Stops
   if( BarsSinceEntry(_Symbol,timeFrame,magicNumber) > nBarExitShort + 2 && nBarExitShort != -1){
      ExitOrderShort("nBarExit");
      if(sendNotification) AlertUser("Exit Short - BarsSinceEntry > nBarExit",sendAlerts,sendEmails,sendNotification); 
   }

   //check ReverseSignal Stop
   if( signal == 1 ){
      ExitOrderShort("ReverseSignal - Exit");
      if(sendNotification) AlertUser("Exit Short - Reverse Signal Detected",sendAlerts,sendEmails,sendNotification);
      EnterLongPosition();
      return;
   }
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
