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
#include <myFunctions.mqh>
MqlTick  m_tick;               // structure of tick;

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+
//--- External Inputs
extern datetime comissionDate = D'2018.01.01';      // YYYYMMDD  
extern int magicNumber = 78452;

extern double firstTradeValue = 10000;
extern double minSpacingPct = 0.1;

extern int maPeriodLong = 200;
extern int rsiPeriodLong = 2;
extern int rsiEntryLong = 25;
extern int rsiExitLong = 70;

extern string SHORT_PARAMETERS = "";

extern int maPeriodShort = 200;
extern int rsiPeriodShort = 2;
extern int rsiEntryShort = 75;
extern int rsiExitShort = 30;

int maxNumPos = 4;
int maxSlippage = 30;

//--- Global Variables
int flag = 0;

int numOpenShort = 0;
int numOpenLong = 0;

double C0;
double MA0;
double RSI0; 
double RSI1;

double sysProfit = 0;

double lastLongPrice = 0;
double lastShortPrice = 0;

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
   /*
   if( MarketClosingWindow(Symbol(),TimeCurrent(),5) && flag == 0 )
   {        
      flag = 1;
      Executor();
   }
   
   if( NewBar() )
   {
      flag = 0;
      sysProfit = SystemProfit(magicNumber, comissionDate);
      Comment( "\n", "SystemProfit = $", DoubleToString(sysProfit,2),
               "\n", "NumOpenLong = ", IntegerToString(numOpenLong),
               "\n", "NumOpenLong = ", IntegerToString(numOpenShort)
             );
      
   }
   */
   
   if(NewBar())
   {
      sysProfit = SystemProfit(magicNumber, comissionDate);
      Comment( "\n", "SystemProfit = $", DoubleToString(sysProfit,2),
               "\n", "NumOpenLong = ", IntegerToString(numOpenLong),
               "\n", "NumOpenLong = ", IntegerToString(numOpenShort)
             );
      Executor();
   }
}
//+------------------------------------------------------------------+


void Executor()
{
   //-- Common Variables
   C0 = iClose(Symbol(),NULL,1);
   
   //-- Long Position Code   
   numOpenLong = CountExpertOrders(Symbol(),ORDER_TYPE_BUY,magicNumber);
   MA0 = iMA(Symbol(),NULL,maPeriodLong,0,MODE_SMA,PRICE_CLOSE,1);
   RSI0 = iRSI(Symbol(),NULL,rsiPeriodLong,PRICE_CLOSE,1);
   RSI1 = iRSI(Symbol(),NULL,rsiPeriodLong,PRICE_CLOSE,2);
   
   if( numOpenLong == 0 )
   {
      enterLongTrade();
   }   
   
   if( numOpenLong > 0 )
   {   
      tradeManagerLong();
   }
   
   //-- Short Positon Code
   numOpenShort = CountExpertOrders(Symbol(),ORDER_TYPE_SELL,magicNumber);   
   MA0 = iMA(Symbol(),NULL,maPeriodShort,0,MODE_SMA,PRICE_CLOSE,1);
   RSI0 = iRSI(Symbol(),NULL,rsiPeriodShort,PRICE_CLOSE,1);
   RSI1 = iRSI(Symbol(),NULL,rsiPeriodShort,PRICE_CLOSE,2);
   
   if( numOpenShort == 0 )
   {
      enterShortTrade();
   } 
 
   if( numOpenShort > 0 )
   {
      tradeManagerShort();
   }      
   
}

void enterLongTrade()
{  
   if( C0 > MA0 && RSI0 <= rsiEntryLong && RSI1 <= rsiEntryLong )
   {      
      EnterLong(Symbol(),PositionSize(Symbol(),firstTradeValue,false),Ask,maxSlippage,0,0,magicNumber,"");
      lastLongPrice = C0;
   }
}

void enterShortTrade()
{
   if( C0 < MA0 && RSI0 >= (rsiEntryShort) && RSI1>= (rsiEntryShort) )
   {
      EnterShort(Symbol(),PositionSize(Symbol(),firstTradeValue,false),Bid,maxSlippage,0,0,magicNumber,"");
      lastShortPrice = C0;
   } 
}

