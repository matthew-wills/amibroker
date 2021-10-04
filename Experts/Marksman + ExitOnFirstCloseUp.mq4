
//+------------------------------------------------------------------+
//|                                                     Marksman.mq4 |
//|                                Copyright 2015, Matthew Wills Inc |
//|                                http://www.MarksmanTrading.com.au |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Matthew Wills Inc"
#property link      "http://www.MarksmanTrading.com.au//"
#property version   "1.5"
#property strict

//+------------------------------------------------------------------+
//| Import Structures Classes and Include Files                      |
//+------------------------------------------------------------------+  
//--- Import Include Files
#include <myFunctions.mqh>
#include <myWatchlists.mqh>

MqlTick  m_tick;               // structure of tick;

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+
//--- External Inputs
extern string expertName = "MarksMan V2.0";            // Name of EA
extern int comissionDate = 20171030;                   // YYYYMMDD  
extern int magicNumber = 51;
extern ENUM_TIMEFRAMES timeFrame = PERIOD_D1;          // TimeFrame

enum myEnum
   {
      Opt0, // GKFX_ALL
      Opt1, // GKFX_US
      Opt2, // GKFX_UK
      Opt3, // GKFX_EU
      Opt4, // JFD_ALL
      Opt5, // JFD_US
      Opt6, // JFD_UK
      Opt7, // JFD_EU
      Opt8, // FXPRO_ALL
   };
extern myEnum watchlist = Opt0;

extern bool entryFlag = true;          //Permission to Enter Trades
extern bool errorPrint = false;        //Print Errors
extern bool emailReport = false;       //TroubleShooting Email
extern bool reportHistory = true;      //Create Excel History File
extern bool hiddenStops = true;        //EA Controls Stops
extern double maxSpread = 0.0030;      //Max Allowable Spread 

extern int minBars = 350;              //Min Bars Rqd

extern int maxGlobal = 20;             //Max Pos in MT4
extern int maxSymbols = 4;             //Max Pos in EA
extern double accountPercent = 1.00;   //Ratio of Account Allocated
extern double fixedFraction = 0.2;     //fixedFraction

extern int maxShareValue = 500;        //Max Share Value
extern int minShareValue = 1;          //Min Share Value

extern int rsiPeriod = 4;
extern int rsiEntryLevel = 30;
extern double entryLimit = 1.5;

extern int filter_P1 = 40;             //Filter Cut Off
extern int filter_P2 = 600;            //Filter Array Size

extern int volatility_P1 = 2;          //ATR Filter P1
extern int volatility_P2 = 50;         //ATR Filter P2

extern int rsiExitLevel = 30;

extern double takeProfit = 5;          //takeProfit Percent Value
extern double stopLoss = 0;            //stopLoss Percent Value
extern int nBarExit = 0;               //nBarExit

//--- System Expected Parameters
extern double expTradesPerYear = 110;     //Trades Per Year
extern double expAccuracy = 70;
extern double expPayoffRatio = 0.8;
extern double expExpectancy = 0.3;
extern double expAvgTrade = 0.9;
extern double expStDev = 3.5;
extern double expE50 = 7500;
extern double expMDD = 5150;

extern double maxDrawDown = 5500;      //10k MDD Limit

//--- Label = MagicNumber and ExpertName
string label = expertName + " " + AccountCompany();

//--- Order Management Settings
int roundLot = 10;                     //Round Num of Shares to Nearest
int minLot = 10;                       //Min Shares Per Order
int slippage = 1;

//--- Inhibit Trades for X minutes after new compilation of code
int timeDelay = 10;

//--- pause EA for Status Update
int pause    = 20;

//--- alpha Lock function
double alpha = 1;
bool alphaLock = false;

//--- Comment Shorthands
string newLine = "\n";
string doubleSpace = "\n\n";

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
    //--- TimeDelay for Trading
    if( timeDelay != 0 )
    {
        if( NewMinute() )
        {
            timeDelay -= 1;
        }
    }
    
    //--- RefreshRates
    //RefreshRates();
    
    //--- Update Trade History Report
    if( reportHistory )
    {
      
      MATLAB2015();
      MATLAB2015(expertName, magicNumber,comissionDate);
      
      BrokersStatement();
    }
    
    // System Safety Switch      

    if ( DD(magicNumber,comissionDate) > maxDrawDown )
    {
      alpha = 0.1;
      alphaLock = true;
    }
    else
    {
      alpha = 1;
      alphaLock = false;
    }
    
    //--- Status Display
    Status();
    Sleep( 1000 * pause );

    //--- Manage Open Positions
    TradeManager();
    Sleep( 3000 );

    //--- Open New Positions
    Executor();
    Sleep( 3000 );
}

