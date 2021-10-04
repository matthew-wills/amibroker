
//+------------------------------------------------------------------+
//|                                                     basicRSI.mq4 |
//|                                Copyright 2015, Matthew Wills Inc |
//|                                http://www.MarksmanTrading.com.au |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Matthew Wills Inc"
#property link      "http://www.MarksmanTrading.com.au//"
#property version   "1.5"
#property strict

#include <myFunctions.mqh>

extern string     GENERALSETTINGS      = "----- General Expert Settings -----";
extern string expertName = "QTA_RSI_SYSTEM";        // Name of Trading System
extern datetime comissionDate = D'2019.10.01';      // YYYYMMDD  
extern int magicNumber = 0;

extern bool entryFlag = true;          //Permission to Enter Trades
extern bool reportHistory = true;      //Create Excel History File
extern bool errorPrint = false;        //Print Errors
extern bool emailReport = false;       //TroubleShooting Email

extern string     MONEYMANAGEMENTSETTINGS      = "----- Money/Risk Management -----";
extern int maxGlobal = 20;              //Max Pos in MT4
extern int maxSymbols = 3;             //Max Pos in EA
extern double accountPercent = 1.00;   //Ratio of Account Allocated
extern double maxFixedFraction = 2.0;     //fixedFraction
extern double maxSpread = 0.020;       //Max Allowable Spread
extern double maxShareValue = 9999;        //Max Share Value
extern double minShareValue = 0;          //Min Share Value
bool poundIsPence = false;      //UK Stocks listed in Pence
int slippage = 1;

extern string     TRADINGSYSTEMSETTINGS      = "----- Trading System Parameters -----";
extern ENUM_TIMEFRAMES timeFrame = PERIOD_D1;          // Select TimeFrame
input int rsiPeriod = 4;
input double rsiEntryLevel = 30;
input double rsiExitLevel = 70;

extern bool hiddenStops = true;        //Hide Stops From Broker
input double takeProfit = 0;
input double stopLoss = 0;
input int nBarExit = 0;

extern string     MONTECARLOSETTINGS      = "----- MonteCarlo Settings -----";

input int optimizingPeriods = 1000; // Optimization periods(bars)
input double bidAskSpread = 0.0015; // Spread

input int runs = 3000;
input double confidenceLevel = 0.95;
input double mddLimit = 0.25;
input double forcastHorizon = 504;

// Global variables
bool executorComplete = true;

string newLine = "\n";
string doubleSpace = "\n\n";

double accuracy = 0;
double payoffRatio = 0;
double expectancy = 0;
double numTrades = 0;
double tradesPerYear = 0;

double safeF;
double CAR05;
double CAR25;
double CAR50;
double CAR75;
double CAR95;

double MDD95;
double bestEstimate[];


