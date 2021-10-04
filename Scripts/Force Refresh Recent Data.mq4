//+------------------------------------------------------------------+
//|                                  Force_Data_Download.mq4         |
//|                                  Copyright (C) 2015, Matt Wills  |
//+------------------------------------------------------------------+
#property copyright "Copyright (C) 2015, Matt Wills"
#property link      "http://www.marksmantrading.com"

#property script_show_inputs

input bool  DebugMe = True;      //Trouble Shooting 


/*
   This script uses chart change and refreshrates() to attempt to refresh all the current data for each symbol in the MT4 Window. This is primarily to ensure that all basket type EA's
   are working with the correct dates and sequence of data
*/


#define MaxForceLoadRetries 10

bool RefreshChart(long handle, string TempSymbol, int tf) 
{  
   ChartSetInteger(handle,CHART_BRING_TO_TOP,0,True);

   // RefreshRates() and check for correct response MT4
   
   RefreshRates();
   
   ChartRedraw();
    
   WindowRedraw();
   
   Sleep(500);
   
   return(True);
}


bool ForceLoadOneSym( string TempSymbol, int& totbars, string& badperiods ) 
{
    
    /* attempt to force-load one symbol. Return false if any iBars() return false
       comes out to be zero, could be waiting for download */
    
    int timeFrames[] = { PERIOD_M5 };

    int     num_tf = ArraySize(timeFrames);
            totbars = 0;
            
    bool    OK = false;
    
    string  s = TempSymbol;

    long handle = 0;
    
    // Open a new and fresh chart for the symbol to be refreshed :
    
    handle = ChartOpen(TempSymbol, PERIOD_D1);
    
    if ( handle <= 0 ) 
    {
        Print("Failed to open chart for symbol : " + TempSymbol);
        return False;
    }
    
    //--- enable auto scroll
    ChartSetInteger(handle,CHART_AUTOSCROLL,true);

    //--- enable shift from the right chart border
    ChartSetInteger(handle,CHART_SHIFT,true);

    //--- draw line (faster than candles)
    ChartSetInteger(handle,CHART_MODE,CHART_LINE);

    //--- set the display mode for No volume
    ChartSetInteger(handle,CHART_SHOW_VOLUMES,CHART_VOLUME_HIDE);
    
    ChartSetInteger(handle,CHART_SCALE,0,0);  

    for (int j=0; j < num_tf; j++) 
    {

        int tf = timeFrames[j];
        bool ChartRefreshed = False;
        bool tfOK = true;
    
        if ( DebugMe )
        { 
            Print("Trying TF (" + tf + ") on symbol " + TempSymbol);
        }
        
        if ( ! ChartSetSymbolPeriod( handle, TempSymbol, tf ) ) 
        {
            tfOK = false;
        } 
        else 
        {
            tfOK = true;
            OK = RefreshChart(handle,TempSymbol,tf);                               
        }
        
        if (!tfOK) 
        {
            OK = false; 
        }
    }
    
    ChartClose(handle);
    
    if ( OK == true) 
    {
      Print("Success: " + s);
    } 
    else 
    {
      Print("Fail:    " + s); 
    }
    
    return( OK );
}


void ForceLoadHistoricalData() 
{
    
    string  success = "", 
            fail    = "";
    
   // --- Cycle through All Symbols
   for( int i = 0; i < SymbolsTotal(false); i++ )
   {
        string TempSymbol = SymbolName( i,false );
        
        if ( MarketInfo( TempSymbol,MODE_BID ) >  0 ) 
        {
            
            bool OK = false;
            int totbars;
            string badperiods = "";
            
            OK = ForceLoadOneSym(TempSymbol,totbars,badperiods); 
   
            if ( !OK ) 
            {
                Print( "Failed:    " + TempSymbol + " after " + MaxForceLoadRetries + " retries, was not refreshed " );
                fail = fail + " " + TempSymbol + " ( " + badperiods + " ) ";
            } 
            else 
            {
                success = success + " "+TempSymbol;
                Print( "Succeeded: " + TempSymbol + " was refreshed ");
            }
            
        }       

    }
    
    
    Print("ForceLoadHistoricalData: successful: "+success);
    
    if (StringLen(fail) == 0) 
    {
         fail = "none"; 
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