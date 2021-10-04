
//+------------------------------------------------------------------+
//|                                                     Marksman.mq4 |
//|                                Copyright 2015, Matthew Wills Inc |
//|                                http://www.MarksmanTrading.com.au |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015,   Matthew Wills Inc"
#property link      "http://www.MarksmanTrading.com.au//"
#property version   "1.5"
#property strict

//+------------------------------------------------------------------+
//| Import Structures Classes and Include Files                      |
//+------------------------------------------------------------------+  
//--- Import Include Files
#include <myFunctions.mqh>
#include <myWatchlists.mqh>
                              

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+

extern double spreadCutOff = 0.0050;

int Pause = 30;

string NewLine = "\n";
string DoubleSpace = "\n\n";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    EventSetTimer( 1 );
    return( INIT_SUCCEEDED );
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit( const int reason )
{
    EventKillTimer();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+

void OnTimer()
{   
    RefreshRates();
    Executor();
}

//+------------------------------------------------------------------+
//| EA Execution Functions                                           |
//+------------------------------------------------------------------+


//--- Manage all Open Postions
void Executor()
{
    //--- Initialize Counters

    int   SymbolError = 0,
          VariableError = 0,
          TotalErrors = 0,
          SymbolCount = 0;
    double
          TotalSpread = 0,
          AverageSpread = 0,
          MaxSpread = 0,
          MinSpread = 0;
          
    string fileName = "SpreadWatchlist.csv";  
    int fileHandle = FileOpen(fileName,FILE_CSV|FILE_READ | FILE_WRITE,',');

    // --- Cycle through Watchlist
    for( int i = 0; i < ArraySize( SHARES ); i++ )
    {
        datetime StartTimer = TimeLocal(); // Log the time that the TradeManager begins its run

        //--- Assign Symbol
        string SYB = SHARES[i];


        //--- Conduct Validation Checks
        if( SymbolNameCheck( SYB ) == false )
        {

            SymbolError += 1;
            continue;
        }

        double   Ask0 = 0,
                 Bid0 = 0,
                 Spread = 0;


        //--- Calculate Variables Variables
        Ask0 = MarketInfo( SYB, MODE_ASK );
        Bid0 = MarketInfo( SYB, MODE_BID );

        //--- Where possible ensure variables have been called and loaded correctly

        if( Ask0 == 0 || Bid0 == 0 )
        {
            Print( SYB, " Failed Variable Error Check..." );
            VariableError += 1;
            continue;
        }
        
        //--- Display cycle summary information

        Comment(
            DoubleSpace, "Scanning ... ", i + 1, " of ", ArraySize( SHARES ), " ... ", DoubleToString( 100 * ( i + 1 ) / ArraySize( SHARES ), 0 ), "%",
            DoubleSpace, "Current Symbol ... ", SYB,
            DoubleSpace, "Symbol Name Not Found ... ", SymbolError,
            DoubleSpace, "Indicator Failure ... ", VariableError,
            DoubleSpace, "Total Errors ... ", SymbolError + VariableError,
            DoubleSpace,
            DoubleSpace, "Symbol = ", Symbol(), " ~ ", SymbolInfoString( Symbol(), SYMBOL_CURRENCY_BASE ), " ~ ", "[ ", MarketOpenTime( Symbol() ), " : ", MarketCloseTime( Symbol() ) + 4, " ]",
            DoubleSpace, "Current Time = ", TimeToStr( Time[0], TIME_DATE ), " ", TimeToStr(TimeCurrent(),TIME_MINUTES),
            DoubleSpace,
            DoubleSpace, "Spread = ", DoubleToString( (Ask0-Bid0)/Ask0, 4 ),
            DoubleSpace,
            DoubleSpace, "Symbol in Count = ", SymbolCount,
            DoubleSpace, "Average Spread = ",DoubleToString(AverageSpread,5),
            DoubleSpace, "Max Spread = ", DoubleToString(MaxSpread,5)
        );
        

        if( i == ArraySize( SHARES ) - 1 )
        {
            Print( "Run Time TradeManager  = ", TimeSeconds( TimeLocal() - StartTimer ), " Seconds" );
            Sleep( 10000 );
        }


        //--- Calculate Spread 
      Spread = ( ( Ask0 - Bid0 ) / Ask0 );
      
      if(Spread > MaxSpread )
      {
         MaxSpread = Spread;
      }
      
      if(Spread >= spreadCutOff)
      {
         Print(SYB," ... Too expensive");
      }
      
      if(Spread < spreadCutOff)
      {
         SymbolCount += 1;
         TotalSpread = TotalSpread += Spread;
         AverageSpread = TotalSpread / SymbolCount;
         FileWrite(fileHandle,SYB,Spread);
      }     
    }
    
    FileClose(fileHandle);
}
