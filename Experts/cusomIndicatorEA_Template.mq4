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

// remove after final itteration and paste in all functions needed
#include <myFunctionsPro.mqh>

//+------------------------------------------------------------------+
//| User Inputs                                                      |
//+------------------------------------------------------------------+
extern bool sendAlerts = false; // Generate Alerts 
extern bool sendEmails = false; // Send Email Alerts
extern bool sendNotification = false; // Send Notificaitons

extern int magicNumber = 1234567890;// Expert Magic Number
extern ENUM_TIMEFRAMES timeFrame = PERIOD_CURRENT;// Time Frame

extern int maxSlippage = 30;// Max Acceptable Slippage 


//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+

int indShift = 0;
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
void OnTimer()
{
//---

 indShift +=10;

 double customIndicator1 = iCustom(_Symbol,PERIOD_CURRENT,"GannExperiment","M15",1,indShift);
 double customIndicator2 = iCustom(_Symbol,PERIOD_CURRENT,"GannExperiment","M15",2,indShift);
 double customIndicator3 = iCustom(_Symbol,PERIOD_CURRENT,"GannExperiment","M15",3,indShift);
 double customIndicator4 = iCustom(_Symbol,PERIOD_CURRENT,"GannExperiment","M15",4,indShift);
 double customIndicator5 = iCustom(_Symbol,PERIOD_CURRENT,"GannExperiment","M15",5,indShift);
 string comment = "";
 
 comment += "\n-ind_Shift = " + (string)indShift;
 comment += "\n-Buffer_1 = " + (string)customIndicator1;
 comment += "\n-Buffer_2 = " + (string)customIndicator2;
 comment += "\n-Buffer_3 = " + (string)customIndicator3;
 comment += "\n-Buffer_4 = " + (string)customIndicator4;
 comment += "\n-Buffer_5 = " + (string)customIndicator5;
 Comment(comment);
 
 Sleep(1000);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert Specific functions                                        |
//+------------------------------------------------------------------+






////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+//
//|                     my Include Functions                         |//
//+------------------------------------------------------------------+//  
////////////////////////////////////////////////////////////////////////