//+------------------------------------------------------------------+
//| EA Execution Functions                                           |
//+------------------------------------------------------------------+

//--- Display the EA General Status
void Status()
{
    string selectedWatchlist;
    if(watchlist == Opt0)selectedWatchlist = "GKFX_ALL"; 
    if(watchlist == Opt1)selectedWatchlist = "GKFX_US";
    if(watchlist == Opt2)selectedWatchlist = "GKFX_UK";
    if(watchlist == Opt3)selectedWatchlist = "GKFX_EU"; 
    if(watchlist == Opt4)selectedWatchlist = "JFD_ALL";
    if(watchlist == Opt5)selectedWatchlist = "JFD_US"; 
    if(watchlist == Opt6)selectedWatchlist = "JFD_UK";
    if(watchlist == Opt7)selectedWatchlist = "JFD_EU";
    if(watchlist == Opt8)selectedWatchlist = "FXPRO_ALL";
    
    double Spread = 0;
    
    if( Ask != 0 )
    {
      Spread = (Ask - Bid)/Ask;
    }
    
    double  balAUD = 0;
    double  AUDUSD = iClose("AUDUSD",PERIOD_H1,1);
    
    if ( AUDUSD != 0)
    {
      balAUD = AccountBalance()/AUDUSD;
    }
    
    string AlphaLock = StringConcatenate
         (
            newLine,
            " ... WARNING!!! SYSTEM IS IN ALPHA LOCK ... ",
            newLine
         );       
    
    double numTrades = TotalTradesHistory( magicNumber,comissionDate );
    double systemTradesPerYear = SystemTPY( magicNumber,comissionDate );
    double E50 = E50(magicNumber,comissionDate);
    double MDD = MDD(magicNumber,comissionDate);
    double DD = DD(magicNumber,comissionDate);
    
    double scoreE50 = 0;
    if(expTradesPerYear != 0)
    {
      scoreE50 = E50 / expE50 * 100;
    }
    
    double scoreMDD = 100;
    if(expMDD != 0)
    {
      scoreMDD = 100 * ( 1 - MDD  / expMDD );
    }
    
    double scoreDD = 100;
    if(expMDD != 0)
    {
      scoreDD = 100 * ( 1 - DD  / expMDD );
    }
    
    double expNumTrades = 0;
    if(systemTradesPerYear != 0)
    {
      expNumTrades = numTrades/systemTradesPerYear * expTradesPerYear;
    } 
        
    string expertDetails = StringConcatenate
         (
             newLine, AccountCompany(),
             newLine, expertName, " - Comissioned ",comissionDate, 
             //newLine, "Registered to ", AccountName(),
             newLine, "Account Number ", AccountNumber(),
             newLine, "Account Balance    = ",DoubleToString(balAUD,2)," AUD"
         );   

    string expertSettings = StringConcatenate
         (   
             doubleSpace, "watchlist        = ", selectedWatchlist,
             newLine, "nMagic           = ",magicNumber,         
             newLine, "maxOpenPos  = ", maxSymbols, 
             newLine, "fixedFraction   = ", fixedFraction,
             newLine, "trendFilter      = ", filter_P1," / ",filter_P2,
             newLine, "atrFilter       = ", volatility_P1," / ",volatility_P2,
             newLine, "rsiPeriod        = ", rsiPeriod,
             newLine, "rsiEntry         = ", rsiEntryLevel,
             newLine, "entryLimit      = ", entryLimit, 
             newLine, "rsiExit            = ", rsiExitLevel, 
             newLine, "takeProfit       = ", takeProfit,
             newLine, "stopLoss         = ", stopLoss,
             newLine, "nBarExit         = ", nBarExit
         );
    
    string expertPerformance = StringConcatenate
         (                          
             doubleSpace, "----- Actual Results -----",

             newLine, "openPositions      = ", CountSystemOrders( OP_BUY, magicNumber ), " / ", maxSymbols,
             newLine, "openDrawDown  = ", DoubleToString( ( 100 * ( AccountBalance() - AccountEquity() ) / AccountBalance() ), 2 ), " %",
             doubleSpace, "profit             = ",DoubleToString(SystemProfit( magicNumber, comissionDate ),2),
             newLine, "pctProfit         = ",DoubleToString(SystemProfitPct(magicNumber, comissionDate ),2), " %",

             doubleSpace, "-----  Fixed Fraction  -----",
             newLine, "CAR50          = ", DoubleToString(CAR50(magicNumber,comissionDate,fixedFraction),2)," %",
             newLine, "MDD             = ", DoubleToString(fixedFractionMDD(magicNumber,comissionDate,fixedFraction),2)," %",
             newLine, "DD               = ", DoubleToString(fixedFractionDD(magicNumber,comissionDate,fixedFraction),2)," %",                                        

             doubleSpace, "----- $10,000 / Trade -----",
             newLine, "E50              = $ ", DoubleToString(E50,0), " ... ",DoubleToString(scoreE50,2), " %",
             newLine, "MDD            = $ ", DoubleToString(MDD,0), " ... ",DoubleToString(scoreMDD,2), " %",
             newLine, "DD               = $ ", DoubleToString(DD,0), " ... ",DoubleToString(scoreDD,2), " %",
             newLine, "alphaLock @ $ ",DoubleToString(maxDrawDown,0)
             
         );
    string expertPerformance2 = StringConcatenate
         (    
             newLine,
             newLine, "numTrades     = ", numTrades,"       ( ",DoubleToString(expNumTrades,0)," )",
             newLine, "TPY              = ", DoubleToString( systemTradesPerYear, 0 ), "      ( ",DoubleToString(expTradesPerYear,0)," )",
             newLine, "accuracy        = ", DoubleToString( SystemAccuracy( magicNumber,comissionDate ), 1 ),"     ( ",DoubleToString(expAccuracy,1), " )",
             newLine, "payoffRatio    = ", DoubleToString( SystemPayoffRatio( magicNumber,comissionDate ), 2 ),"     ( ",DoubleToString(expPayoffRatio,2), " )",
             newLine, "expectancy     = ", DoubleToString( SystemExpectancy( magicNumber,comissionDate ), 2 ),"     ( ",DoubleToString(expExpectancy,2), " )",
             newLine, "avgTrade       = ", DoubleToString( 100 * SystemAverageTrade( magicNumber,comissionDate ), 2 ),"     ( ",DoubleToString(expAvgTrade,2), " )",
             newLine, "stDev            = ", DoubleToString( 100 * SystemStDev( magicNumber,comissionDate ), 2 ),"     ( ",DoubleToString(expStDev,2), " )",
             newLine, "t.Test            = ", DoubleToString( SystemTTest( magicNumber,comissionDate ), 2 ),
             newLine
         );

    string symbolInfo = StringConcatenate
         (
             //newLine, "iBarShift = ",iBarShift(Symbol(),PERIOD_D1,TimeCurrent(),true),
             
             newLine, Symbol(), " ", SymbolInfoString( Symbol(), SYMBOL_CURRENCY_BASE )," [ ",MarketOpenTime( Symbol() ), "  ", MarketCloseTime( Symbol() ) + 4," ] ",
             newLine, "Share Value = ", DoubleToString( ShareValue( Symbol() ), 2 )," ",AccountCurrency(),
             newLine, "Spread = ",DoubleToString(Spread,4),
             newLine, "Position Size = ", PositionSize( Symbol(), MoneyManagement( alpha * fixedFraction, accountPercent ), roundLot, minLot ), " Lots ~ $", DoubleToString( PositionSize( Symbol(), MoneyManagement( alpha * fixedFraction, accountPercent ),roundLot, minLot ) * ShareValue( Symbol() ), 2 )
         );
         
    string openTradeInfo = StringConcatenate
         (
             newLine,
             newLine, "Order Open Price = ", DoubleToString( OpenPrice( Symbol(), magicNumber ), 2 ),
             newLine, "Bars Since Entry = ", BarsSinceEntry( Symbol(),timeFrame, magicNumber ),
             newLine, "Take Profit Level = ", DoubleToString( TakeProfitPrice( Symbol(), takeProfit, magicNumber ), Digits )
         );    

    if( OpenPrice( Symbol(), magicNumber ) != 0 )
    {
      if (alphaLock)
      {
         Comment( AlphaLock, expertDetails, expertSettings, expertPerformance, expertPerformance2, symbolInfo, openTradeInfo );
      }
      else
      {
         Comment( expertDetails, expertSettings, expertPerformance, expertPerformance2, symbolInfo, openTradeInfo );
      }  
    }
    else
    {
      if(alphaLock)
      {
         Comment(AlphaLock, expertDetails, expertSettings, expertPerformance, expertPerformance2, symbolInfo );
      }
      else
      {
         Comment(expertDetails, expertSettings, expertPerformance, expertPerformance2, symbolInfo );
      }
      
    }
}

