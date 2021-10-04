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

string systemName = "Incrementum_LowsHighs_Breakout";

extern string     GENERAL_SETTINGS     = "----- general settings -----";
extern bool allowTrading = true; // Allow EA to Trade
bool sendAlerts = false; // Generate Alerts 
bool sendEmails = false; // Send Email Alerts
bool sendNotification = false; // Send Notificaitons

extern int magicNumber = 123;// Expert Magic Number
extern ENUM_TIMEFRAMES timeFrame = PERIOD_D1;// Time Frame

extern string     MONEY_MANAGEMENT_SETTINGS     = "----- money management settings -----";
extern double defaultPosSize = 0.01;
extern bool useMoneyManagement = false;
extern double posSizeStep = 0.01; // lots / $1000.00 Balance

extern string     TIME_FILTER     = "----- Time Filter Settings -----";
extern bool trade_Monday = true;
extern bool trade_Tuesday = true;
extern bool trade_Wednesday = true;
extern bool trade_Thursday = true;
extern bool trade_Friday = true;

extern string     INDICATOR_SETTINGS     = "----- indicator settings -----";
extern int breakoutBars = 40; // HHV / LLV Lookback

extern bool useBreakEvenStop = true; // BreakEven Stop On/Off
extern double breakEvenPoints = 500; // Minimum Points before stop moves to break even
extern double breakEvenProfitPoints  = 200; // Points in Profit after break even

extern SL_MODE stopLossMode = ATR; // StopLoss Operation Mode
extern double stopLossFixed = 1000;// Fixed StopLoss in Points
extern int atrPeriod = 1; // ATR Stop Period
extern double atrMultiplier = 2; // ATR Stop Multiplier

extern double tpLong = 1500; //Fixed TakeProfit Long - (Set this to 0 to turn off)
extern double tpShort = 1500; //Fixed TakeProfit Short - (Set this to 0 to turn off)

extern int nBarExit = 0; // Exit Position after X num of candles - (Set this to 0 to turn off)

int maxSlippage = 30000;// Max Acceptable Slippage 

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+
double orderOpenPrice = 0;
double stopLossPoints = 0;
int barsSinceEntry = -1;
int breakEvenFlag = 0;

int numOpenShort = 0;
int numOpenLong = 0;
int numOpenExpert = 0;

double HHV = -1;
double LLV = -1;

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
   }
   
   Load_Position_Counters();      
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
   if( stopLossMode == ATR ){
      stopLossPoints = atrMultiplier * iATR(_Symbol,timeFrame,atrPeriod,1);
   }
   else{
      stopLossPoints = stopLossFixed*_Point;
   }  
   HHV = HHV(_Symbol,timeFrame,breakoutBars,1);
   LLV = LLV(_Symbol,timeFrame,breakoutBars,1);
}

void Load_Position_Counters(){
   numOpenLong = CountOrders(_Symbol,OP_BUY,magicNumber);
   numOpenShort = CountOrders(_Symbol,OP_SELL,magicNumber); 
   numOpenExpert = numOpenLong+numOpenShort;
}

