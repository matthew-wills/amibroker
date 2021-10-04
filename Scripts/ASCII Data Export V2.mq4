//+------------------------------------------------------------------+
//|                                           ASCII Data Export .mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright (C) 2015, Matt Wills"
#property link      "http://www.marksmantrading.com"

#property script_show_inputs

//+------------------------------------------------------------------+
//| Import Structures Classes and Include Files                      |
//+------------------------------------------------------------------+  
//--- Import Include Files
#include <myFunctions.mqh>

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+

extern int fromDate  = 20000101;     // Begin Date

extern bool daily = true;
extern bool H4 = false;
extern bool H1 = false;
extern bool M30 = false;
extern bool M15 = false;
extern bool M5 = false;   

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Comment("Begining Export");
   Export_EverySymbol();
   Comment("Data Export Complete!");
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| User Defined Functions                                           |
//+------------------------------------------------------------------+
void Export_EverySymbol()
{      
      if (daily == true)   Write_ASCII_ALL( PERIOD_D1, fromDate );
      if (H4 == true)      Write_ASCII_ALL( PERIOD_H4, fromDate );
      if (H1 == true)      Write_ASCII_ALL( PERIOD_H1, fromDate );
      if (M30 == true)     Write_ASCII_ALL( PERIOD_M30, fromDate );
      if (M15 == true)     Write_ASCII_ALL( PERIOD_M15, fromDate );       
      if (M5 == true)      Write_ASCII_ALL( PERIOD_M5, fromDate );       
}