void TradeManager()
{ 
   //--- Initialize Counters

   int   totalOpenTrades = 0,
         variableError = 0,
         totalErrors = 0;

   for( int i = OrdersTotal() - 1; i >= 0; i-- )
   {
      if( ! OrderSelect(i,SELECT_BY_POS,MODE_TRADES) ) 
      {
         continue;
      }
      
      if( OrderMagicNumber() == magicNumber )
      { 
         totalOpenTrades += 1;
         string symbol = OrderSymbol();
         
         //--- Declare and Zero All Variables for Each Symbol
         int      barsSinceEntry = 0,
                  numSymbolLong = 0;
         
         double   ask = 0,
                  bid = 0,
         
                  close0 = 0,
                  close1 = 0,
                  rsi0 = 0,
                  entryPrice = 0,
                  takeProfitPrice = 0;
         
         bool     tradingWindow = false;
         
         //--- Calculate Variables Variables
         
         ask = MarketInfo( symbol, MODE_ASK );
         bid = MarketInfo( symbol, MODE_BID );
         
         close0 = iClose( symbol, PERIOD_D1, 0 );
         close1 = iClose( symbol, PERIOD_D1, 1 );
         rsi0 = iRSI( symbol, PERIOD_D1, rsiPeriod, PRICE_CLOSE, 0 );
         
         barsSinceEntry = BarsSinceEntry( symbol, timeFrame, magicNumber);
         entryPrice = OpenPrice( symbol, magicNumber);
         takeProfitPrice = TakeProfitPrice( symbol, takeProfit, magicNumber );
         
         tradingWindow = MarketClosingWindow( symbol, 5 );
         
         //--- Where possible ensure variables have been called and loaded correctly
         
         if( ask == 0 || bid == 0 || close0 == 0 )
         {
            if( errorPrint )
            {
                Print( symbol, " Failed Variable Error Check..." );
            }
            continue;
         }
         
         //--- Monitor all open positions and check all stops
         
         // Apply stops at the end of the first trading day
         if( tradingWindow && barsSinceEntry < 1 ) 
         {
            if( !hiddenStops && takeProfit != 0 && bid < entryPrice )
            {
               {
                   ApplyTakeProfit( symbol, takeProfit, magicNumber );
               }
            }
            
            if( !hiddenStops && stopLoss != 0)
            {
               {
                   ApplyStopLoss( symbol, stopLoss, magicNumber );
               }
            }
         }
         
         if( barsSinceEntry >= 1 )
         {
            // Check for manual exit conditions
            if( takeProfit != 0 && takeProfitPrice != 0 && bid >= takeProfitPrice )  
            {
                ExitLong( symbol, bid, slippage, magicNumber, Green );
                Alert( "EA_TakeProfit_Exit ", symbol );
                continue;
            }
                 
            if( close0 > close1 && tradingWindow )
            {
                ExitLong( symbol, bid, slippage, magicNumber, Black );
                Alert( " C > ref(C,-1) ", symbol );
                continue;
            }
         
            if( nBarExit != 0 && barsSinceEntry >= nBarExit && tradingWindow )
            {
                ExitLong( symbol, bid, slippage, magicNumber, Red );
                Alert( "EA_nBarExit ", symbol );
                continue;
            }
            
            if ( stopLoss != 0 && close0 <= entryPrice * ( 1 - (stopLoss * 0.01)) && tradingWindow)
            {
                ExitLong( symbol, bid, slippage, magicNumber, Red );
                Alert( "Hard stopLoss triggered ", symbol );
                continue;
            }
            
            // Submit TP and SL to broker 
            if( !hiddenStops )
            {
               if ( takeProfit != 0 ) 
               {
                  ApplyTakeProfit( symbol, takeProfit, magicNumber );
               }
               
               if (stopLoss != 0)
               {
                  ApplyStopLoss( symbol, stopLoss, magicNumber );
               }
            }
         }
      }
   }
   
   Comment
   (
      newLine, "TradeManager Scan Completed... ",
      doubleSpace, "Open Positions ... ", totalOpenTrades,
      doubleSpace, "Indicator Failure ... ", variableError,
      doubleSpace, "Total Errors ... ", variableError
   );
   
   Sleep( 500 );
   
}