void ExpertMain(){
   GenerateComments();  

   //--- check for entries    
   if( numOpenExpert == 0){
      ClearStopVariables();   
      
      if(TimeDayOfWeek(TimeCurrent())==1 && trade_Monday==false)return;
      if(TimeDayOfWeek(TimeCurrent())==2 && trade_Tuesday==false)return;
      if(TimeDayOfWeek(TimeCurrent())==3 && trade_Wednesday==false)return;
      if(TimeDayOfWeek(TimeCurrent())==4 && trade_Thursday==false)return;
      if(TimeDayOfWeek(TimeCurrent())==5 && trade_Friday==false)return;
      
      if(Ask > HHV ){
         if(allowTrading == true) EnterLongPosition();
         if(sendNotification == true) AlertUser("Buy Signal Detected",sendAlerts,sendEmails,sendNotification);
      }        
      if(Bid < LLV){
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
   if (useMoneyManagement) posSize = MoneyManagementCalculator(_Symbol,posSizeStep);  
   string stopLossModeLabel = "ATR";
   if (stopLossMode != ATR) stopLossModeLabel = "Fixed";
   
   string com = "";
   com+="\n====================";
   com+="\n "+systemName;
   com+="\n====================\n";
   com+="\n-positionSize (lots) = " + DoubleToString(posSize,2);
   if(stopLossMode == ATR) com+="\n-stopLossATR = " + (string)atrMultiplier + " * ATR(" + (string) atrPeriod+")";
   if(stopLossMode != ATR) com+="\n-stopLossPoints = " + (string)stopLossFixed;   
   com+="\n-breakEvenLevel = " + (string)breakEvenPoints;
   com+="\n-breakEvenProfit = " + (string)breakEvenProfitPoints;
   com+="\n-takeProfitLong = " + (string)tpLong;
   com+="\n-takeProfitShort = " + (string)tpShort;
   com+="\n\n====================";
   com+="\n Indicator Values ";
   com+="\n====================\n";   
   com+="\n-timeFrame = " + (string) timeFrame;   
   com+="\n-HHV = " + DoubleToString(HHV,_Digits);
   com+="\n-LLV = " + DoubleToString(LLV,_Digits);
   if(numOpenExpert!=0){
      com+="\n\n====================";
      com+="\n Open Position Info ";
      com+="\n====================\n"; 
      com+="\n-OrderOpenPrice = " + DoubleToString(orderOpenPrice,_Digits);
      com+="\n-BarsSinceEntry = " + IntegerToString(BarsSinceEntry(_Symbol,timeFrame,magicNumber));   
   }
   Comment(com);
}   

double MoneyManagementCalculator(string _symbol, double _lotsPerThousand){
   double lots = MathFloor(AccountBalance()/1000)*_lotsPerThousand;
   return(lots);
}

void EnterLongPosition(){
   double posSize = defaultPosSize;
   if (useMoneyManagement) posSize = MoneyManagementCalculator(_Symbol,posSizeStep);
   RefreshRates();
   if(tpLong != 0){
      EnterPosition(_Symbol,OP_BUY,posSize,Ask,maxSlippage,Ask-stopLossPoints,Ask+tpLong*_Point,magicNumber,"LongBreakout");
   }
   else{
      EnterPosition(_Symbol,OP_BUY,posSize,Ask,maxSlippage,Ask-stopLossPoints,0,magicNumber,"LongBreakout");
   }
}

void EnterShortPosition(){   
   double posSize = defaultPosSize;
   if (useMoneyManagement) posSize = MoneyManagementCalculator(_Symbol,posSizeStep);
   RefreshRates();
   if(tpShort != 0){
      EnterPosition(_Symbol,OP_SELL,posSize,Bid,maxSlippage,Bid+stopLossPoints,Bid-tpShort*_Point, magicNumber,"ShortBreakout");
   }else{
      EnterPosition(_Symbol,OP_SELL,posSize,Bid,maxSlippage,Bid+stopLossPoints,0, magicNumber,"ShortBreakout");
   }
}

void TradeManagerLong(){
//--- Initialize Stops
   if(orderOpenPrice == 0){
      orderOpenPrice = OpenPrice(_Symbol,magicNumber);
      breakEvenFlag = 0;
   }

//--- Adjust Stops
   if( breakEvenFlag == 0 && useBreakEvenStop){
      if( Bid - orderOpenPrice > breakEvenPoints * _Point ){
         Print("BreakEvenActivated - Long");
         if(sendNotification)AlertUser("Moving Stop to breakEven", sendAlerts,sendEmails,sendNotification);
         if(ModifyPosition(_Symbol,OrderTakeProfit(),orderOpenPrice+breakEvenProfitPoints*_Point,magicNumber)){
            breakEvenFlag = 1;
         }
      }
   }

//--- Check Stops
   
   if( BarsSinceEntry(_Symbol,timeFrame,magicNumber) > nBarExit && nBarExit != 0){
      ExitOrderLong("nBarExit");
      if(sendNotification) AlertUser("Exit Long - BarsSinceEntry > nBarExit",sendAlerts,sendEmails,sendNotification); 
   }
   
   //check LLV Stop
   if( Ask < LLV ){
      ExitOrderLong("LLV Exit");
      if(sendNotification) AlertUser("Exit Long - LLVSTOP Signal Detected",sendAlerts,sendEmails,sendNotification);
      return;
   }
                        
}

void TradeManagerShort(){
//--- Initialize Stops
   if(orderOpenPrice == 0){
      orderOpenPrice = OpenPrice(_Symbol,magicNumber);
   }

//--- Adjust Stops
   if( breakEvenFlag == 0 && useBreakEvenStop){
      if( orderOpenPrice - Ask > breakEvenPoints * _Point ){
         Print("BreakEvenActivated - Short");
         if(sendNotification)AlertUser("Moving Stop to breakEven", sendAlerts,sendEmails,sendNotification);
         if(ModifyPosition(_Symbol,OrderTakeProfit(),orderOpenPrice-breakEvenProfitPoints*_Point,magicNumber)){
            breakEvenFlag = 1;
         }
      }
   }

//--- Check Stops

   if( BarsSinceEntry(_Symbol,timeFrame,magicNumber) > nBarExit && nBarExit != 0){
      ExitOrderShort("nBarExit");
      if(sendNotification) AlertUser("Exit Short - BarsSinceEntry > nBarExit",sendAlerts,sendEmails,sendNotification); 
   }

   //check LLV Stop
   if( Bid > HHV ){
      ExitOrderShort("HHV Exit");
      if(sendNotification) AlertUser("Exit Short - HHV STOP Signal Detected",sendAlerts,sendEmails,sendNotification);
      return;
   }
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
   breakEvenFlag = 0;
}

////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+//
//|                     my Include Functions                         |//
//+------------------------------------------------------------------+//  
////////////////////////////////////////////////////////////////////////