void tradeManagerLong()
{ 
   // Check for exit
   if( RSI0 > rsiExitLong )
   {
      ExitLong(Symbol(),Bid,maxSlippage,magicNumber,Black);
      lastLongPrice = 0;
      return;
   }
      
   // Check for scaleIn
   if( C0 < MA0) return;
    
   double tradeValue = firstTradeValue * ComputeScale( numOpenLong );
   double posSize = PositionSize(Symbol(),tradeValue,false);
   double lowestOpenPrice = LowestOpenPrice( Symbol(),ORDER_TYPE_BUY,magicNumber );
      
   if( C0 <= lastLongPrice && numOpenLong < maxNumPos )
   {
      EnterLong(Symbol(),posSize,Ask,maxSlippage,0,0,magicNumber,"");
      lastLongPrice = C0;
      return;
   }  
}

void tradeManagerShort()
{ 
   
   // Check for exit
   if( RSI0 < rsiExitShort )
   {
      ExitShort(Symbol(),Ask,maxSlippage,magicNumber);
      lastShortPrice = 0;
      return;
   }
      
   // Check for scaleIn
   if( C0 > MA0 ) return;
   
   double tradeValue = firstTradeValue * ComputeScale( numOpenShort );
   double posSize = PositionSize(Symbol(),tradeValue,false);
   double highestOpenPrice = OpenPrice(Symbol(),magicNumber);
   
   Comment(highestOpenPrice);
   
   if( C0 >= lastShortPrice && numOpenShort < maxNumPos )
   {
      EnterShort(Symbol(),posSize,Bid,maxSlippage,0,0,magicNumber,"");
      lastShortPrice = C0;
      return;
   }  
}

double ComputeScale( int n )
{
   double f[10];
   double Fib = 0;
   
   f[0] = 1;
   f[1] = 2;
   f[2] = 3;
   f[3] = 4;              
   
   Fib = f[n];
   
   return ( Fib );
}

//------------------------------------------------------------------------------------------------//

double AverageEntryPrice( string symbol, int nOrderType, int nMagic )
{
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
                    takeprofit = MathRound( averagePrice * ( 1 + ( TakeProfitPct * 0.01 ) ) / ticksize ) * ticksize;
                }

                if( OrderType() == OP_SELL )
                {
                    takeprofit = MathRound( averagePrice * ( 1 - ( TakeProfitPct * 0.01 ) ) / ticksize ) * ticksize;
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

////////////////////////////////////////////

double SystemProfit( int nMagic, datetime startDate )
{
    double TotalProfit = 0;

    for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
        if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
        if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
        
        TotalProfit += ( OrderProfit() + OrderCommission() + OrderSwap() );
    }

    return( TotalProfit );
}

double StartBalance( datetime startDate )
{
    double TotalProfit = 0;

    for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
        if( OrderSymbol() == "" ) continue;
        if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
        
        TotalProfit += ( OrderProfit() + OrderCommission() + OrderSwap() );
    }

    return( AccountBalance() - TotalProfit );
}

double SystemProfitPct( int nMagic, datetime startDate )
{
    double TotalProfit = 0;

    for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
        if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
        if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
        
        TotalProfit += ( OrderProfit() + OrderCommission() + OrderSwap() );
    }

    return( 100 * ( TotalProfit / StartBalance(startDate) ) );
}

double SystemCAR( int nMagic, datetime startDate )
{
   double TPY = SystemTPY( nMagic, startDate );
   double TotalTrades = TotalTradesHistory( nMagic, startDate );
   double TWR = SystemProfitPct( nMagic, startDate )/100 + 1;

   double CAR = 100 * ( exp( log(TWR) / (TotalTrades/TPY) ) - 1 );
   
   return(CAR);
}

double SystemAccuracy( int nMagic, datetime startDate )
{
    double Wins = 0,
           nTrades = 0;

    for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
        if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
        if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;

        if( NetDelta() >= 0 )
        {
            Wins += 1;
        }

        nTrades += 1;
    }

    if( nTrades == 0 )
        return( 0 );
    else
        return( Wins / nTrades * 100 );
}

double SystemPayoffRatio( int nMagic, datetime startDate )
{
    double NumWins = 0,
           NumLoss = 0,
           AvgWin = 0,
           AvgLoss = 0,
           TotalWins = 0,
           TotalLoss = 0,
           Ratio = 0,
           Accuracy = 0,
           delta = 0;

    for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
        if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
        if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
        
        delta = NetDelta();

        if( delta >= 0 )
        {
            NumWins += 1;
            TotalWins += delta;
        }
        else
        {
            NumLoss += 1;
            TotalLoss += -delta;
        }
    }

    if( NumLoss == 0 || NumWins == 0 ) return( 0 );

    AvgWin = TotalWins / NumWins;
    AvgLoss = TotalLoss / NumLoss;
    Accuracy = NumWins / ( NumWins + NumLoss );
    Ratio = AvgWin / AvgLoss;
    return( Ratio );
}