//+------------------------------------------------------------------+
//| Structure for collecting indicator values                        |
//+------------------------------------------------------------------+
struct Optimizing_Structure
{
    datetime          date;
    double            rsiValue;
    double            close;
};
Optimizing_Structure optimizer[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---

   EventSetTimer( 1 );  
//---
    return( INIT_SUCCEEDED );
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit( const int reason )
{
//---

}
//+------------------------------------------------------------------+
//| Fills the optimizer array with data                              |
//+------------------------------------------------------------------+
void FillArray()
{
//Fill optimizer array
    ArrayResize( optimizer, optimizingPeriods + 1 );

    for( int i = 0; i <= optimizingPeriods; i++ )
    {
        optimizer[i].rsiValue = iRSI( NULL, PERIOD_CURRENT, rsiPeriod, PRICE_CLOSE, i );
        optimizer[i].close = iClose( NULL, 0, i );
        optimizer[i].date = iTime(NULL,PERIOD_CURRENT,i);
    }
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
//void OnTick()
void OnTimer()
{

// Trade only on new bars, and one at a time
    if( NewBar() ) // Run only on new bars
    {
         executorComplete = false;
                
         BackTest();        
    }
    
    if( NewMinute() )
    {
         PositionManager();
         Status();
    }
    
   if( MarketClosingWindow(Symbol(),TimeCurrent(),5) && executorComplete == false )
   {        
         executorComplete = true;
         Executor();
   }
   
}


//+------------------------------------------------------------------+
//| oversold value generation                                        |
//+------------------------------------------------------------------+

void Executor()
{
   string symbol = _Symbol;
   
   if( CAR25 < 5 )
   {
      Print(_Symbol," CAR25 < 5");
      return;
   }
   
   if( CountSystemOrders(ORDER_TYPE_BUY,magicNumber) >= maxSymbols )
   {
      return;   
   }
   
   // Is there already a position open for today
   if( CountExpertOrders(symbol,ORDER_TYPE_BUY,magicNumber) > 0 ) 
   {
      return;      
   } 
   
   // If there was already an open position on this Bar - disarm the symbol
   if( ExitBar( symbol, timeFrame, magicNumber ) ) // Searches history ... computationally expensive
   {         
      return;
   }
   
   // Are there enough bars for the EA? 
   if ( iBars( symbol, timeFrame ) < optimizingPeriods )
   {
      if( errorPrint )
      {
          Print( symbol, " Not Enough Bars on Chart ..." );
      }
      return;
   }       
             
   // Is there a split in the Data?      
   if( StockSplitCheck( symbol, optimizingPeriods ) == false )
   {
      if( errorPrint )
      {
         Print( symbol, " Stock split detected ..." );
      }
      return;
   }
   
   if( ValidDateSequence( symbol ) == false )
  {
      if( errorPrint )
      {
          Print( symbol, " Dates are out of sequence..." );
      }       
      return;
  }   
  
   double rsi = -1;
   rsi = iRSI( symbol, timeFrame, rsiPeriod, PRICE_CLOSE, 0);  
   if(rsi >= rsiEntryLevel || rsi==-1) 
   {
      return;
   }
   
   // Are there enough funds           
   double  lots = 0,
           sharesPerLot = 0,
           tradeValue = 0,
           fundsAvailable = 0,
           takeProfitPrice = 0;
   
   
   double fixedFraction = MathMin(maxFixedFraction,safeF);                 
   lots = PositionSize( symbol, MoneyManagement( fixedFraction, accountPercent ), poundIsPence );
   sharesPerLot = SymbolInfoDouble( symbol, SYMBOL_TRADE_CONTRACT_SIZE );
   tradeValue = lots * sharesPerLot * ShareValue( symbol, poundIsPence );
   fundsAvailable = accountPercent * fixedFraction  * AccountBalance() - SystemExposure( magicNumber, poundIsPence );

   if( tradeValue > fundsAvailable || tradeValue == 0 )
   {
      if( errorPrint )
      {
         Print( symbol, " Not Enough Funds ... Line 590" );
      }
      return;
   }
   
   RefreshRates();
   EnterLong( symbol, lots, Ask, slippage, 0, 0, magicNumber, expertName );
   return; 
}

void PositionManager()
{ 
   Comment(doubleSpace, "TradeManager()");

   //--- Initialize Counters

   int   totalOpenTrades = 0,
         variableError = 0,
         totalErrors = 0;
   
   datetime timeCurrent = TimeCurrent();

   for( int i = OrdersTotal() - 1; i >= 0; i-- )
   {
      if( ! OrderSelect(i,SELECT_BY_POS,MODE_TRADES) ) 
      {
         continue;
      }
      
      if ( OrderSymbol() != Symbol() )
      {
         continue;
      }            
      
      if( OrderMagicNumber() != magicNumber )
      {
         continue;
      } 
          
      string symbol = OrderSymbol();      
      
      totalOpenTrades ++ ;
      
      if(SessionClosed(OrderSymbol(),timeCurrent) == true) 
      {
         continue;
      } 
               
      //--- Declare and Zero All Variables for Each Symbol
      int      barsSinceEntry = 0,
               numSymbolLong = 0;
      
      double   ask = 0,
               bid = 0,
               close0 = 0,
               rsi0 = 0,
               entryPrice = 0,
               takeProfitPrice = 0,
               stopLossPrice = 0;
      
      //--- CalculateRequired for Every Scan

      barsSinceEntry = BarsSinceEntry( symbol, NULL, magicNumber);   
      bid = SymbolInfoDouble(symbol,SYMBOL_BID);
      
      // If not first candle
      if( barsSinceEntry >= 1 )
      {        
         // Always manually check TP and SL
             
         //Check for TP Exit
         if( takeProfit != 0 )
         { 
            takeProfitPrice = TakeProfitPrice( symbol, takeProfit, magicNumber );    
            if( takeProfitPrice != 0 && bid >= takeProfitPrice )  
            {
                ExitLong( symbol, bid, slippage, magicNumber, Green );
                Alert( "EA_TakeProfit_Exit ", symbol );
                continue;
            }
         }
         
         // Check for SL Exit            
         if( stopLoss != 0 )
         { 
            stopLossPrice = StopLossPrice( symbol, stopLoss, magicNumber );    
            if( stopLossPrice != 0 && bid <= stopLossPrice )  
            {
                ExitLong( symbol, bid, slippage, magicNumber, Red );
                Alert( "EA_StopLoss_Exit ", symbol );
                continue;
            }
         }                  
                 
         // if stops going to broker then check them!
         if( !hiddenStops )
         {
            if ( takeProfit != 0 ) 
            {
               ApplyTakeProfit( symbol, takeProfit, magicNumber );
            }
            
            if ( stopLoss != 0 )
            {
               ApplyStopLoss( symbol, stopLoss, magicNumber );
            }
         }
      } 
    
      //--- If the market is about to close
      if( MarketClosingWindow( symbol, timeCurrent, 2 ) == true )
      {  
         entryPrice = OpenPrice( symbol, magicNumber);
         
         // If submitting TP and SL to Broker and it is the First Day of trade
         if( !hiddenStops && barsSinceEntry < 1 )
         {           
            // Submit SL and TP at end of first day
            // If price < takeProfit modify order
            if( takeProfit != 0 && bid < entryPrice )
            {
               {
                   ApplyTakeProfit( symbol, takeProfit, magicNumber );
               }
            }            
            if( stopLoss != 0)
            {
               {
                   ApplyStopLoss( symbol, stopLoss, magicNumber );
               }
            }        
         }
         
         // Check Rule Based Exits
         if( barsSinceEntry >= 1 )
         {         
            rsi0 = customRSI( symbol, PERIOD_D1, rsiPeriod, 0 );
            
            if( rsi0 >= rsiExitLevel )
            {
                ExitLong( symbol, bid, slippage, magicNumber, Green );
                Alert( "EA_RSI_Exit ", symbol );
                continue;
            }
         
            if( nBarExit != 0 && barsSinceEntry >= nBarExit )
            {
                ExitLong( symbol, bid, slippage, magicNumber, Black );
                Alert( "EA_nBarExit ", symbol );
                continue;
            }
            
            if ( stopLoss != 0 && bid <= entryPrice * ( 1 - (stopLoss * 0.01)) )
            {
                ExitLong( symbol, bid, slippage, magicNumber, Red );
                Alert( "Hard stopLoss triggered ", symbol );
                continue;
            }            
         }      
      }
      
   }   
   
   Comment
   (
      doubleSpace, "TradeManager() Completed ... ",
      doubleSpace, "Open Positions ... ", totalOpenTrades,
      doubleSpace, "Indicator Failure ... ", variableError,
      doubleSpace, "Total Errors ... ", variableError
   );  
}


void Status()
{
   // Declare static variables that are updated only when a new position is closed
   static double actNumTrades = -1, actTradesPerYear = -1;
   static string symbol = _Symbol;
   static double actAccuracy = -1, actPayoffRatio = -1, actExpectancy = -1, avgTrade = -1, stDev= -1;   
   static double actTotalProfit = 0, actSystemProfit = 0, actSystemProfitPct = 0;
   
   int currentNumTrades = TotalTradesHistory(magicNumber,comissionDate);   
   
   if( currentNumTrades != actNumTrades && currentNumTrades > 0 )
   {
      actNumTrades = currentNumTrades;
      
      // newTrade Closed re-run calculations

      datetime timeCurrent = TimeCurrent();
      datetime firstTradeDate = TimeCurrent();      
      
      // Create Tradelist and calculate standard Metrics  
         
      int    numWinners = 0, numLosers = 0;
      double delta = 0, sumWinners = 0, sumLosers = 0, avgWin = 0, avgLoss = 0, sumX2 = 0, numDays = 1;
      actTotalProfit = 0;   
              
      double tradeList[];
      double tradeArray[][2];
      ArrayResize(tradeList,(int)numTrades,0);
      ArrayResize(tradeArray,(int)numTrades,0);

      int j = 0;
      for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
      {
         if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
         if( OrderSymbol() == "" || OrderMagicNumber() != magicNumber ) continue;
         if ( DateCheck(comissionDate, OrderCloseTime()) == false ) continue;
         
         actTotalProfit += ( OrderProfit() + OrderCommission() + OrderSwap() );
         
         delta = NetDelta();
         
         tradeArray[j][0] = (double) OrderCloseTime();
         tradeArray[j][1] = delta;
         
         j++;
         
         if( delta > 0)
         {
            numWinners ++;
            sumWinners += delta; 
         }
         else
         {
            numLosers ++;
            sumLosers += -delta;
         }                 
      }
           
      if( actNumTrades > 0 ) 
      {      
         ArraySort(tradeArray);
         for( int a = 0; a < numTrades; a++)
         {
           tradeList[a] = tradeArray[a][1];
         }
         
         firstTradeDate = (datetime)tradeArray[0][0];
         numDays = MathMax(1, 365 * ( TimeYear(timeCurrent) - TimeYear(firstTradeDate) ) + TimeDayOfYear(timeCurrent) - TimeDayOfYear(firstTradeDate));         
         actTradesPerYear = (int) ( ( actNumTrades /  numDays ) * 365 );
         
         avgTrade = ( sumWinners - sumLosers ) / actNumTrades;
         for( int a = 0 ; a < j ; a++ ) 
         {
            delta = tradeList[a];
            sumX2 += ( ( delta - avgTrade ) * ( delta - avgTrade ) );
         }     
         actSystemProfit = actTotalProfit;
         actSystemProfitPct = 100 * actTotalProfit / (AccountBalance() - actTotalProfit);      
         actAccuracy = double (numWinners) / double (actNumTrades);       
         stDev = sqrt(sumX2 / actNumTrades);      
      }       
      
      if( numWinners > 0)    avgWin = sumWinners / numWinners;
      if( numLosers > 0)     avgLoss = sumLosers / numLosers;
      if( avgLoss != 0 )     payoffRatio = avgWin / avgLoss;
      
      actExpectancy =  actAccuracy * actPayoffRatio + actAccuracy - 1;
   }
   
   ////////////////////////////////// PRINT RESULTS /////////////////////////////////////
   
   
   string expertDetails = StringConcatenate
   (
       newLine, expertName," - ",magicNumber, " - ",comissionDate         
   );
   
   string expertSettings = StringConcatenate
   (   
       doubleSpace, "maxOpenPos  = ", maxSymbols, 
       newLine, "maxFixedFraction   = ", maxFixedFraction,
       newLine, "rsiPeriod        = ", rsiPeriod,
       newLine, "rsiEntry         = ", rsiEntryLevel,
       newLine, "rsiExit            = ", rsiExitLevel, 
       newLine, "takeProfit       = ", takeProfit,
       newLine, "stopLoss         = ", stopLoss,
       newLine, "nBarExit         = ", nBarExit
   );
   
   string backTestResults = StringConcatenate
   (          
       doubleSpace,"----- BackTest Results -----",
       newLine, "numTrades     = ", numTrades,
       newLine, "tradesPerYear = ", DoubleToString( tradesPerYear, 0 ),
       newLine, "accuracy        = ", DoubleToString( accuracy, 2 ),
       newLine, "payoffRatio    = ", DoubleToString( payoffRatio, 2 ),
       newLine, "expectancy     = ", DoubleToString( expectancy, 2 ),       
       newLine, "safeF     = ",  DoubleToString( safeF, 2 ),
       newLine, "CAR25     = ", DoubleToString( CAR25, 2 ),
       newLine,
       newLine, "           ", DoubleToString( CAR50, 0 ),
       newLine, "      ", DoubleToString( CAR25, 0 ),"       ", DoubleToString( CAR75, 0 ),
       newLine, " ", DoubleToString( CAR05, 0 ),"                   ",  DoubleToString( CAR95, 0 )              
   );
   
   
   string expertPerformance = StringConcatenate
   (                          
       doubleSpace, "----- Actual Results -----",

       newLine, "numOpenPos      = ", CountSystemOrders( OP_BUY, magicNumber ), " / ", maxSymbols,
       newLine, "openDrawDown  = ", DoubleToString( ( 100 * ( AccountBalance() - AccountEquity() ) / AccountBalance() ), 2 ), " %",
       newLine, "profit             = $",DoubleToString(actSystemProfit,0)," / ",DoubleToString(actSystemProfitPct,0),"%",
       newLine,                       
       newLine, "numTrades     = ", actNumTrades,
       newLine, "tradesPerYear = ", DoubleToString( actTradesPerYear, 0 ),
       newLine, "accuracy        = ", DoubleToString( actAccuracy, 2 ),
       newLine, "payoffRatio    = ", DoubleToString( actPayoffRatio, 2 ),
       newLine, "expectancy     = ", DoubleToString( actExpectancy, 2 ),
       newLine, "avgTrade       = ", DoubleToString( 100*avgTrade, 4 ),
       newLine, "stDev       = ", DoubleToString( 100*stDev, 4 )
   );
   
   string symbolInfo = StringConcatenate
   (
       //newLine, "iBarShift = ",iBarShift(symbol,PERIOD_D1,TimeCurrent(),true),
       
       doubleSpace, symbol, " ", SymbolInfoString( symbol, SYMBOL_CURRENCY_BASE )," [ ",TimeConvert(MarketOpenTime( symbol )), "  ", TimeConvert(MarketCloseTime( symbol ))," ] ", !SessionClosed(symbol,TimeCurrent()),
       newLine, "closingWindow = "," [ ",TimeConvert(MarketCloseTime( symbol ) - 5 * 60), "  ", TimeConvert(MarketCloseTime( symbol ))," ] ",
       newLine, "shareValue = ", DoubleToString( ShareValue( symbol, poundIsPence ), 2 )," ",AccountCurrency(),
       newLine, "spread = ",DoubleToString( ( Ask-Bid ) / MathMin(Ask,999999999999999999),4),
       newLine, "Position Size = " +  DoubleToString(accountPercent * PositionSize( symbol, MoneyManagement( MathMin(maxFixedFraction,safeF) ),poundIsPence ),2)
   );
      
   string openTradeInfo = StringConcatenate
   (
       newLine,
       newLine, "orderOpenPrice = ", DoubleToString( OpenPrice( symbol, magicNumber ), 2 ),
       newLine, "barsSinceEntry = ", BarsSinceEntry( symbol,timeFrame, magicNumber )
   );   
   
   Comment( expertDetails, expertSettings, backTestResults, expertPerformance, symbolInfo, openTradeInfo );
   return;
}

void BackTest()
{
    FillArray();// fill optimizer array
    
    ArrayResize(bestEstimate,optimizingPeriods+1,0);

    double orderOpenPrice = NULL;
    bool inTrade = false;

    // Set variables for metric calculations

    int numWin = 0;
    int numLoss = 0;
    
    int tradeNum = 0;  
      
    double delta = 0;
    double totalWin = 0;
    double totalLoss = 0;
    double totalProfit = 0;

    for( int i = optimizingPeriods - 1; i > 0; i-- )
    {
        if( !inTrade && optimizer[i].rsiValue < rsiEntryLevel)// && optimizer[i + 1].rsiValue > entryLevel )
        {
            double profitCheck = 0;
            inTrade = true;
            tradeNum ++;
            orderOpenPrice = optimizer[i].close * (1 + bidAskSpread);

            if( orderOpenPrice == 0 ) break;

            for( int remainingBars = i - 1; remainingBars > 0; remainingBars-- )
            {
                
                // for first bar of trade bestEstimate is Close - Order open price
                if( remainingBars == i-1)
                {
                     bestEstimate[remainingBars] = ( optimizer[remainingBars].close - orderOpenPrice ) / orderOpenPrice;
                }
                else
                {
                     bestEstimate[remainingBars] = ( optimizer[remainingBars].close - optimizer[remainingBars+1].close ) / optimizer[remainingBars+1].close;
                }
                
                // Check if it hits stoploss
                if( inTrade && stopLoss != 0 && optimizer[remainingBars].close < orderOpenPrice * ( 1 - 0.01 * stopLoss ) )
                {
                    inTrade = false; // Turn the order off since stoploss was hit
                    i = remainingBars; // skip the bars used while the trade was active
                    numLoss++; // add to loss counter
                    delta = ( optimizer[remainingBars].close - orderOpenPrice ) / orderOpenPrice;
                    //Print("TradeNum = ", tradeNum, " profit = ",10000*delta);
                    totalLoss = totalLoss + 10000 * delta; // add up totalProfit
                    break;
                }

                // Check if it hits takeProfit
                if( inTrade && takeProfit != 0 && optimizer[remainingBars].close > orderOpenPrice * ( 1 + 0.01 * takeProfit ) )
                {
                    inTrade = false; // Turn the order off since stoploss was hit
                    i = remainingBars; // skip the bars used while the trade was active
                    numWin++; // add to loss counter
                    delta = ( optimizer[remainingBars].close - orderOpenPrice ) / orderOpenPrice;
                    //Print("TradeNum = ", tradeNum, " profit = ",10000*delta);
                    totalWin = totalWin + 10000 * delta; // add up totalProfit
                    break;
                }

                // Check if it hits nBarExit
                if( inTrade && ( i - remainingBars ) > nBarExit && nBarExit != 0 )
                {
                    inTrade = false; // Turn the order off since stoploss was hit
                    delta = ( optimizer[remainingBars].close - orderOpenPrice ) / orderOpenPrice;
                    //Print("TradeNum = ", tradeNum, " profit = ",10000*delta);

                    if( delta > 0 )
                    {
                        numWin++; // add to profit counter
                        i = remainingBars; // skip the bars used while the trade was on
                        totalWin = totalWin + 10000 * delta; // add up totalProfit
                        break;
                    }
                    else
                    {
                        numLoss++; // add to loss counter
                        i = remainingBars; // skip the bars used while the trade was on
                        totalLoss = totalLoss + 10000 * delta; // add up totalProfit
                        break;
                    }
                }
                
                // Check for RSI Exit
                if( inTrade && optimizer[remainingBars].rsiValue > rsiExitLevel )
                {
                    inTrade = false; // Turn the order off since stoploss was hit
                    delta = ( optimizer[remainingBars].close - orderOpenPrice ) / orderOpenPrice;
                    //Print("TradeNum = ", tradeNum, " profit = ",10000*delta);

                    if( delta > 0 )
                    {
                        numWin++; // add to profit counter
                        i = remainingBars; // skip the bars used while the trade was on
                        totalWin = totalWin + 10000 * delta; // add up totalProfit
                        break;
                    }
                    else
                    {
                        numLoss++; // add to loss counter
                        i = remainingBars; // skip the bars used while the trade was on
                        totalLoss = totalLoss + 10000 * delta; // add up totalProfit
                        break;
                    }
                }
            }
        }
        else
        {
            bestEstimate[i] = 0;
        }
    }
    
    numTrades = tradeNum;     
    accuracy = numWin / numTrades;
    
    if( numWin != 0 && numLoss !=0 )
    {   
      payoffRatio = (totalWin/numWin) / (-totalLoss/numLoss);
      expectancy =  accuracy * payoffRatio + accuracy - 1;
      tradesPerYear = numTrades / optimizingPeriods * 252;
    }
    
///////////////////////////////////// MonteCarlo Runs///////////////////////////////////////
      double twr25, mdd95, fraction;
      double TWR25 = 0;
   
        
      //create TWR and MDD Arrays
      double TWR[];
      ArrayResize(TWR,runs,0);
      double MDD[];
      ArrayResize(MDD,runs,0);
      
      fraction = 1.0;
      
      for( int k = 0 ; k < 10 ; k++ )
      {
         for( int a = 0 ; a < runs ; a++ )
         {
            // set variables for monteCarlo runs
            double equity = 1;
            double maxEquity = 1;
            double drawDown = 0;
            double maxDrawDown = 0;
            
            int randomTradeNumber = 0;
            double randomTrade = 0;
            double thisTrade = 0;
            
            // weighted distribution variables
            double horizonSoFar = 0;
            double weight = 0;
            
            /* uniform distribution
            for( int x = 0; x < forcastHorizon; x++ )
            {
               randomTradeNumber = (int)randomBetween( 0, optimizingPeriods - 1);
               randomTrade = bestEstimate[randomTradeNumber];
               thisTrade = equity * fraction * randomTrade;
               equity = equity + thisTrade;
               maxEquity = MathMax(equity,maxEquity);
               drawDown = (maxEquity - equity) / maxEquity;
               maxDrawDown = MathMax(drawDown,maxDrawDown);      
            }
            */
            
            // weighted distribution
            while( horizonSoFar < forcastHorizon )
            {
               randomTradeNumber = (int)randomBetween( 0, optimizingPeriods - 1);
               weight = 1 - (double)( randomTradeNumber / optimizingPeriods );
               horizonSoFar += weight;
               randomTrade = bestEstimate[randomTradeNumber]*weight;
               thisTrade = equity * fraction * randomTrade;
               equity = equity + thisTrade;
               maxEquity = MathMax(equity,maxEquity);
               drawDown = (maxEquity - equity) / maxEquity;
               maxDrawDown = MathMax(drawDown,maxDrawDown);      
            }
                       
            TWR[a] = equity;
            MDD[a] = maxDrawDown;           
         }
         
         ArraySort(TWR);
         ArraySort(MDD);
         
         int P25 = (int)MathFloor(0.25 * runs);
         int P95 = (int)MathFloor(confidenceLevel * runs);    
               
         twr25 = TWR[P25];
         mdd95 = MDD[P95];
         
         //Print(mdd95);
         
         if( MathAbs(mdd95 - mddLimit) > 0.005 && mdd95 != 0)
         {
            fraction = fraction * mddLimit / mdd95;
            continue;
         }
         else
         {
            safeF = fraction;
            TWR25 = twr25;
            MDD95 = 100 * mdd95;
            break;         
         }      
      }
      

      CAR25 = 100 * ( MathExp(MathLog(TWR25) / (forcastHorizon/252)) - 1 );
      CAR50 = 100 * ( MathExp(MathLog(TWR[(int)MathFloor(0.5 * runs)]) / (forcastHorizon/252)) - 1 );
      CAR95 = 100 * ( MathExp(MathLog(TWR[(int)MathFloor(0.95 * runs)]) / (forcastHorizon/252)) - 1 );
      CAR05 = 100 * ( MathExp(MathLog(TWR[(int)MathFloor(0.05 * runs)]) / (forcastHorizon/252)) - 1 );
      CAR75 = 100 * ( MathExp(MathLog(TWR[(int)MathFloor(0.75 * runs)]) / (forcastHorizon/252)) - 1 );      
    
   // Print("totalWin = ", totalWin, " numWin = ", numWin, " totalLoss = ", totalLoss,  " numLoss = ", numLoss);
   // Print("numTrades = ", numTrades, " accuracy = ", accuracy, " payoffRatio = ", payoffRatio );

//////////////////////////Create File to check results//////////////////////////////////////////////
      
      // Create System Backtest Report
      string fileName = StringConcatenate(AccountCompany()," - ",AccountNumber(),"\\",expertName," - ",magicNumber,"\\backtestData.csv");
      string accountLabel = StringConcatenate( AccountCompany()," - ",AccountNumber() );
      string systemLabel = StringConcatenate("rsiBasic");
      int fileHandle = FileOpen(fileName,FILE_CSV|FILE_WRITE,',');
      
      FileWrite(fileHandle, "index i","date[i]","rsi[i]","close[i]","bestEstimate[i]");
                   
         for( int i = optimizingPeriods - 1; i > 0; i-- )
         {                  
            FileWrite( fileHandle, i,optimizer[i].date, optimizer[i].rsiValue, optimizer[i].close, bestEstimate[i] );     
         }
         FileClose( fileHandle );

    return;
}