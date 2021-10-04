//+------------------------------------------------------------------+
//|                                              martyMartingale.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Import Structures Classes and Include Files                      |
//+------------------------------------------------------------------+  
//--- Import Include Files
#include <myFunctionsForex.mqh>

MqlTick  m_tick;               // structure of tick;

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+
//--- External Inputs

extern int magicNumber = 10001;

extern double lotSize = 0.01;
//extern double multi = 10000;

extern int maPeriod = 200;
extern int maPeriodDaily = 20;

extern int rsiPeriod = 2;
extern int rsiEntry = 5;
extern int rsiExit = 30;

extern double takeProfitPips = 85;

//extern double maxDrawDown = 50;
extern double gridSpacing = 10;
extern int nPosBreakEven = 10;
extern int nPosMax = 15;

int maxSlippage = 30;
double lowestEquity = 100;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
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
   int numOpenLong = 0, numOpenShort = 0;
   
   numOpenLong = CountExpertOrders(Symbol(),ORDER_TYPE_BUY,magicNumber);
   numOpenShort = CountExpertOrders(Symbol(),ORDER_TYPE_SELL,magicNumber);
   
   double equityLevel = 100 * AccountEquity() / AccountBalance();
   
   if( equityLevel < lowestEquity )
   {
      lowestEquity = equityLevel;
   }

         
   if( NewBar() )
   {     
      Comment(equityLevel, "\n", 100 - lowestEquity);
      
      if( numOpenLong != 0)
      {   
         if( equityLevel < 90)
         {
            ExitLong(Symbol(),Ask,100,magicNumber,1);
            return;
         }
         tradeManagerBuy();
         return;
      }
   
      if( numOpenShort != 0)
      {         
         if( equityLevel < 90)
         {
            ExitShort(Symbol(),Bid,100,magicNumber);
            return;
         }
         tradeManagerSell();
         return;
      }
            
      //if( numOpenLong + numOpenShort == 0)
      {
         enterTrade();
         return;
      }
   }
     
  }
//+------------------------------------------------------------------+

double ComputeFib( int n )
{
    double f[100];
    //int j;
    double Fib = 1;
    
    if ( n <= 1 )
        Fib = 1;
    
    else
    {
        f[0] = 1;
        f[1] = 1;
        f[2] = 2;
        f[3] = 2;
        f[4] = 3;
        f[5] = 3;
        f[6] = 4;
        f[7] = 4;
        f[8] = 5;
        f[9] = 5;
        f[10] = 5;
        f[11] = 10;
        f[12] = 10;
        f[13] = 10;
        f[14] = 10;
        f[15] = 15;
        f[16] = 15;
        f[17] = 15;
        f[18] = 15;
        f[19] = 15;
        f[20] = 20;
        f[21] = 20;
        f[22] = 20;
        f[23] = 20;
        f[24] = 20;
        f[25] = 20;
        f[26] = 30;
        f[27] = 30;
        f[28] = 30;
        f[29] = 30;
        f[30] = 30;

        /*
        for ( j = 4; j <= n; j++ )
        {
            f[j] = f[j-1] + f[j-2];
        }
        */
               
        Fib = f[n];
    }
    return ( Fib );
}

