//+------------------------------------------------------------------+
//|                                          ASCII Data Exporter.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input datetime fromDate  = D'2010.01.01';    // Begin Date

input bool combinedFiles = true;
input bool individualFiles = false;

input bool D1 = true;
input bool H4 = false;
input bool H1 = false;
input bool M30 = false;
input bool M15 = false;
input bool M5 = false;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Comment("Data Exporter Running");      
   
   if(individualFiles == true)
   {
      Export_EverySymbol_IndividualFiles();
   }
   if(combinedFiles == true)
   {
      Export_EverySymbol_OneFile();    
   }
   
   Comment("Data Exporter Run Complete for Today");
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if( NewDay() && TimeDayOfWeek(TimeCurrent()) == 0 )
   {
      if(individualFiles == true)
      {
         Export_EverySymbol_IndividualFiles();
      }
      if(combinedFiles == true)
      {
         Export_EverySymbol_OneFile();    
      }
   }
 
  }
//+------------------------------------------------------------------+

bool NewDay()
{
   static datetime LastDay;
   datetime ThisDay = TimeDay(TimeCurrent());
   if( ThisDay != LastDay )
   {
      LastDay = ThisDay;
      return (true);
   }
   else
      return (false);
}

void Export_EverySymbol_IndividualFiles(string File = "All_Symbols")
{     
   Comment("Export Running ... Individual Files");  
      
      if (D1 == true)      
      {
         Comment("Exporting Daily Data ... Individual Files");
         for(int i = 0; i<SymbolsTotal(false); i++)
         {
            string symbol = SymbolName(i,false);
            Write_ASCII( symbol, PERIOD_D1, fromDate );
         }         
      } 
      if (H4 == true)      
      {
         Comment("Exporting 4HR Data ... Individual Files");
         for(int i = 0; i<SymbolsTotal(false); i++)
         {
            string symbol = SymbolName(i,false);
            Write_ASCII( symbol, PERIOD_H4, fromDate );
         }         
      } 
      if (H1 == true)      
      {
         Comment("Exporting 1HR Data ... Individual Files");
         for(int i = 0; i<SymbolsTotal(false); i++)
         {
            string symbol = SymbolName(i,false);
            Write_ASCII( symbol, PERIOD_H1, fromDate );
         }         
      } 
      if (M30 == true)      
      {
         Comment("Exporting 30Min Data ... Individual Files");
         for(int i = 0; i<SymbolsTotal(false); i++)
         {
            string symbol = SymbolName(i,false);
            Write_ASCII( symbol, PERIOD_M30, fromDate );
         }         
      }
      if (M15 == true)      
      {
         Comment("Exporting 15Min Data ... Individual Files");
         for(int i = 0; i<SymbolsTotal(false); i++)
         {
            string symbol = SymbolName(i,false);
            Write_ASCII( symbol, PERIOD_M15, fromDate );
         }         
      }
      if (M5 == true)      
      {
         Comment("Exporting 5Min Data ... Individual Files");
         for(int i = 0; i<SymbolsTotal(false); i++)
         {
            string symbol = SymbolName(i,false);
            Write_ASCII( symbol, PERIOD_M5, fromDate );
         }         
      }        
   
   Comment("Export Complete ... Individual Files");     
}

void Export_EverySymbol_OneFile()
{     
   Comment("Export Running ... One File");  
   
   if (D1 == true)      
   {
      Comment("Exporting Daily Data ... One File");  
      Write_ASCII_ALL( PERIOD_D1, fromDate );         
   } 
   if (H4 == true)
   {
      Comment("Exporting 4 Hourly Data ... One File");  
      Write_ASCII_ALL( PERIOD_H4, fromDate );
   }   
   if (H1 == true)      
   {
      Comment("Exporting Hourly Data ... One File");  
      Write_ASCII_ALL( PERIOD_H1, fromDate );
   }  
   if (M30 == true)     
   {
      Comment("Exporting 30 Min Data ... One File");  
      Write_ASCII_ALL( PERIOD_M30, fromDate );
   }       
   if (M15 == true)
   {     
      Comment("Exporting 15 Min Data ... One File");  
      Write_ASCII_ALL( PERIOD_M15, fromDate );  
   }      
   if (M5 == true)      
   {
      Comment("Exporting 5 Min Data ... One File");  
      Write_ASCII_ALL( PERIOD_M5, fromDate ); 
   }
   
   Comment("Export Complete ... One File");      
}