//--- Look to Enter New Positons

void Executor()
{
    datetime StartTimer = TimeLocal(); // Log the time that the executor begins its run

//  Load Correct Watchlist for EA    
    string SHARES[];
    if(watchlist == Opt0)ArrayCopy(SHARES,GKFX_ALL,0,0,WHOLE_ARRAY); 
    if(watchlist == Opt1)ArrayCopy(SHARES,GKFX_US,0,0,WHOLE_ARRAY); 
    if(watchlist == Opt2)ArrayCopy(SHARES,GKFX_UK,0,0,WHOLE_ARRAY); 
    if(watchlist == Opt3)ArrayCopy(SHARES,GKFX_EU,0,0,WHOLE_ARRAY); 
    if(watchlist == Opt4)ArrayCopy(SHARES,JFD_ALL,0,0,WHOLE_ARRAY); 
    if(watchlist == Opt5)ArrayCopy(SHARES,JFD_US,0,0,WHOLE_ARRAY); 
    if(watchlist == Opt6)ArrayCopy(SHARES,JFD_UK,0,0,WHOLE_ARRAY); 
    if(watchlist == Opt7)ArrayCopy(SHARES,JFD_EU,0,0,WHOLE_ARRAY);
    if(watchlist == Opt8)ArrayCopy(SHARES,FXPRO_ALL,0,0,WHOLE_ARRAY); 

    //--- Initialize Counters

    int   triggerDayCount = 0,
          aboveFilterCount = 0,
          
          barCountError = 0,
          symbolNameError = 0,
          stockSplitError = 0,
          variableError = 0,
          newCandleError = 0,
          dateSequenceError = 0,
          spreadLimitError = 0,
          totalErrors = 0;

    // --- Cycle through watchlist
    for( int i = 0; i < ArraySize( SHARES ); i++ )
    {
        //--- Assign Symbol() to variable symbol
        string symbol = SHARES[i];
        
        // RefreshRates as in MQL5 
        SymbolInfoTick(symbol, m_tick);

        //--- Display cycle summary information
        Comment
        (
            newLine, "Scanning ... ", i + 1, " ... ", DoubleToString( 100 * ( i + 1 ) / ArraySize( SHARES ), 0 ), "%",
            newLine, "Current Symbol ... ", symbol,
            newLine, "Trade Inhibit Timer ... ", timeDelay, " mins",
            
            doubleSpace, "Symbol Name Not Found ... ", symbolNameError,
            newLine, "Not Enough Bars on Chart ... ", barCountError,
            newLine, "Stock Split Detected ... ", stockSplitError,
            newLine, "Dates Out of Sequence... ", dateSequenceError,
            newLine, "Daily Bar Not Yet Formed ... ", newCandleError,
            
            doubleSpace, "Indicator Failure ... ", variableError,
            newLine, "Spread is Too Expensive ... ", spreadLimitError,
            
            doubleSpace, "Total Errors ... ", symbolNameError + barCountError + stockSplitError + variableError + spreadLimitError + dateSequenceError,
            newLine, "Tradable Stocks ... ", DoubleToString( 100 * ( ArraySize( SHARES ) - ( symbolNameError + barCountError + stockSplitError + variableError + spreadLimitError + dateSequenceError ) ) / ArraySize( SHARES ),2)," %",
            doubleSpace, "Stocks Above Filter ... ", aboveFilterCount,
            newLine, "Stocks Armed for Entry ... ", triggerDayCount
        );

        if( i == ArraySize( SHARES ) - 1 )
        {
            //Print( "Run Time... Executor = ", TimeSeconds( TimeLocal() - StartTimer ), " Seconds" );
            Sleep( 2000 );
        }

        // --- Conduct DataValidation Checks

        if( SymbolNameCheck( symbol ) == false )
        {
            if( errorPrint )
            {
                Print( symbol, " Not found in watchlist..." );
            }

            symbolNameError += 1;
            continue;
        }

        if( iBars( symbol, PERIOD_D1 ) < minBars )
        {
            if( errorPrint )
            {
                Print( symbol, " Not enough bars on chart..." );
            }

            barCountError += 1;
            continue;
        }

        if( StockSplitCheck( symbol, minBars ) == false )
        {
            if( errorPrint )
            {
                Print( symbol, " Stock split detected..." );
            }

            stockSplitError += 1;
            continue;
        }

        if( ValidDateSequence( symbol ) == false )
        {
            if( errorPrint )
            {
                Print( symbol, " Dates are out of sequence" );
            }

            dateSequenceError += 1;
            continue;
        }      
        
        if( iBarShift(symbol,timeFrame,TimeCurrent(),true) != 0 )
        {
            if( errorPrint )
            {
                Print( symbol, " Waiting for new bar..." );
            }

            newCandleError += 1;
            continue;
        }
        //--- Declare and Zero All Variables for Each Symbol - Fail SAFE feature

        int      nGlobal = 0,
                 nSystemLong = 0,
                 nSymbolLong = 0;

        double   ask = 0,
                 bid = 0,
                 spread = 0,
         
                 barShift = -1,
                 barWidth = -1,
                 low1 = 0,
                 entryPrice = 0,
                 rsi1 = 0,
         
                 contractSize = 0,
                 tradeValue = 0,
                 fundsAvailable = 0,
                 shareValue = 0;

        bool     trendFilter = False,
                 volatilityFilter = False,
                 currentDailyBar = False;

        //--- Calculate and Load Variables

        nGlobal =  CountGlobalOrders();
        nSystemLong = CountSystemOrders( OP_BUY, magicNumber );         // Count number of positions that are open in this system
        nSymbolLong = CountExpertOrders( symbol, OP_BUY, magicNumber ); // Count number of positions that are open for the symbol and controlled by the system

        ask = MarketInfo( symbol, MODE_ASK );
        bid = MarketInfo( symbol, MODE_BID );

        barShift = iBarShift(Symbol(),timeFrame,TimeCurrent(),true);
        barWidth = iHigh( symbol, timeFrame, 0 ) - iLow( symbol, timeFrame, 0 );
        
        low1 = iLow( symbol, timeFrame, 1 );
        entryPrice = low1 * ( 100 - entryLimit ) * 0.01;
        trendFilter = HHV_Filter( symbol, timeFrame, filter_P1, filter_P2 );
        volatilityFilter = ATR_Filter( symbol, timeFrame, volatility_P1,volatility_P2);
        rsi1 = iRSI( symbol, PERIOD_D1, rsiPeriod, PRICE_CLOSE, 1 );

        contractSize = PositionSize( symbol, MoneyManagement( fixedFraction, accountPercent ), roundLot, minLot );
        tradeValue = contractSize * ShareValue( symbol );
        fundsAvailable = accountPercent * fixedFraction * maxSymbols * AccountBalance() - SystemExposure( magicNumber );

        shareValue = ShareValue( symbol );

        //--- Where possible ensure variables have been called and loaded correctly

        if( ask == 0 || bid == 0 || low1 == 0 || entryPrice == 0 || rsi1 == 0 || contractSize == 0 || tradeValue == 0 || shareValue == 0 )
        {
            if( errorPrint )
            {
                Print( symbol, " Failed Variable Error Check..." );
            }

            variableError += 1;
            continue;
        }
        
        spread = ( ask - bid ) / ask;
        if( spread > maxSpread )
        {
            if( errorPrint )
            {
               Print( symbol, " Spread is Too Expensive..." );
            }
            spreadLimitError += 1;
            continue;
        }
        
        if( trendFilter && volatilityFilter )
        {
            aboveFilterCount += 1;
        }
        
        
        if( trendFilter && rsi1 <= rsiEntryLevel )
        {
            triggerDayCount += 1;
            //Print( symbol, " ... Armed for Entry " );
        }

        //--- Check for valid entries

        if( entryFlag && timeDelay == 0 && nGlobal <= maxGlobal && nSymbolLong == 0 && nSystemLong < maxSymbols )                 // Permission to Enter
        {
            if( shareValue <= maxShareValue && shareValue >= minShareValue && tradeValue <= fundsAvailable )                      // Finance Parameters Are Correct
            {
                if( !ExitBar( symbol, timeFrame, magicNumber ) )
                {
                    if( trendFilter && volatilityFilter && rsi1 <= rsiEntryLevel && ask <= entryPrice )
                    {
                        EnterLong( symbol, contractSize, ask, slippage, 0, 0, magicNumber, label );
                        if( emailReport==true )
                        {
                           sendEmail(symbol,entryPrice,barShift, barWidth,low1,spread,ask,rsi1);
                        }
                        continue;
                    }
                }
            }
        }

   }


}