double SystemAverageTrade( int nMagic, datetime startDate )
{
    double nTrades = 0,
           totalProfit = 0;

    for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
        if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
        if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;

        nTrades += 1;
        totalProfit += NetDelta();
    }

    if( nTrades == 0 || totalProfit == 0 ) return( 0 );

    return( totalProfit / nTrades );
}

double SystemTPY( int nMagic, datetime startDate )
{
    datetime   firstTradeDate = TimeCurrent();
    
    double     nTrades = 0,
               years = 0,
               days = 0,
               timeDiff;

    for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
        if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
        if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
        
        
        if( OrderCloseTime() < firstTradeDate ) 
        {
            firstTradeDate = OrderCloseTime();
        }
        
        nTrades += 1;

    }
    
    years = TimeYear(TimeCurrent()) - TimeYear(firstTradeDate);
    days = TimeDayOfYear(TimeCurrent()) - TimeDayOfYear(firstTradeDate);
    
    timeDiff = 365*years + days;
    
    if( nTrades == 0 || timeDiff == 0 ) return( 0 );
    
    double TPY = nTrades / timeDiff * 365;

    return( TPY );
}

double SystemExpectancy( int nMagic, datetime startDate )
{
    double NumWins = 0,
           NumLoss = 0,
           AvgWin = 0,
           AvgLoss = 0,
           TotalWins = 0,
           TotalLoss = 0,
           Ratio = 0,
           Accuracy = 0,
           delta = 0;

    for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
        if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
        if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
         
        delta = NetDelta();
         
        if( delta >= 0 )
        {
            NumWins += 1;
            TotalWins += delta;
        }
        else
        {
            NumLoss += 1;
            TotalLoss += -delta;
        }
    }

    if( NumLoss == 0 || NumWins == 0 ) return( 0 );

    AvgWin = TotalWins / NumWins;
    AvgLoss = TotalLoss / NumLoss;
    Accuracy = NumWins / ( NumWins + NumLoss );
    Ratio = AvgWin / AvgLoss;
    return( Accuracy * Ratio + Accuracy - 1 );
}

double SystemStDev( int nMagic, datetime startDate )
{
   double totalTrades = 0,
          mean = 0,
          sumX2 = 0,
          delta = 0,
          stdev = 0;
          
   mean = SystemAverageTrade( nMagic, startDate );       
          
   for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
   {
      if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
      if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
      if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
      
      
      delta = NetDelta();
      sumX2 += ( ( delta - mean ) * ( delta - mean ) ); 
      totalTrades += 1; 
   }
   
   if(totalTrades == 0)
   {
      return(0);       
   }       
   stdev = sqrt(sumX2 / totalTrades);
   return(stdev);
}

double E50( int nMagic, datetime startDate )
{
   double E50 = 10000 * SystemAverageTrade( nMagic, startDate ) * SystemTPY( nMagic, startDate );
   return(E50);
}

double MDD( int nMagic, datetime startDate)
{
   
   double   trade = 0,
            equity = 0,
            maxEquity = 0,
            drawDown = 0,
            MaxDrawDown = 0;
   
   for(  int i = 1 ; i <= OrdersHistoryTotal() ; i++  )
   {
      if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
      if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
      if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
      
      
      trade = 10000*NetDelta();
      equity += trade;
      
      if(equity > maxEquity)
      {
         maxEquity = equity;
      }
      
      drawDown = maxEquity - equity;
      
      if( MaxDrawDown < drawDown )
      {
         MaxDrawDown = drawDown;
      }      
   } 
   
   return(MaxDrawDown);
}


double DD( int nMagic, datetime startDate)
{
   
   double   trade = 0,
            equity = 0,
            maxEquity = 0,
            drawDown = 0,
            MaxDrawDown = 0;
   
   for( int i = 1 ; i <= OrdersHistoryTotal() ; i++ )
   {
      if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
      if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
      if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
      
      
      trade = 10000*NetDelta();
      equity += trade;
      
      if(equity > maxEquity)
      {
         maxEquity = equity;
      }
      
      drawDown = maxEquity - equity;
         
   } 
   
   return(drawDown);
}

double CAR50( int nMagic, datetime startDate, double FF = 0.1)
{

   double TPY = SystemTPY( nMagic, startDate );
   double mean = SystemAverageTrade( nMagic, startDate);

   double trade = ( 1 + FF * mean );
   double car50 = ( MathPow( trade, TPY) - 1 ) * 100;
   
   return( car50 );

}