void Write_ASCII(string symbol, ENUM_TIMEFRAMES timeframe, datetime startDate) 
{
   int handle = FileOpen("ASCII_DataExport_Individual\\" + EnumToString(timeframe) + "\\" + symbol + ".txt", FILE_CSV|FILE_WRITE|FILE_ANSI,',');

   datetime firstDateTerminal = (datetime)SeriesInfoInteger(symbol,timeframe,SERIES_FIRSTDATE);
   datetime firstDateServer = (datetime)SeriesInfoInteger(symbol,timeframe,SERIES_SERVER_FIRSTDATE);
   datetime today = TimeCurrent();

   if(startDate < firstDateServer) startDate = firstDateServer;

   int numBars;
     
   if(startDate >= firstDateTerminal)
   {
      numBars = Bars(symbol,timeframe,startDate,today);
   }
   else
   {
      numBars = Bars(symbol,timeframe);
   }
   
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int copied = CopyRates(symbol,timeframe,startDate,today,rates);
         
   double ask, bid, spread = 0;
   ask = SymbolInfoDouble(symbol,SYMBOL_ASK);
   bid = SymbolInfoDouble(symbol,SYMBOL_BID);
   int digits = (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   if ( ask == 0 || bid == 0 )
   {
      spread = 0;
   }
   else
   {
      spread = ( ask - bid ) / ask;
   }
   
   string symboltxt = symbol;
   StringReplace(symboltxt,"#","");
   
   if ( handle > 0 ) 
   {
      FileWrite(handle,"SYMBOL","DATE","TIME","OPEN","HIGH","LOW","CLOSE","VOLUME","SPREAD");
      for(int i = numBars-1; i >= 0; i --)
      {
         FileWrite(handle,        
                     symboltxt,
                     TimeToString(rates[i].time,TIME_DATE),
                     TimeToString(rates[i].time,TIME_SECONDS),
                     DoubleToString(rates[i].open,digits),
                     DoubleToString(rates[i].high,digits),
                     DoubleToString(rates[i].low,digits),
                     DoubleToString(rates[i].close,digits),
                     DoubleToString(rates[i].tick_volume,digits),
                     DoubleToString(spread,5) 
                  );
      }
      FileClose( handle );
   }
}


void Write_ASCII_ALL( ENUM_TIMEFRAMES timeframe, datetime BeginDate) 
{
   int handle = FileOpen("ASCII_DataExport_All\\" + EnumToString(timeframe) + ".txt", FILE_CSV|FILE_WRITE|FILE_ANSI,',');

   if ( handle > 0 ) 
   {
      FileWrite(handle,"SYMBOL","DATE","TIME","OPEN","HIGH","LOW","CLOSE","VOLUME","SPREAD");
      
      datetime today = TimeCurrent();
      for(int i = 0; i<SymbolsTotal(false); i++)
      {
         string symbol = SymbolName(i,false);
         
         string symboltxt = symbol;
         StringReplace(symboltxt,"#","");
         
         datetime firstDateTerminal = (datetime)SeriesInfoInteger(symbol,timeframe,SERIES_FIRSTDATE);
         datetime firstDateServer = (datetime)SeriesInfoInteger(symbol,timeframe,SERIES_SERVER_FIRSTDATE);
         
         datetime startDate = BeginDate;
         
         if(startDate < firstDateServer) startDate = firstDateServer;
      
         int numBars;
           
         if(startDate >= firstDateTerminal)
         {
            numBars = Bars(symbol,timeframe,startDate,today);
         }
         else
         {
            numBars = Bars(symbol,timeframe);
         }
         
         MqlRates rates[];
         ArraySetAsSeries(rates,true);
         int copied = CopyRates(symbol,timeframe,startDate,today,rates);
               
         double ask, bid, spread = 0;
         ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
         int digits = (int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
         if ( ask == 0 || bid == 0 )
         {
            spread = 0;
         }
         else
         {
            spread = ( ask - bid ) / ask;
         }
         
         for(int j = numBars-1; j >= 0; j --)
         {
            FileWrite(handle,        
                        symboltxt,
                        TimeToString(rates[j].time,TIME_DATE),
                        TimeToString(rates[j].time,TIME_SECONDS),
                        DoubleToString(rates[j].open,digits),
                        DoubleToString(rates[j].high,digits),
                        DoubleToString(rates[j].low,digits),
                        DoubleToString(rates[j].close,digits),
                        DoubleToString(rates[j].tick_volume,digits),
                        DoubleToString(spread,5) 
                     );
         }        
      }
      FileClose( handle );  
   }   
}

double Spread (string symbol)
{
   double ask = SymbolInfoDouble(symbol,SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol,SYMBOL_BID);
   
   if( bid != 0)
   {
      return( (ask - bid) / bid );
   }
   else
   {
      return (1);
   }
}

//--- Is the Symbol in the Market watchlist
bool SymbolNameCheck( string symbol )
{
    for( int s = 0; s < SymbolsTotal( false ); s++ )
    {
        if( symbol == SymbolName( s, false ) )
            return( true );
    }

    return( false );
}
