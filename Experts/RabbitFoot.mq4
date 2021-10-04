
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
extern string     GENERALSETTINGS      = "----- General Expert Settings -----";
extern string expertName = "Rabbit_Foot";         // Name of Trading System
extern datetime comissionDate = D'2018.01.01';      // YYYYMMDD  
extern int magicNumber = 1;

extern bool entryFlag = true;          //Permission to Enter Trades
extern bool reportHistory = true;      //Create Excel History File
extern bool errorPrint = false;        //Print Errors
extern bool emailReport = false;       //TroubleShooting Email

extern string     DISPLAYSETTINGS      = "----- System Display Settings -----";
extern int randomWait     = 0;  // Stagger EA's
extern int statusPause    = 60; // Pause for Status
extern int scanPause      = 0;  // Pause for Scans

extern string     MONEYMANAGEMENTSETTINGS      = "----- Money/Risk Management -----";
extern double accountPercent = 1.00;   //Ratio of Account Allocated
extern int maxGlobal = 20;             //Max Pos in MT4
extern int maxSymbols = 7;             //Max Pos in EA
extern int maxNumUSD = 3;              //Max Num US Stocks
extern int maxNumGBP = 2;              //Max Num UK Stocks
extern int maxNumEUR = 2;              //Max Num EU Stocks
extern int maxNumOthers = 1;           //Max Num Other Stocks
extern double fixedFraction = 0.2;     //fixedFraction
extern double maxSpread = 0.020;       //Max Allowable Spread
extern double maxShareValue = 9999;        //Max Share Value
extern double minShareValue = 0;          //Min Share Value
bool poundIsPence = false;      //UK Stocks listed in Pence

extern string     TRADINGSYSTEMSETTINGS      = "----- Trading System Parameters -----";
extern ENUM_TIMEFRAMES timeFrame = PERIOD_D1;          // Select TimeFrame
extern int minBars = 350;              //Min Bars Rqd

extern int filter_P1 = 40;             //HHV Filter Cut Off
extern int filter_P2 = 350;            //HHV Filter Array Size

extern double rsiPeriod = 4;
extern double rsiEntryLevel = 30;
extern double rsiExitLevel = 30;

extern bool hiddenStops = true;        //Hide Stops From Broker
extern double takeProfit = 0;          //takeProfit Percent Value
extern double stopLoss = 0;            //stopLoss Percent Value
extern int nBarExit = 0;               //nBarExit

extern string     SYSTEMMONITORING      = "----- Expected System Performance -----";
extern double expTradesPerYear = 100;     //Trades Per Year
extern double expAccuracy = 70;
extern double expPayoffRatio = 0.7;
extern double expExpectancy = 0.2;
extern double expAvgTrade = 0.5;
extern double expStDev = 3;

extern string     MONTECARLOSETTINGS      = "----- MonteCarlo Settings -----";
extern double  forcastHorizon = 2;
extern double mddLimit = 0.3;
extern double confidenceLevel = 0.95;
extern int  runs = 100000;
double expMDD;                             // Calculated on Init.

//--- Label = MagicNumber and ExpertName
string label = expertName + " " + AccountCompany();

//--- Order Management Settings
int roundLot = 10;                     //Round Num of Shares to Nearest
int minLot = 10;                       //Min Shares Per Order
int slippage = 1;

//--- Inhibit Trades for X minutes after new compilation of code
int timeDelay = 10;

//--- Comment Shorthands
string newLine = "\n";
string doubleSpace = "\n\n";

//--- Set Arrays
string SHARES[];
int SCANNED[];
double ARMED[];

int cycleCount = 0;
int flag = 1;
int arraySize;

string selectedWatchlist;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{   
   // Load Correct Watchlist for EA    
   if( AccountCompany() == "FxPro Financial Services Ltd" )
   { 
      selectedWatchlist = "FXPRO_ALL";
      ArrayCopy(SHARES,FXPRO_ALL,0,0,WHOLE_ARRAY); 
   }
   
   if( AccountCompany() == "JFD Group Ltd" )
   {
      ArrayCopy(SHARES,JFD_ALL,0,0,WHOLE_ARRAY); 
      selectedWatchlist = "JFD_ALL";
      poundIsPence = true;
   }
   
   if( AccountCompany() == "FXTM" ) 
   {
      ArrayCopy(SHARES,FOREXTIME_ALL,0,0,WHOLE_ARRAY);
      selectedWatchlist = "FOREXTIME_ALL";
   }
   
   arraySize = ArraySize(SHARES);
   
   ArrayResize(SCANNED,arraySize,0);
   ArrayFill(SCANNED,0,arraySize,0);
   
   ArrayResize(ARMED,arraySize,0);
   ArrayFill(ARMED,0,arraySize,0);
      
   expMDD = MDD9510K(expAvgTrade,expStDev,(int)expTradesPerYear,(int)forcastHorizon,confidenceLevel,runs);
   
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
   if( cycleCount < 1)
   {
      Comment("Initial Pause ... ", randomWait, " Seconds");
      Sleep(randomWait*1000);
   }   
   cycleCount ++;

   //--- TimeDelay for Trading
   if( timeDelay != 0 )
   {
      if( NewMinute() ) timeDelay -- ;
   }
   
   //--- Status Display   
   Status();
   Sleep( 1000 * statusPause );
   
   //--- Manage Open Positions
   PositionManager();
   Sleep( 1000 * scanPause );
   
   //--- Open New Positions
   SymbolScanner();
   Sleep( 1000 * scanPause );
   
   PriceScanner();
   Sleep( 1000 * scanPause );   
   
   //--- Reset flag to generate error report for the hour
   int min = TimeMinute(TimeCurrent());
   if( min >= 5 && min < 10 )  flag = 1;
   
   //--- Update Trade History Report
   if( reportHistory && NewDay() )
   {     
      MATLAB2015();
      MATLAB2015( expertName, magicNumber, comissionDate );
      BrokersStatement();
   }
}

