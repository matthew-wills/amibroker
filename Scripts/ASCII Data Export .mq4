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
#include <myWatchlists.mqh>

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+

extern int fromDate  = 20170101;     // Begin Date

extern bool allSymbols = true;   // Export All Symbols
extern bool shares = true;       // Export Shares
extern bool forex = true;        // Export Forex
extern bool indicies = true;     // Export Indicies
extern bool commodities = true;  // Export Commodities

extern bool daily = true;
extern bool H4 = false;
extern bool H1 = false;
extern bool M30 = false;
extern bool M15 = false;
extern bool M5 = true;   

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   //---
   if( allSymbols ) Export_EverySymbol();
   if( shares ) Export_Shares();
   if( forex ) Export_Forex();
   if( indicies ) Export_Indicies();
   if( commodities ) Export_Commodities();
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| User Defined Functions                                           |
//+------------------------------------------------------------------+
void Export_EverySymbol(string File = "All_Symbols")
{  
   int BarTally = 0;
   for(int i = 0; i<SymbolsTotal(false); i++)
   {
      string symbol = SymbolName(i,false);
      
      if( SymbolNameCheck( symbol ) == false ) continue;
      
      if (daily == true)   Write_ASCII( symbol, File, PERIOD_D1, fromDate );
      if (H4 == true)      Write_ASCII( symbol, File, PERIOD_H4, fromDate );
      if (H1 == true)      Write_ASCII( symbol, File, PERIOD_H1, fromDate );
      if (M30 == true)     Write_ASCII( symbol, File, PERIOD_M30, fromDate );
      if (M15 == true)     Write_ASCII( symbol, File, PERIOD_M15, fromDate );       
      if (M5 == true)      Write_ASCII( symbol, File, PERIOD_M5, fromDate );

      BarTally += iBars( symbol, PERIOD_D1 );
      Comment(i,"     ",BarTally);
   }
}

void Export_Shares(string File = "SHARES")
{  
   int BarTally = 0;
   for( int i = 0; i < ArraySize( SHARES ); i++ )
   {
      string symbol = SHARES[i];
      
      if( SymbolNameCheck( symbol ) == false ) continue;
      
      if (daily == true)   Write_ASCII( symbol, File, PERIOD_D1, fromDate );
      if (H4 == true)      Write_ASCII( symbol, File, PERIOD_H4, fromDate );
      if (H1 == true)      Write_ASCII( symbol, File, PERIOD_H1, fromDate );
      if (M30 == true)     Write_ASCII( symbol, File, PERIOD_M30, fromDate );
      if (M15 == true)     Write_ASCII( symbol, File, PERIOD_M15, fromDate );       
      if (M5 == true)      Write_ASCII( symbol, File, PERIOD_M5, fromDate );

      BarTally += iBars( symbol, PERIOD_D1 );
      Comment(i,"     ",BarTally);
   }
}

void Export_Forex(string File = "FOREX")
{  
   int BarTally = 0;
   for( int i = 0; i < ArraySize( FOREX ); i++ )
   {
      string symbol = FOREX[i];
      
      if( SymbolNameCheck( symbol ) == false ) continue;
      
      if (daily == true)   Write_ASCII( symbol, File, PERIOD_D1, fromDate );
      if (H4 == true)      Write_ASCII( symbol, File, PERIOD_H4, fromDate );
      if (H1 == true)      Write_ASCII( symbol, File, PERIOD_H1, fromDate );
      if (M30 == true)     Write_ASCII( symbol, File, PERIOD_M30, fromDate );
      if (M15 == true)     Write_ASCII( symbol, File, PERIOD_M15, fromDate );       
      if (M5 == true)      Write_ASCII( symbol, File, PERIOD_M5, fromDate );

      BarTally += iBars( symbol, PERIOD_D1 );
      Comment(i,"     ",BarTally);
   }
}

void Export_Indicies(string File = "INDICIES")
{  
   int BarTally = 0;
   for( int i = 0; i < ArraySize( INDICIES ); i++ )
   {
      string symbol = FOREX[i];
      
      if( SymbolNameCheck( symbol ) == false ) continue;
      
      if (daily == true)   Write_ASCII( symbol, File, PERIOD_D1, fromDate );
      if (H4 == true)      Write_ASCII( symbol, File, PERIOD_H4, fromDate );
      if (H1 == true)      Write_ASCII( symbol, File, PERIOD_H1, fromDate );
      if (M30 == true)     Write_ASCII( symbol, File, PERIOD_M30, fromDate );
      if (M15 == true)     Write_ASCII( symbol, File, PERIOD_M15, fromDate );       
      if (M5 == true)      Write_ASCII( symbol, File, PERIOD_M5, fromDate );

      BarTally += iBars( symbol, PERIOD_D1 );
      Comment(i,"     ",BarTally);
   }
}

void Export_Commodities(string File = "COMMODITIES")
{  
   int BarTally = 0;
   for( int i = 0; i < ArraySize( COMMODITIES ); i++ )
   {
      string symbol = FOREX[i];
      
      if( SymbolNameCheck( symbol ) == false ) continue;
      
      if (daily == true)   Write_ASCII( symbol, File, PERIOD_D1, fromDate );
      if (H4 == true)      Write_ASCII( symbol, File, PERIOD_H4, fromDate );
      if (H1 == true)      Write_ASCII( symbol, File, PERIOD_H1, fromDate );
      if (M30 == true)     Write_ASCII( symbol, File, PERIOD_M30, fromDate );
      if (M15 == true)     Write_ASCII( symbol, File, PERIOD_M15, fromDate );       
      if (M5 == true)      Write_ASCII( symbol, File, PERIOD_M5, fromDate );

      BarTally += iBars( symbol, PERIOD_D1 );
      Comment(i,"     ",BarTally);
   }
}