void enterTrade()
{
   double maDaily = iMA(Symbol(),PERIOD_D1,maPeriodDaily,0,MODE_SMA,PRICE_CLOSE,1);
   double MA1 = iMA(Symbol(),NULL,maPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   double RSI1 = iRSI(Symbol(),NULL,rsiPeriod,PRICE_CLOSE,1);
   double RSI2 = iRSI(Symbol(),NULL,rsiPeriod,PRICE_CLOSE,2);
   double C1 = iClose(Symbol(),NULL,1);
   
   double posSize = lotSize;//*(AccountBalance()/multi);
   
   if( C1 > maDaily && C1 > MA1 && RSI1 <= rsiEntry )
   {
      EnterLong(Symbol(),posSize,Ask,maxSlippage,0,0.2,magicNumber,"");
      return;
   }
   
   if( C1 < maDaily && C1< MA1 && RSI1 >= 100-rsiEntry )
   {
      EnterShort(Symbol(),posSize,Bid,maxSlippage,0,0,magicNumber,"");
      return;
   }   
}

void tradeManagerBuy()
{
   int numOpenPos = CountExpertOrders(Symbol(),ORDER_TYPE_BUY,magicNumber);   
   double averageEntryPrice = AverageEntryPrice(Symbol(),ORDER_TYPE_BUY,magicNumber);
   
   double C1 = iClose(Symbol(),NULL,1);
   double maDaily = iMA(Symbol(),PERIOD_D1,maPeriodDaily,0,MODE_SMA,PRICE_CLOSE,1);
     
   // Adjust TP Value
   if( numOpenPos < nPosBreakEven )
   {   
      ApplyTakeProfitMultiFixed(Symbol(),averageEntryPrice,takeProfitPips*0.0001,magicNumber);
   }
   else
   {
      ApplyTakeProfitMultiFixed(Symbol(),averageEntryPrice,0,magicNumber);
   }
   
   // Check for scaleIn
   double posSize = lotSize;//*(AccountBalance()/multi);
   double scaleIn = ComputeFib( numOpenPos );
   double lowestOpenPrice = OpenPrice( Symbol(), magicNumber );
   
   if( Ask <= lowestOpenPrice - gridSpacing * 0.0001 && numOpenPos < nPosMax )
   {
      EnterLong(Symbol(),posSize*scaleIn,Ask,maxSlippage,0,0,magicNumber,"");
      return;
   }  
}

void tradeManagerSell()
{
   int numOpenPos = CountExpertOrders(Symbol(),ORDER_TYPE_SELL,magicNumber);   
   double averageEntryPrice = AverageEntryPrice(Symbol(),ORDER_TYPE_SELL,magicNumber);
   
   double C1 = iClose(Symbol(),NULL,1);
   double maDaily = iMA(Symbol(),PERIOD_D1,maPeriodDaily,0,MODE_SMA,PRICE_CLOSE,1);
      
   // Adjust TP Value
   if( numOpenPos < nPosBreakEven )
   {   
      ApplyTakeProfitMultiFixed(Symbol(),averageEntryPrice,takeProfitPips*0.0001,magicNumber);
   }
   else
   {
      ApplyTakeProfitMultiFixed(Symbol(),averageEntryPrice,0,magicNumber);
   }
   
   // Check for scaleIn
   
   double scaleIn = ComputeFib( numOpenPos );
   double posSize = lotSize;//*(AccountBalance()/multi);
   double lastOpenPrice = OpenPrice( Symbol(), magicNumber );
   
   if( Bid >= lastOpenPrice + gridSpacing * 0.0001 && numOpenPos < nPosMax )
   {
      EnterShort(Symbol(),posSize*scaleIn,Bid,maxSlippage,0,0,magicNumber,"");
      return;
   }  
}

double AverageEntryPrice( string symbol, int nOrderType, int nMagic )
{
    double ticksize = SymbolInfoDouble( symbol, SYMBOL_TRADE_TICK_SIZE );
    int digits = (int)MarketInfo( symbol, MODE_DIGITS );
    
    double sumLots = 0;
    double sumLotsPrice = 0;
    double averagePrice = 0;

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;

        if( OrderType() == nOrderType && OrderMagicNumber() == nMagic && OrderSymbol() == symbol )
        {
            sumLots += OrderLots();
            sumLotsPrice += OrderLots() * OrderOpenPrice();
        }
    }
    
    if( sumLots == 0 )
    {
      return(0);
    }
    
    averagePrice = sumLotsPrice / sumLots;
    
    return( averagePrice);
}

void ApplyTakeProfitMulti( string symbol,double averagePrice, double TakeProfitPct, int nMagic )
{
    double takeprofit = 0;
    double ticksize = SymbolInfoDouble( symbol, SYMBOL_TRADE_TICK_SIZE );
    int digits = (int)MarketInfo( symbol, MODE_DIGITS );

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
        if( OrderMagicNumber() != nMagic ) continue;
        {
            if( OrderSymbol() == symbol )
            {
                if( OrderType() == OP_BUY )
                {
                    takeprofit = NormPrice( averagePrice * ( 1 + TakeProfitPct * 0.01), ticksize, digits );
                }

                if( OrderType() == OP_SELL )
                {
                    takeprofit = NormPrice( averagePrice * ( 1 + TakeProfitPct * 0.01), ticksize, digits );
                }
            }

            if( OrderTakeProfit() != takeprofit && takeprofit != 0 && OrderSymbol() == symbol )
            {
                if( !OrderModify( OrderTicket(), OrderOpenPrice(), OrderStopLoss(), takeprofit, 0 ) )
                    Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError(), OrderTakeProfit(), takeprofit );
            }
        }
    }
}

void ApplyTakeProfitMultiFixed( string symbol,double averagePrice, double TakeProfit, int nMagic )
{
    double takeprofit = 0;
    double ticksize = SymbolInfoDouble( symbol, SYMBOL_TRADE_TICK_SIZE );
    int digits = (int)MarketInfo( symbol, MODE_DIGITS );

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
        if( OrderMagicNumber() != nMagic ) continue;
        {
            if( OrderSymbol() == symbol )
            {
                if( OrderType() == OP_BUY )
                {
                    takeprofit = MathRound( averagePrice * ( 1 + ( TakeProfit ) ) / ticksize ) * ticksize;
                }

                if( OrderType() == OP_SELL )
                {
                    takeprofit = MathRound( averagePrice * ( 1 - ( TakeProfit ) ) / ticksize ) * ticksize;
                }
            }

            if( OrderTakeProfit() != takeprofit && takeprofit != 0 && OrderSymbol() == symbol )
            {
                if( !OrderModify( OrderTicket(), OrderOpenPrice(), OrderStopLoss(), takeprofit, 0 ) )
                    Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
            }
        }
    }
}