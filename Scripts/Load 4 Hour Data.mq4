//+------------------------------------------------------------------+
//|                                  Force_Data_Download.mq4         |
//|                                  Copyright (C) 2015, Matt Wills  |
//+------------------------------------------------------------------+
#property copyright "Copyright (C) 2015, Matt Wills"
#property link      "http://www.marksmantrading.com"

#property script_show_inputs

extern bool  DebugMe = True;           //Trouble Shooting
extern int   MinBars = 10000;            //Minimum Bars Required   
extern int   MaxForceLoadRetries = 5;  //Max Attempts on one chart

/*
   This script uses ChartNavigate() to ATTEMPT to force-load historical data for all
   found FX symbols and timeframes, by scrolling the chart to the left.
   This forces the broker's MT4 server to send historical datas until it reaches the oldest ones.
   
   Message will go to Experts tab via Print() statement.
   
   Read the message and attempt to manually download those which failed.
   Why?  CrapT4...

 */

int barsWithRetry(long handle, string TempSymbol, int tf) 
{

   int bars = 0;

   long first_bar  = ChartGetInteger(handle,CHART_FIRST_VISIBLE_BAR,0);
   long first_bar0 = first_bar;

   ChartSetInteger(handle,CHART_BRING_TO_TOP,0,true);

   long bars_count=0; //=WindowBarsPerChart();
   
   if ( ! ChartGetInteger(handle,CHART_WIDTH_IN_BARS,0,bars_count) ) 
   {
      return 0;
   }
   
   if ( DebugMe ) 
   {
      Print (TempSymbol," BarCount = ", bars_count);
   }
   
   int count_no_backfill = 0;

   // Scroll to the left to get a backfill from the broker's MT4 server :
   
   while(ChartNavigate(handle,CHART_CURRENT_POS,-bars_count)) 
   {
      
      //--- get the number of the first bar visible on the chart (numeration like in timeseries)
            
      first_bar0 = first_bar;
      first_bar  = ChartGetInteger(handle,CHART_FIRST_VISIBLE_BAR,0);

      if ( DebugMe ) 
      {
         Print(TempSymbol + "First bar number: " + first_bar);
      }
            
      if ( first_bar == first_bar0 ) 
      {

         // No bars was added in the last scrolling : end on backfills ?

         count_no_backfill ++;
         
         if ( count_no_backfill > 1 && first_bar >= MinBars )
         {
            // Two Attepts at scrolling and more than Min Bars on chart : we stop
            break;
         }

         if ( count_no_backfill >= MaxForceLoadRetries ) 
         {
            // Max retries : we stop
            break;
         }
         
         // Keep trying after some tempo : //@@TODO : a better tempo, starting with small values and dynamicly increasing. Also for D1/W1/MN1, max retries must be far lower than 10 !
         Sleep(500);
      } 
      else 
      {
         count_no_backfill = 0;
         //--- wait a bit and continue ...
         Sleep(100);
      }
   }
   
   bars=iBars(TempSymbol,tf);
      
   if (bars > 0)
   {
      return(first_bar+1);
   }
   else
   {
      return 0;
   }
}


bool ForceLoadOneSym(string TempSymbol, int& totbars, string& badperiods) 
{
    
    /* attempt to force-load one symbol. Return false if any iBars() return false
       comes out to be zero, could be waiting for download */
    
    int timeFrames[] = { PERIOD_H4 };

    int     num_tf = ArraySize(timeFrames);
            totbars = 0;
    bool    OK = true;
    
    string  s = TempSymbol + " NumBars(TF): ";
            badperiods = "";

    long handle = 0;
    
    // Open a new and fresh chart for the symbol to be refreshed :
    
    handle = ChartOpen(TempSymbol, PERIOD_H4);
    
    if ( handle <= 0 ) 
    {
        Print("Failed to open chart for symbol : " + TempSymbol);
        return False;
    }
    
    //--- disable auto scroll
    ChartSetInteger(handle,CHART_AUTOSCROLL,false);

    //--- no shift from the right chart border
    ChartSetInteger(handle,CHART_SHIFT,false);

    //--- draw line (faster than candles)
    ChartSetInteger(handle,CHART_MODE,CHART_LINE);

    //--- set the display mode for No volume
    ChartSetInteger(handle,CHART_SHOW_VOLUMES,CHART_VOLUME_HIDE);
    
    ChartSetInteger(handle,CHART_SCALE,0,0);
            
    RefreshRates();
    
    ChartRedraw();
    
    WindowRedraw();   

    for (int j=0; j < num_tf; j++) 
    {

        int tf = timeFrames[j];
        int bars;
        bool tfOK=true;
    
        if ( DebugMe )
        { 
            Print("Trying TF (" + tf + ") on symbol " + TempSymbol);
        }
        
        if ( ! ChartSetSymbolPeriod( handle, TempSymbol, tf ) ) 
        {
            bars = 0; 
            tfOK = false;
        } 
        else 
        {
            RefreshRates();
            ChartRedraw();
            WindowRedraw();

            bars = barsWithRetry(handle,TempSymbol,tf);
            totbars += bars;

            tfOK = true;
            
            if (bars == 0) 
            {
                tfOK = false;
            }
        
            double z = iClose(TempSymbol,tf,0);
            
            if (z == 0.0) 
            {
                tfOK = false;
            }
        
            double y = iMA(TempSymbol,tf,1,0,MODE_SMA,PRICE_MEDIAN,0);
            
            if (y == 0.0) 
            {
                tfOK = false;
            }
        }
        
        s = s + bars+" ("+tf+") ";
        
        if (!tfOK) 
        {
            badperiods = badperiods + " "+tf;
            OK=false; 
        }
    }
    
    ChartClose(handle);
    
    if (OK) 
    {
      Print("Success: "+s);
    } 
    else 
    {
      Print("Fail:    "+s); 
    }
    
    return(OK);
}


void ForceLoadHistoricalData() 
{
    
    string success="", fail="";
    
   // --- Cycle through All Symbols
   for(int i=0; i<SymbolsTotal(false); i++)
   {
        string TempSymbol = SymbolName(i,false);
        
        if (MarketInfo( TempSymbol,MODE_BID) >  0 ) 
        {
            
            bool OK=false;
            int totbars;
            string badperiods="";
            

            
            OK = ForceLoadOneSym(TempSymbol,totbars,badperiods); 
   
            if ( !OK ) 
            {
                Print("Failed:    "+TempSymbol+" after "+MaxForceLoadRetries+" retries, got "+totbars+" bars. Failed periods:"+badperiods);
                fail = fail + " "+TempSymbol+"("+badperiods+")";
            } 
            else 
            {
                success = success + " "+TempSymbol;
                Print("Succeeded: "+TempSymbol+" got "+totbars+" bars");
            }
            
        }
        

    }
    
    
    Print("ForceLoadHistoricalData: successful: "+success);
    
    if (StringLen(fail) == 0) 
    {
         fail="none"; 
    }    
    else 
    {
         Alert("Failed: "+fail); 
    }
    
    Print("ForceLoadHistoricalData: failed: "+fail);
    return;

}

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start() {
//----
    ForceLoadHistoricalData();
//----
    return(0);
}
//+------------------------------------------------------------------+