//+------------------------------------------------------------------+
//| EA Specific Function                                             |
//+------------------------------------------------------------------+
void sendEmail( string symbol, double entryPrice, double barShift, double barWidth, double low1, double spread, double ask, double rsi1)
{        
      string subject = StringConcatenate
      (
         newLine, "TRADE ENTRY REPORT ", symbol, " ", TimeToString(TimeLocal()), " ", AccountCompany(), " ", AccountNumber(), " ", expertName, " ", IntegerToString(magicNumber)
      );
      
      string section1 = StringConcatenate
      (
         newLine, symbol,
         newLine, "TimeCurrent ", TimeToString(TimeLocal()),
         newLine, "TimeGMT ", TimeToString(TimeGMT()),
         doubleSpace,
          
         newLine, "BAR 0",
         newLine, TimeToString( iTime(symbol,timeFrame,0) ),
         newLine, "Open ",DoubleToString( iOpen(symbol,timeFrame,0),4 ),
         newLine, "High ",DoubleToString( iHigh(symbol,timeFrame,0),4 ),
         newLine, "Low ",DoubleToString( iLow(symbol,timeFrame,0),4 ),
         newLine, "Close ",DoubleToString( iClose(symbol,timeFrame,0),4 ),
         newLine, "Ask ",DoubleToString( ask,4 ),
         doubleSpace,
         
         newLine, "BAR 1",
         newLine, TimeToString( iTime(symbol,timeFrame,1) ),
         newLine, "Open ",DoubleToString( iOpen(symbol,timeFrame,1),4 ),
         newLine, "High ",DoubleToString( iHigh(symbol,timeFrame,1),4 ),
         newLine, "Low ",DoubleToString( iLow(symbol,timeFrame,1),4 ),
         newLine, "Close ",DoubleToString( iClose(symbol,timeFrame,1),4 ),
         newLine, "RSI1 ",DoubleToString( rsi1,4 ),
         doubleSpace
        
       );
      
      string section2 = StringConcatenate
      (  
         newLine, "BAR 2",
         newLine, TimeToString( iTime(symbol,timeFrame,2) ),
         newLine, "Open ",DoubleToString( iOpen(symbol,timeFrame,2),4 ),
         newLine, "High ",DoubleToString( iHigh(symbol,timeFrame,2),4 ),
         newLine, "Low ",DoubleToString( iLow(symbol,timeFrame,2),4 ),
         newLine, "Close ",DoubleToString( iClose(symbol,timeFrame,2),4 ),
         newLine, "RSI2 ",DoubleToString( iRSI(symbol,timeFrame,rsiPeriod,PRICE_CLOSE,2),4 ),
         
         doubleSpace, "VARIABLES",
         newLine, "Low1 ", DoubleToString(low1,4),
         newLine, "EntryPrice ",DoubleToString(entryPrice,4),
         newLine, "Spread ", DoubleToString(spread,4),
         newLine, "barShift ", DoubleToString(barShift,2),
         newLine, "barWidth ", DoubleToString(barWidth,2)
      );
      
      string body = StringConcatenate(subject,section1,section2);
      SendMail("TradeEntryReport",body);
}