//+------------------------------------------------------------------+
//| EA Execution Functions                                           |
//+------------------------------------------------------------------+

//--- Display the EA General Status

void Status()
{  
   static double numTrades = -1, tradesPerYear = 0, expNumTrades = 0;
   static string symbol = "";
   static double car, dd, mdd, accuracy, payoffRatio, expectancy, avgTrade, stDev, tTest, expTTest, twoTail, equityScore, scoreE50, scoreDD, scoreMDD, safeF, CAR25, MDD95;   
   static double totalProfit = 0, systemProfit = 0, systemProfitPct = 0;
   
   int currentNumTrades = TotalTradesHistory(magicNumber,comissionDate);   
   
   if( currentNumTrades != numTrades )
   {
      numTrades = currentNumTrades;
      
      // newTrade Closed re-run calculations
      
      datetime timeCurrent = TimeCurrent();
      datetime firstTradeDate = TimeCurrent();      
      
      // Create Tradelist and calculate standard Metrics  
         
      int    numWinners = 0, numLosers = 0;
      double delta = 0, sumWinners = 0, sumLosers = 0, avgWin = 0, avgLoss = 0, sumX2 = 0, numDays = 1;
              
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
         
         totalProfit += ( OrderProfit() + OrderCommission() + OrderSwap() );
         
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
           
      if( numTrades > 0 ) 
      {      
         ArraySort(tradeArray);
         for( int a = 0; a < numTrades; a++)
         {
           tradeList[a] = tradeArray[a][1];
         }
         
         firstTradeDate = (datetime)tradeArray[0][0];
         numDays = MathMax(1, 365 * ( TimeYear(timeCurrent) - TimeYear(firstTradeDate) ) + TimeDayOfYear(timeCurrent) - TimeDayOfYear(firstTradeDate));       
         tradesPerYear = (int) ( ( numTrades /  numDays ) * 365 );

         avgTrade = ( sumWinners - sumLosers ) / numTrades;
         for( int a = 0 ; a < j ; a++ ) 
         {
            delta = tradeList[a];
            sumX2 += ( ( delta - avgTrade ) * ( delta - avgTrade ) );
         }     
      
         systemProfit = totalProfit;
         systemProfitPct = 100 * totalProfit / (AccountBalance() - totalProfit);      
         accuracy = double (numWinners) / double (numTrades);       
         stDev = sqrt(sumX2 / numTrades);      
      }       
      
      if( numWinners > 0)    avgWin = sumWinners / numWinners;
      if( numLosers > 0)     avgLoss = sumLosers / numLosers;
      if( avgLoss != 0 )     payoffRatio = avgWin / avgLoss;
      
      expectancy =  accuracy * payoffRatio + accuracy - 1;
           
      //--- Equity Runs ---//
      
      // fixedFraction 
       
      double   trade = 0,
               equity = 1,
               maxEquity = 0,
               drawDown = 0,
               maxDrawDown = 0;
      
      for( int b = 0 ; b < j; b++ )
      {      
         trade = equity * fixedFraction * tradeList[b];
         equity += trade;
         
         if(equity > maxEquity)        
         {
            maxEquity = equity;
         }
         
         drawDown = 100 * ( maxEquity - equity ) / equity;
         
         if( maxDrawDown < drawDown )  
         {
            maxDrawDown = drawDown;
         }     
      }
      
      car = 100 * ( MathPow(( 1 + (fixedFraction * avgTrade) ), tradesPerYear) - 1 );
      mdd = maxDrawDown;
      dd = drawDown; 
      
      // 10K per Trade
        
      trade = 0;
      equity = 0;
      maxEquity = 0;
      drawDown = 0;
      maxDrawDown = 0;
      
      for( int c = 0 ; c < j; c++ )
      {      
         trade = 10000 * tradeList[c];
         equity += trade;
         
         if(equity > maxEquity)        
         {
            maxEquity = equity;
         }
         
         drawDown = maxEquity - equity;
         
         if( maxDrawDown < drawDown )  
         {
            maxDrawDown = drawDown;
         }     
      }
      
      double n = 0, mu = 0, sigma = 0;
      double lowerCurve = 0, middleCurve = 0, upperCurve = 0;
      
      n = numTrades;
      mu = expAvgTrade / 100 * 10000;
      sigma = expStDev / 100 * 10000;
     
      if(expStDev != 0) expTTest = expAvgTrade * sqrt(expTradesPerYear) / expStDev; 
      if(stDev != 0) tTest = avgTrade * sqrt(tradesPerYear) / stDev;
      twoTail = twoTailedTTest(avgTrade,expAvgTrade/100,stDev,expStDev/100,tradesPerYear,expTradesPerYear); 
                
      middleCurve = n * avgTrade * 10000;
      upperCurve = n * mu + MathSqrt(n) * 1.645 * sigma;
      lowerCurve = n * mu - MathSqrt(n) * 1.645 * sigma;
      
      if(upperCurve != lowerCurve)
      {
         equityScore = (middleCurve - lowerCurve) / (upperCurve - lowerCurve);
      } 
       
       scoreE50 = 0;
       if(expTradesPerYear != 0 && expAvgTrade != 0)
       {
         scoreE50 = tradesPerYear * avgTrade / ( expTradesPerYear * expAvgTrade / 100 );
       }
       
       scoreMDD = 1;
       if(expMDD != 0)
       {
         scoreMDD = maxDrawDown / expMDD ;
       }
       
       scoreDD = 1;
       if(expMDD != 0)
       {
         scoreDD = drawDown  / expMDD ;
       }
       
       expNumTrades = 0;
       if(tradesPerYear != 0 && expTradesPerYear != 0)
       {
         expNumTrades = numTrades / tradesPerYear * expTradesPerYear;
       } 
   
      /////////////// MonteCarlo Runs
      double twr25, mdd95, fraction;
      double TWR25 = 0;
      
      if( numTrades > 20)
      {     
         //create TWR and MDD Arrays
         double TWR[];
         ArrayResize(TWR,runs,0);
         double MDD[];
         ArrayResize(MDD,runs,0);
         
         fraction = fixedFraction;
         
         for( int k = 0 ; k < 10 ; k++ )
         {
            for( int a = 0 ; a < runs ; a++ )
            {
               // Set Variables for MC Run
               equity = 1;
               maxEquity = 1;
               drawDown = 0;
               maxDrawDown = 0;
               
               int randomTradeNumber = 0;
               double randomTrade = 0;
               double thisTrade = 0;
               
               for( int x = 0; x < forcastHorizon*tradesPerYear; x++ )
               {
                  randomTradeNumber = (int)randomBetween( 0, numTrades - 1);
                  randomTrade = tradeList[randomTradeNumber];
                  thisTrade = equity * fraction * randomTrade;
                  equity = equity + thisTrade;
                  maxEquity = MathMax(equity,maxEquity);
                  drawDown = (maxEquity - equity) / maxEquity;
                  maxDrawDown = MathMax(drawDown,maxDrawDown);      
               }
               
               //Print(a);      
               
               TWR[a] = equity;
               MDD[a] = maxDrawDown;    
               //Sleep(1);        
            }
            
            ArraySort(TWR);
            ArraySort(MDD);
            
            int P25 = (int)MathFloor(0.25 * runs);
            int P95 = (int)MathFloor(confidenceLevel * runs);    
                  
            twr25 = TWR[P25];
            mdd95 = MDD[P95];
            
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
         CAR25 = 100 * ( MathExp(MathLog(TWR25) / forcastHorizon) - 1 );
      }
      
      // Create System Performance Report
      string fileName = StringConcatenate(AccountCompany()," - ",AccountNumber(),"\\",expertName," - ",magicNumber,"\\systemPerformance.csv");
      string accountLabel = StringConcatenate( AccountCompany()," - ",AccountNumber() );
      string systemLabel = StringConcatenate(expertName," - ",magicNumber);
      string startDate = StringConcatenate( TimeDay(comissionDate),"/",TimeMonth(comissionDate),"/",TimeYear(comissionDate)); 
      int fileHandle = FileOpen(fileName,FILE_CSV|FILE_WRITE,',');
      
      FileWrite(fileHandle, "TradeNumber","Equity","P05","P25","P50","P95","","TradeNumber","DrawDown","DrawDownLimit","","Metric","Result","backTest");
      FileWrite(fileHandle, "0","0","0","0","0","0","","","","","","","","");     
         trade = 0;
         equity = 0;
         maxEquity = 0;
         drawDown = 0;
         maxDrawDown = 0;
         
         middleCurve = 0;
         upperCurve = 0;
         lowerCurve = 0;
         
         int tradeNumber = 0;
                 
         for( int i = 0 ; i < MathMax(j,18); i++ )
         {                  
            tradeNumber = i + 1;
            
            if( i >= j )
            {
               trade = 0;
            }
            else
            {
               trade = 10000 * tradeList[i];
            }
            
            equity += trade;
            
            if(equity > maxEquity)        
            {
               maxEquity = equity;
            }
            
            drawDown = maxEquity - equity;
            
            if( maxDrawDown < drawDown )  
            {
               maxDrawDown = drawDown;
            }
            
            //z - score values ( probability under the curve to the left where centre is zero )
            //0.01 = -2.330   0.99 = 2.33
            //0.05 = -1.645   0.95 = 1.645
            //0.25 = -0.675   0.75 =0.675
            //0.50 = 0
            
            string eq, p05,p25,p50,p95;
            
            eq = DoubleToString( equity,2 );
            p50 = DoubleToString( tradeNumber * expAvgTrade / 100 * 10000 , 2 );
            p05 = DoubleToString( tradeNumber * mu + MathSqrt(tradeNumber) * -1.645 * sigma, 2 );
            p25 = DoubleToString( tradeNumber * mu + MathSqrt(tradeNumber) * -0.675 * sigma, 2 );
            p95 = DoubleToString( tradeNumber * mu + MathSqrt(tradeNumber) *  1.645 * sigma, 2 );
         
            if (i == 0 ){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","accountDetails",accountLabel,"");continue; }
            if (i == 1 ){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","systemDetails",systemLabel,"");continue; }
            if (i == 2 ){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","commissionDate",startDate,"");continue; }
            if (i == 3 ){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","numTrades",IntegerToString((int)numTrades),expNumTrades);continue; }
            if (i == 4 ){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","tradesPerYear",IntegerToString((int)tradesPerYear),expTradesPerYear);continue; }
            if (i == 5 ){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","accuracy",DoubleToString(100*accuracy,2),expAccuracy);continue; }
            if (i == 6 ){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","payoffRatio",DoubleToString(payoffRatio,2),expPayoffRatio);continue; }            
            if (i == 7 ){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","expectancy",DoubleToString(expectancy,2),expExpectancy);continue; }          
            if (i == 8 ){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","avgTrade",DoubleToString(100*avgTrade,2),expAvgTrade);continue; }
            if (i == 9 ){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","stDev",DoubleToString(100*stDev,2),expStDev);continue; }
            if (i == 10){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","T-Test",DoubleToString(tTest,2),expTTest); continue; }
            if (i == 11){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","T-Test(twoTail)",DoubleToString(twoTail,2),"");continue; }
            if (i == 12){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","SafeF",DoubleToString(safeF,2),"");continue; }
            if (i == 13){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","CAR25",DoubleToString(CAR25,2),"");continue; }
            if (i == 14){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","equityScore",DoubleToString(100*equityScore,2),"");continue; }
            if (i == 15){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","profitScore",DoubleToString(100*scoreE50,2),"");continue; }
            if (i == 16){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","ddScore",DoubleToString(100*scoreDD,2),"");continue; }
            if (i == 17){ FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD,"","mddScore",DoubleToString(100*scoreMDD,2),"");continue; }
            else
            FileWrite( fileHandle,tradeNumber,eq,p05,p25,p50,p95,"",tradeNumber,-drawDown,-expMDD);     
         }
         FileClose( fileHandle );       
   }

   double Spread = Spread(symbol);

   // Calculations checked now display status    
   string expertDetails = StringConcatenate
      (
          //newLine, AccountCompany(),
          newLine, expertName," - ",magicNumber, " - ",comissionDate,
          newLine, "Account Number ", AccountNumber(),
          newLine,"counter = ", cycleCount                 
      );   
   
   string expertSettings = StringConcatenate
      (   
          doubleSpace, "watchlist        = ", selectedWatchlist,      
          newLine, "maxOpenPos  = ", maxSymbols, 
          newLine, "fixedFraction   = ", fixedFraction,
          newLine, "trendFilter      = ", filter_P1," / ",filter_P2,
          newLine, "rsiPeriod        = ", rsiPeriod,
          newLine, "rsiEntry         = ", rsiEntryLevel,
          newLine, "rsiExit            = ", rsiExitLevel, 
          newLine, "takeProfit       = ", takeProfit,
          newLine, "stopLoss         = ", stopLoss,
          newLine, "nBarExit         = ", nBarExit
      );
   
   string expertPerformance = StringConcatenate
      (                          
          doubleSpace, "----- Actual Results -----",
   
          newLine, "numOpenPos      = ", CountSystemOrders( OP_BUY, magicNumber ), " / ", maxSymbols,
          newLine, "openDrawDown  = ", DoubleToString( ( 100 * ( AccountBalance() - AccountEquity() ) / AccountBalance() ), 2 ), " %",
          doubleSpace, "profit             = $",DoubleToString(systemProfit,0)," / ",DoubleToString(systemProfitPct,0),"%",
          newLine, "car                = ", DoubleToString(car,2)," %",
          newLine, "mdd              = ", DoubleToString(mdd,2)," %",
          newLine, "dd                 = ", DoubleToString(dd,2)," %"                                                  
      );
   string expertPerformance2 = StringConcatenate
      (    
          doubleSpace, "----- System Statistics -----",
          newLine, "numTrades     = ", numTrades,"       ( ",DoubleToString(expNumTrades,0)," )",
          newLine, "tradesPerYear = ", DoubleToString( tradesPerYear, 0 ), "      ( ",DoubleToString(expTradesPerYear,0)," )",
          newLine, "accuracy        = ", DoubleToString( accuracy, 2 ),"     ( ",DoubleToString(expAccuracy,1), " )",
          newLine, "payoffRatio    = ", DoubleToString( payoffRatio, 2 ),"     ( ",DoubleToString(expPayoffRatio,2), " )",
          newLine, "expectancy     = ", DoubleToString( expectancy, 2 ),"     ( ",DoubleToString(expExpectancy,2), " )",
          newLine, "avgTrade       = ", DoubleToString( 100*avgTrade, 4 ),"     ( ",DoubleToString(expAvgTrade,2), " )",
          newLine, "stDev            = ", DoubleToString( 100*stDev, 4 ),"     ( ",DoubleToString(expStDev,2), " )",
          newLine, "tTest             = ", DoubleToString( tTest, 2 ),"     ( ",DoubleToString(expTTest,2), " )",
          newLine, "twoTailtTest   = ", DoubleToString( twoTail, 2 )
      );
   
   string expertPerformance3 = StringConcatenate
      ( 
          doubleSpace, "----- System vs Backtest -----",
          newLine, "equityCurve             ", visualScore(equityScore),"   ",DoubleToString(equityScore,2),
          newLine, "equityPerYear           ", visualScore(scoreE50),"   ",DoubleToString(scoreE50,2),
          newLine, "drawDown               ", visualScore(scoreDD),"   ",DoubleToString(scoreDD,2),
          newLine, "maxDrawDown         ", visualScore(scoreMDD),"   ",DoubleToString(scoreMDD,2),
          //newLine, "alphaLock @ $ ",DoubleToString(maxDrawDown,0)   
          
          doubleSpace, "----- MonteCarlo Analysis -----",
          newLine, "forcastHorizon = ", forcastHorizon,
          newLine, "maxDD95 = ", mddLimit,
          
          newLine, "safeF = ", DoubleToString(safeF,2),
          newLine, "CAR25 = ",DoubleToString(CAR25,2)
          //newLine, "MDD95 = ",DoubleToString(MDD95,2)             
      );         
   
   string symbolInfo = StringConcatenate
      (
          //newLine, "iBarShift = ",iBarShift(symbol,PERIOD_D1,TimeCurrent(),true),
          
          doubleSpace, symbol, " ", SymbolInfoString( symbol, SYMBOL_CURRENCY_BASE )," [ ",TimeConvert(MarketOpenTime( symbol )), "  ", TimeConvert(MarketCloseTime( symbol ))," ] ", !SessionClosed(symbol,TimeCurrent()),
          newLine, "closingWindow = "," [ ",TimeConvert(MarketCloseTime( symbol ) - 5 * 60), "  ", TimeConvert(MarketCloseTime( symbol ))," ] ",
          newLine, "shareValue = ", DoubleToString( ShareValue( symbol, poundIsPence ), 2 )," ",AccountCurrency(),
          newLine, "spread = ",DoubleToString(Spread,4),
          newLine, "positionSize = ", PositionSize( symbol, MoneyManagement( fixedFraction, accountPercent ), poundIsPence ), " lots / $", DoubleToString( PositionSize( symbol, MoneyManagement( fixedFraction, accountPercent ), poundIsPence ) * ShareValue( symbol, poundIsPence ) * SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE), 0 )
      );
      
   string openTradeInfo = StringConcatenate
      (
          newLine,
          newLine, "orderOpenPrice = ", DoubleToString( OpenPrice( symbol, magicNumber ), 2 ),
          newLine, "barsSinceEntry = ", BarsSinceEntry( symbol,timeFrame, magicNumber ),
          newLine, "takeProfitLevel = ", DoubleToString( TakeProfitPrice( symbol, takeProfit, magicNumber ), Digits )
      );    
   
   string AlphaLock = StringConcatenate
      (
         newLine,
         " ... WARNING!!! SYSTEM IS IN ALPHA LOCK ... ",
         newLine
      );  
   
   if( OpenPrice( _Symbol, magicNumber ) != 0 )
   {     
      Comment( expertDetails, expertSettings, expertPerformance, expertPerformance2, expertPerformance3, symbolInfo, openTradeInfo );
   }
   else
   {   
      Comment(expertDetails, expertSettings, expertPerformance, expertPerformance2, expertPerformance3, symbolInfo );
   }  
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

      barsSinceEntry = BarsSinceEntry( symbol, timeFrame, magicNumber);   
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
      if( MarketClosingWindow( symbol, timeCurrent, 5 ) == true )
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
                ExitLong( symbol, bid, slippage, magicNumber, Black );
                Alert( "EA_RSI_Exit ", symbol );
                continue;
            }
         
            if( nBarExit != 0 && barsSinceEntry >= nBarExit )
            {
                ExitLong( symbol, bid, slippage, magicNumber, Red );
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

//--- Look to Enter New Positons

void SymbolScanner()
{
   Comment(doubleSpace, "Executor()");

   //--- Log the time that the TradeManager begins its run   
   datetime StartTimer = TimeLocal(); 
   datetime currentTime = TimeCurrent();
   int currentDay = TimeDay(currentTime);
         
   //--- Initialize Counters for Data Errors
   int   symbolNameError = 0;

   // --- Cycle through watchlist
   for( int i = 0; i<arraySize; i++ )
   {
      //--- Assign _Symbol to variable symbol
      string symbol = SHARES[i];
      
      //--- Eliminate Stocks that are untradable ---//
      
      // Does the Symbol Exits - prevents EA failure if symbol removed by broker .....
      if( SymbolNameCheck( symbol ) == false )
      {
         if( errorPrint )
         {
             Print( symbol, " Not found in watchlist ... Line 435" );
         }

         symbolNameError += 1;
         continue;
      }
      
      // If Session is Closed reset SCANNED & ARMED Arrays
      if( SessionClosed(symbol,currentTime) == true )
      {   
         //Print(symbol," closed");
         ARMED[i] = 0;
         SCANNED[i] = 0;
         continue;      
      } 
      
      // Has Symbol already been SCANNED 
      if( SCANNED[i] > 0 )
      {
         continue;
      }
      
      // Has Today's Candle Loaded     
      if( TimeDay(iTime(symbol,timeFrame,0)) != currentDay )
      {         
         ARMED[i] = 0;
         SCANNED[i] = -1;
         
         // Before Continuing attempt to load data by calling iBars
         int Loading = iBars(symbol,timeFrame);
         Sleep(100);
         
         continue;
      }
      
      // --- beyond this line, the data has loaded correctly thus SCANNED >= 1 && ARMED == 0 
      
      // Is there already a position open for today
      if( CountExpertOrders(symbol,ORDER_TYPE_BUY,magicNumber) > 0 ) 
      {
         ARMED[i] = 0;
         SCANNED[i] = 99;
         continue;      
      } 
      
      // If there was already an open position on this Bar - disarm the symbol
      if( ExitBar( symbol, timeFrame, magicNumber ) ) // Searches history ... computationally expensive
      {         
         ARMED[i] = 0;
         SCANNED[i] = 99;
         continue;
      }
      
      // Are there enough bars for the EA? 
      if ( iBars( symbol, timeFrame ) < minBars )
      {
         if( errorPrint )
         {
             Print( symbol, " Not Enough Bars on Chart ... Line 455" );
         }

         ARMED[i] = 0;
         SCANNED[i] = 1;        
         continue;
      }      
      
      // Is the share price outside acceptable range 
      double shareValue = 0;
      shareValue = ShareValue( symbol );
      if( shareValue == 0 || shareValue < minShareValue || shareValue > maxShareValue )
      {
         Print(symbol,"share value = ",shareValue);
         
         ARMED[i] = 0;
         SCANNED[i] = 2;
         continue;
      }   
                
      // Is there a split in the Data?      
      if( StockSplitCheck( symbol, minBars ) == false )
      {
         if( errorPrint )
         {
            Print( symbol, " Stock split detected ... Line 480" );
         }
         
         ARMED[i] = 0;
         SCANNED[i] = 3;         
         continue;
      }
      
      if( ValidDateSequence( symbol ) == false )
     {
         if( errorPrint )
         {
             Print( symbol, " Dates are out of sequence" );
         }
         
         ARMED[i] = 0;
         SCANNED[i] = 4;         
         continue;
     }       
      
//////////////////////////////--- Check for a valid entry signal ---///////////////////////////////////
      
      //Step through conditions and jump out of loop if condition not met.
      //Start with the most restrictive conditions to jump out ASAP & improve excecution time.
            
      // Is the Stock above the trend filter
      double trendFilter = false;
      trendFilter = HHV_Filter(symbol,timeFrame,filter_P1,filter_P2);      
      
      if(trendFilter == false)
      {         
         ARMED[i] = 0;
         SCANNED[i] = 99;
         continue;
      }
      
      // Calculate EntryLimit Price
      double entryPrice = 0;
      entryPrice = ReverseRSI(symbol,timeFrame,rsiPeriod,rsiEntryLevel);
      
      if( entryPrice == 0 )
      {
         if( errorPrint )
         {
            Print( symbol, " ReverseRSI Error " );
         }
         
         ARMED[i] = 0;
         SCANNED[i] = 5;
         continue;
      }          
      
      //--- Stock has passed all requirements and can now be ARMED at the entryPrice   
      
      ARMED[i] = entryPrice;
      SCANNED[i] = 100;
      
      // consider lots array,          
   
   }
   
   // Initialize Counters for Scan Processing Errors
   
   int   marketsScanned = 0,
         armedCount = 0,
         marketsClosed = 0,
         newCandleError = 0,
         barCountError = 0,         
         priceRangeError = 0,
         stockSplitError = 0,
         dateSequenceError = 0,
         variableError = 0;                 

   for( int i = 0; i<ArraySize(SHARES); i++ )
   {
      if( SCANNED[i] > 0  ) marketsScanned++;
      if( ARMED[i]   > 0  ) armedCount++;
      
      if( SCANNED[i] == 0  ) marketsClosed++;      
      if( SCANNED[i] == -1 ) newCandleError++;     
      if( SCANNED[i] == 1  ) barCountError++;      
      if( SCANNED[i] == 2  ) priceRangeError++;    
      if( SCANNED[i] == 3  ) stockSplitError++;    
      if( SCANNED[i] == 4  ) dateSequenceError++;  
      if( SCANNED[i] == 5  ) variableError++;             
   }   
   
   int totalErrors =  newCandleError + barCountError + priceRangeError + stockSplitError + dateSequenceError + variableError;
   
   Comment  (
      doubleSpace, "TradeExecutor ( ) Completed in ... ", TimeMinute( TimeLocal() - StartTimer )*60 + TimeSeconds(TimeLocal() - StartTimer) , " Seconds", 
      doubleSpace, "Trade Inhibit Timer ... ", timeDelay,
      doubleSpace, "Symbol Name Not Found ... ", symbolNameError,
      doubleSpace, "Session is Now Closed ... ", marketsClosed,
      doubleSpace, "Waiting for New Candle ... ", newCandleError,
      
      doubleSpace, "Not Enough Bars on Chart ... ", barCountError,
      doubleSpace, "Symbol Too Expensive / Cheap ... ", priceRangeError,            
      doubleSpace, "Stock Split Detected ... ", stockSplitError,
      doubleSpace, "Indicator Failure ... ", variableError,
      
      doubleSpace, "Total Symbols Scanned ... ", marketsScanned,
      doubleSpace, "Total Errors ... ", totalErrors,
      
      doubleSpace, "Stocks Available ... ", marketsScanned - totalErrors,
      doubleSpace, "Stocks Armed ... ", armedCount
            );   


   // Write when Flag > 0
   if( flag > 0 )
   {
      string fileName = StringConcatenate(AccountCompany()," - ",AccountNumber(),"\\",expertName," - ",magicNumber,"\\System Logs\\SystemLog - ",TimeHour(TimeCurrent()),"00.csv");
      int fileHandle = FileOpen(fileName,FILE_CSV|FILE_WRITE,',');
      
      FileWrite(fileHandle, "SYSTEM LOG SUMMARY");
      FileWrite(fileHandle, "Server Time",TimeConvert(TimeCurrent()));
      FileWrite(fileHandle, "Total Number of Symbols", arraySize);
      FileWrite(fileHandle, "Symbol Name Not Found", symbolNameError);
      FileWrite(fileHandle, "Session is Now Closed", marketsClosed);
      FileWrite(fileHandle, "Waiting for New Candle", newCandleError);
      FileWrite(fileHandle, "Not Enough Bars on Chart", barCountError);
      FileWrite(fileHandle, "Symbol Too Expensive / Cheap", priceRangeError);
      FileWrite(fileHandle, "Stock Split Detected", stockSplitError);
      FileWrite(fileHandle, "Total Symbols Scanned", marketsScanned);
      FileWrite(fileHandle, "Total Errors", totalErrors);
      FileWrite(fileHandle, "Stocks Available", marketsScanned - totalErrors);
      FileWrite(fileHandle, "Stocks Armed", armedCount);
      FileWrite(fileHandle, "");
      
      FileWrite(fileHandle, "SYSTEM LOG DETAILS");
      FileWrite(fileHandle, "NAME","SPREAD","SCANNED","ARMED","RESULT");
      
      for( int i = 0; i<arraySize; i++ )
      {          
         string Error = "";
         
         if( SCANNED[i] == 0  ) Error = "marketsClosed";
         if( SCANNED[i] == -1 ) Error = "newCandleError";     
         if( SCANNED[i] == 1  ) Error = "barCountError";     
         if( SCANNED[i] == 2  ) Error = "priceRangeError";    
         if( SCANNED[i] == 3  ) Error = "stockSplitError";    
         if( SCANNED[i] == 4  ) Error = "dateSequenceError";  
         if( SCANNED[i] == 5  ) Error = "variableError";
         if( SCANNED[i] == 6  ) Error = "maxSymbolsReached";
         if( SCANNED[i] == 7  ) Error = "maxSymbolTypeReached";
         if( SCANNED[i] == 99  ) Error = "Nil";
         if( SCANNED[i] == 100 ) Error = "Armed";
                        
         FileWrite( fileHandle,SHARES[i],DoubleToString(Spread(SHARES[i]),5),SCANNED[i],ARMED[i],Error);
      }
      FileClose( fileHandle );
      flag = 0;
   }
}   

void PriceScanner()
{       
   Comment(doubleSpace, "PriceScanner()");
      
   // --- Cycle through watchlist
   for( int i = 0; i<arraySize; i++ )
   {           
      // Is timeDelay != 0 then break the for loop
      if( timeDelay > 0 ) break;
      
      // If not scanned or armed then skip
      if ( SCANNED[i] == 0 || ARMED[i] == 0 ) continue;
      
      // Check Position Count if at Max Stop Scanning All Symbols for rest of the session - to avoid late entries in the day
      if ( CountGlobalOrders() >= maxGlobal ) 
      {
         for( int j = 0; j<arraySize; j++ )
         {
            SCANNED[j] = 6;
            ARMED[j] = 0;
         }
         break;
      }
      // Check Position Count if at Max Stop Scanning All Symbols for rest of the session - to avoid late entries in the day
      if ( CountSystemOrders(ORDER_TYPE_BUY,magicNumber) >= maxSymbols )
      {
         for( int j = 0; j<arraySize; j++ )
         {
            SCANNED[j] = 6;
            ARMED[j] = 0;
         }
         break;
      }      
      // Assign _Symbol to variable symbol
      string symbol = SHARES[i];
      
      // Check max number of US / UK / EU / Other ... Stocks reached
      int numUS = CountSystemOrdersUS(ORDER_TYPE_BUY,magicNumber);
      int numUK = CountSystemOrdersGBP(ORDER_TYPE_BUY,magicNumber);
      int numEU = CountSystemOrdersEUR(ORDER_TYPE_BUY,magicNumber);
      int numOthers = CountSystemOrdersOthers(ORDER_TYPE_BUY,magicNumber);
      
      // If stock is US and Max US Reached then skip disarm symbol
      string symbolBase = SymbolInfoString(symbol,SYMBOL_CURRENCY_BASE);
      if( 
            ( symbolBase == "USD" && numUS >= maxNumUSD ) ||
            ( symbolBase == "GBP" && numUS >= maxNumGBP ) ||
            ( symbolBase == "EUR"  && numUS >= maxNumEUR ) ||
            ( symbolBase != "USD" && symbolBase != "GBP" && symbolBase != "EUR" && numOthers >= maxNumOthers )         
        )
      {
         SCANNED[i] = 7;
         ARMED[i] = 0;
      }
      
      // Is Asking Price Less than EntryLimit Price
      double ask = -1;
      ask = SymbolInfoDouble(symbol,SYMBOL_ASK);
      if( ask == -1 || ask > ARMED[i] )
      {
         continue;
      }
      
      // Is the spread too expensive
      if( Spread(symbol) > maxSpread )
      {
         if( errorPrint )
         {
            Print( symbol, " Spread is Too Expensive ... ", Spread(symbol)  );
         }
         continue;
      } 
      
      // If Position already open - disarm this symbol
      if( CountExpertOrders(symbol,ORDER_TYPE_BUY,magicNumber) > 0 ) 
      {
         ARMED[i] = 0;
         continue;      
      } 
           
      // Are there enough funds           
      double  lots = 0,
              sharesPerLot = 0,
              tradeValue = 0,
              fundsAvailable = 0,
              takeProfitPrice = 0;
                       
      lots = PositionSize( symbol, MoneyManagement( fixedFraction ), poundIsPence );
      sharesPerLot = SymbolInfoDouble( symbol,SYMBOL_TRADE_CONTRACT_SIZE );
      tradeValue = lots * sharesPerLot * ShareValue( symbol, poundIsPence );
      fundsAvailable = accountPercent * fixedFraction * maxSymbols * AccountBalance() - SystemExposure( magicNumber, poundIsPence );
   
      if( tradeValue > fundsAvailable || tradeValue == 0 )
      {
         if( errorPrint )
         {
            Print( symbol, " Not Enough Funds ... Line 590" );
         }
         continue;
      }
   
      EnterLong( symbol, lots, ask, slippage, 0, 0, magicNumber, label );
      continue;  
   }
   
   Comment(doubleSpace, "PriceSanner() Completed");
}



//+------------------------------------------------------------------+
//| EA Specific Function                                             |
//+------------------------------------------------------------------+

void sendEmail( string symbol, double barShift, double barWidth, double spread, double ask, double rsi0)
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
         newLine, "RSI0 ",DoubleToString( rsi0,4 ),
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
         newLine, "RSI2 ",DoubleToString( customRSI(symbol,timeFrame,rsiPeriod,2),4 ),
         
         doubleSpace, "VARIABLES",
         newLine, "Spread ", DoubleToString(spread,4),
         newLine, "barShift ", DoubleToString(barShift,2),
         newLine, "barWidth ", DoubleToString(barWidth,2)
      );
      
      string body = StringConcatenate(subject,section1,section2);
      SendMail("TradeEntryReport",body);
}

