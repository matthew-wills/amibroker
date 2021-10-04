//+------------------------------------------------------------------+
//|                                                  myFunctions.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

//+------------------------------------------------------------------+
//| User Defined Functions                                           |
//+------------------------------------------------------------------+

// This function returns true when a new bar is placed on the chart
bool NewBar()
{
   static datetime lastBarOpenTime;
   datetime thisBarOpenTime = Time[0];
   if( thisBarOpenTime != lastBarOpenTime )
   {
      lastBarOpenTime = thisBarOpenTime;
      return (true);
   }
   else
      return (false);
}

// This function returns true when a new Minute is Detected

bool NewMinute()
{
    static datetime LastMinute;
    datetime ThisMinute = TimeMinute( TimeGMT() );

    if( ThisMinute != LastMinute )
    {
        LastMinute = ThisMinute;
        return ( true );
    }
    else
        return ( false );
}

bool NewHour()
{
   static datetime LastHour;
   datetime ThisHour = TimeHour(TimeGMT());
   if( ThisHour != LastHour )
   {
      LastHour = ThisHour;
      return (true);
   }
   else
      return (false);
}

bool NewDay()
{
   static datetime LastDay;
   datetime ThisDay = TimeDay(TimeGMT());
   if( ThisDay != LastDay )
   {
      LastDay = ThisDay;
      return (true);
   }
   else
      return (false);
}

int MarketOpenTime( string symbol )
{
    for( int i = 1; i <= 300; i++ )
    {
        if( TimeDay( iTime( symbol, PERIOD_M5, i ) ) != TimeDay( iTime( symbol, PERIOD_M5, i - 1 ) ) )
        {
            int H = TimeHour( iTime( symbol, PERIOD_M5, i - 1 ) );
            int M = TimeMinute( iTime( symbol, PERIOD_M5, i - 1 ) );
            int TimeCurrentBar = H * 100 + M;

            return( TimeCurrentBar );
        }
    }

    return( 0 );
}

int MarketCloseTime( string symbol )
{
    for( int i = 1; i <= 300; i++ )
    {
        if( TimeDay( iTime( symbol, PERIOD_M5, i ) ) != TimeDay( iTime( symbol, PERIOD_M5, i - 1 ) ) )
        {
            int H = TimeHour( iTime( symbol, PERIOD_M5, i ) );
            int M = TimeMinute( iTime( symbol, PERIOD_M5, i ) );
            int TimeCurrentBar = H * 100 + M;

            return( TimeCurrentBar );
        }
    }

    return( 0 );
}

bool MarketClosingWindow( string symbol, int TimeLimit )
{
    int TC = 100 * TimeHour( TimeCurrent() ) + TimeMinute( TimeCurrent() );

    if( TC >= MarketCloseTime( symbol ) && TC <= MarketCloseTime( symbol ) + TimeLimit )
    {
        return( true );
    }
    else
    {
        return( false );
    }
}

// This Function returns True when the Current Hour is equal to or between the Start and Finish times
bool TimeFilter(int Start,int Finish)
{
   bool response = false;
   int CurrentTime = TimeHour(TimeGMT());
   if( Start == 0 ) Start = 24; 
   if( Finish == 0 ) Finish = 24; 
   if( CurrentTime == 0 ) CurrentTime = 24;

   if ( ((Start < Finish) && ( (CurrentTime < Start) || (CurrentTime > Finish))) || ((Start > Finish) && ((CurrentTime < Start) && (CurrentTime > Finish))) )
   {   
      response = false;
      return(response);
   }
   else
   {
      response = true;
      return(response);
   }
}

bool IndexFilter( string symbol, int IndexPeriod, ENUM_TIMEFRAMES timeframe )
{
   double Index = iClose(symbol,timeframe,1);
   double IndexMA = iMA(symbol,timeframe,IndexPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   if( Index >= IndexMA )
      return(true);
   else
      return(false);
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

//--- Is there a disruption in the Data
bool StockSplitCheck( string symbol, int NumberOfBars )
{
    for( int i = 0; i < NumberOfBars; i++ )
    {
        double close0 = iClose( symbol, NULL, i );
        double open0 = iOpen( symbol, NULL, i );
        double open1 = iOpen( symbol, NULL, i + 1 );

        if( close0 == 0 || open0 == 0 || open1 == 0 )
            return( false );

        double R = close0 / open1;
        double R2 = open0 / open1;

        if( R > 1.49 || R < 0.67 || R2 > 1.49 || R2 < 0.67 )
            return( false );
    }

    return( true );
}

bool CurrentDailyCandle( string symbol )
{
    int DayOfMinute1 = TimeDay( iTime( symbol, PERIOD_M1, 1 ) );
    int DayOfDay0 = TimeDay( iTime( symbol, PERIOD_D1, 0 ) );

    if( DayOfMinute1 == DayOfDay0 )
        return( true );
    else
        return( false );
}

bool ValidDateSequence( string symbol )
{
    int Day_0 = TimeDayOfYear( iTime( symbol, PERIOD_D1, 0 ) );
    int Day_1 = TimeDayOfYear( iTime( symbol, PERIOD_D1, 1 ) );
    int Shift = ( Day_0 - Day_1 );
    int DayofWeek = TimeDayOfWeek( iTime( symbol, PERIOD_D1, 0 ) );

    if( DayofWeek != 1 && Shift == 1 )
    {
        return( true );
    }

    if( DayofWeek == 1 && Shift == 3 )
    {
        return( true );
    }
    else
    {
        return( false );
    }
}

//--- Has the candle actually formed
bool ValidCandleCheck(string symbol, ENUM_TIMEFRAMES timeframe)
{
   bool response = false;
   double low = iLow(symbol,timeframe,0);
   double high = iHigh(symbol,timeframe,0);   
   if( MathAbs( high - low ) == 0 || low == 0 || high == 0 )
   {
      response = false;
      return(response);
   }
   else
   {
      response = true;
      return(response);
   }   
}

//--- Returns Current Profit from all Trades on the Symbol
double CurrentProfit(string symbol, int nMagic)
{
   double Profit = 0;
   for ( int i = OrdersTotal()-1 ; i>=0 ; i-- )
   {
      if( !OrderSelect(i,SELECT_BY_POS) ) continue;
      if( OrderSymbol() == symbol && OrderMagicNumber() == nMagic )
      {
         Profit += OrderProfit();
      }   
   }
   return(Profit);
}

// This function returns the positon of the HHV of the close within the Array LookBack period
bool HHV_Filter( string symbol, ENUM_TIMEFRAMES timeframe, int HHV_LB, int ARRAY_LB )
{
    bool response = false;
    int HHV_C = iHighest( symbol, timeframe, MODE_CLOSE, ARRAY_LB, 1 );

    if( HHV_C == -1 || HHV_C > HHV_LB )
    {
        response = false;
        return( response );
    }
    else
    {
        response = true;
        return( response );
    }
}

// This function returns the boolean pass fail of an ATR Filter where if ATR1 >= ATR2 the function is true, else false
bool ATR_Filter( string symbol, ENUM_TIMEFRAMES timeframe, int P1, int P2 )
{
   double ATR1 = iATR( symbol,timeframe,P1,1 );
   double ATR2 = iATR( symbol,timeframe,P2,1 );
   
   if( ATR1 == 0 || ATR2 == 0 )
   {
      return(false);
   }
   
   if( ATR1 >= ATR2 )
   {
      return(true);
   }
   else
   {
      return(false);
   }   
}

// This function counts the number of different symbols that are open within a system
int CountOpenSymbols( int nOrderType, int nMagic )
{
    int TotalSymbols = 0;
    string strSymbol;

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;

        if( i == 0 ) // There is only 1 Open Order ...
        {
            TotalSymbols += 1;
            break;
        }

        if( OrderMagicNumber() == nMagic && OrderType() == nOrderType )
        {
            strSymbol = OrderSymbol();
            {
                for( int j = i - 1 ; j >= 0 ; j-- )
                {
                    if( !OrderSelect( j, SELECT_BY_POS ) ) continue;

                    if( OrderMagicNumber() == nMagic && OrderType() == nOrderType )
                        if( OrderSymbol() == strSymbol )
                            break;

                    if( j == 0 )
                        TotalSymbols++;
                }
            }
        }
    }

    return( TotalSymbols );
}

//--- Returns the Lowest Open Price on the Symbol
double LowestOpenPrice(string symbol, int nOrderType, int nMagic)
{
   double LowestPrice = 0;
   for( int i=OrdersTotal()-1 ; i>=0 ; i-- )
   {
      if( !OrderSelect(i,SELECT_BY_POS) ) continue;
      {
         if( OrderSymbol() == symbol && OrderType() == nOrderType && OrderMagicNumber() == nMagic )
         {
            if ( LowestPrice == 0 )
            {
               LowestPrice = OrderOpenPrice();
            }
            else
            {
               if( OrderOpenPrice() < LowestPrice )
               {
                  LowestPrice = OrderOpenPrice();
               }
            }
         }   
      }   
   }
   return(LowestPrice);
}

//--- Returns the Highest Open Price on the Symbol
double HighestOpenPrice(string symbol, int nOrderType, int nMagic)
{
   static double HighestPrice = 0;
   for( int i=OrdersTotal()-1 ; i>=0 ; i-- )
   {
      if( !OrderSelect(i,SELECT_BY_POS)) continue;
      {
         if( OrderSymbol() == symbol && OrderType() == nOrderType && OrderMagicNumber() == nMagic )
         {
               if( OrderOpenPrice() > HighestPrice )
               {
                  HighestPrice = OrderOpenPrice();
               }
            
         }   
      }   
   }
   return(HighestPrice);
}

// This function returns the number of open orders matching the symbol and system magic number
int CountExpertOrders( string symbol, int nOrderType, int nMagic )
{
    int nOrderCount = 0;

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;

        if( OrderType() == nOrderType && OrderMagicNumber() == nMagic && OrderSymbol() == symbol )
        {
            nOrderCount++;
        }
    }

    return( nOrderCount );
}

// This function returns the number of open orders matching system magic number
int CountSystemOrders( int nOrderType, int nMagic )
{
    int nOrderCount = 0;

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;

        if( OrderType() == nOrderType && OrderMagicNumber() == nMagic )
        {
            nOrderCount++;
        }
    }

    return( nOrderCount );
}

// This function returns the total number of open orders.
int CountGlobalOrders()
{
    int nOrderCount = 0;

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;

        if( OrderType() == OP_BUY || OrderType() == OP_SELL )
        {
            nOrderCount++;
        }
    }

    return( nOrderCount );
}

// This function returns the number of Bars Since the selected order was entered
int BarsSinceEntry( string symbol, ENUM_TIMEFRAMES timeframe, int nMagic )
{
    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;

        if( OrderSymbol() == symbol && OrderMagicNumber() == nMagic )
        {
            return( iBarShift( symbol, timeframe, OrderOpenTime() ) );
        }
    }

    return( 0 );
}

// This function returns the OrderType of the last placed Order Plus 1 ie ... Buy =1 Sell=2 Blimit=3 Slimit=4 Bstop=5 Sstop=6
int LastOpenTrade(string symbol, int nMagic)
{
   int last_trade = 0;
   if(OrdersTotal() != 0)
   {
      if(OrderSelect(last_trade-1,SELECT_BY_POS,MODE_TRADES)==true)
      {   
        if(OrderSymbol() == symbol && OrderMagicNumber() == nMagic)
        {
          return(OrderType()+1);
        }
      }
   }
   return(EMPTY_VALUE);
}

// Function returns the LLV of the Close given a start bar and a lookback
double LowestLowClose(string symbol, ENUM_TIMEFRAMES timeframe, int LookBack, int Start)
{
   int shift = iLowest(symbol,timeframe,MODE_CLOSE,LookBack,Start);
   double LLV = iClose(symbol,timeframe,shift);
   return(LLV);
}

//Function returns true for a cross up and false for a cross down and EMPTY VALUE for default
int Cross(double fast1, double slow1, double fast2, double slow2)
{
   if(fast1>slow1 && fast2<=slow2)
   {
      return(1);
   }
   else if(fast1<slow1 && fast2>=slow2)
   {   
      return(-1);
   }
   else
   {
      return(0);
   }   
}

//Function returns true for a cross up and false for a cross down and EMPTY VALUE for default
bool CrossLevelUp(double fast1, double fast2, double level)
{
   if(fast1 > level && fast2 <= level)
      return(true);
   else
      return(false);
}

//Function returns true for a cross up and false for a cross down and EMPTY VALUE for default
bool CrossLevelDown(double fast1, double fast2, double level)
{
   if(fast1 < level && fast2 >= level)
      return(true);
   else
      return(false);
}

//+------------------------------------------------------------------+
//| System History Reports to Excel                        |
//+------------------------------------------------------------------+

void MATLAB2015( string eaName = "", int nMagic = 0, int startDate = 0 )
{
   double count = 0;
   double delta = 0;
   double posValue = 0;
   double brokerFees = 0;
   double netDelta = 0;
   double netProfit = 0;
   double fixedProfit = 0;
   string fileName;

   if( nMagic != 0)
   {
      fileName = StringConcatenate(AccountCompany(),"\\MATLAB_2015\\",eaName,"_",nMagic,"\\History.csv");
   }
   else
   {
      fileName = StringConcatenate(AccountCompany(),"\\MATLAB_2015\\","CompleteHistory","\\History.csv");
   }
   
   int fileHandle = FileOpen(fileName,FILE_CSV|FILE_WRITE,',');

   FileWrite(fileHandle,"Num","eaName","Symbol","exDate","Shares","posValue","Price","exPrice","brokerFees","Delta","netProfit","fixedProfit");
   for( int i = 0; i <= OrdersHistoryTotal() - 1; i++ )
   {     
      if ( !OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) ) continue;
      if ( OrderSymbol() == "" || OrderOpenPrice() == 0 ) continue;
      if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
      if ( OrderType() != OP_BUY && OrderType() != OP_SELL ) continue;
      if ( nMagic != 0 && OrderMagicNumber() != nMagic ) continue;
      if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
         
      count += 1;
      
      delta = ( OrderClosePrice() - OrderOpenPrice() ) / OrderOpenPrice();
        
      brokerFees = ( OrderCommission() + OrderSwap() );
     
      if(delta == 0)
      {
         delta = 0.00000000001;
      }       
      posValue = OrderProfit() / delta;
      
      netProfit = ( OrderProfit() + OrderCommission() + OrderSwap() );
      
      if( posValue == 0)
      {
         netDelta = 0;
      }
      else
      {
         netDelta = netProfit / posValue ;
      }
      
      fixedProfit = 10000 * netDelta ;
     
      FileWrite(fileHandle,count,OrderComment(),OrderSymbol(),TimeToStr(OrderCloseTime(),TIME_DATE),OrderLots(),posValue,OrderOpenPrice(),OrderClosePrice(),brokerFees,netDelta,netProfit,fixedProfit);
   }
   FileClose(fileHandle);
}

void BrokersStatement()
{
   double delta = 0;
   double posValue = 0;
   double netDelta = 0;
   double brokerFees = 0;
   double tradeValue = 0;
   double netProfit = 0;
   double fixedProfit = 0;

   string fileName = StringConcatenate(AccountCompany(),"\\BrokersStatement.csv");
   int fileHandle = FileOpen(fileName,FILE_CSV|FILE_WRITE,',');

   FileWrite(fileHandle, "eaName","magicNumber","Symol","Date","Ex.Date","Shares","Price","Ex.Price","GrossProfit","Commission","Swap","netProfit");
   
   for( int i = 0; i <= OrdersHistoryTotal() - 1; i++ )
   {     
      if ( !OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) ) continue;
        
      brokerFees = ( OrderCommission() + OrderSwap() );
      
      netProfit = ( OrderProfit() + OrderCommission() + OrderSwap() );
     
      FileWrite( fileHandle, OrderComment(), OrderMagicNumber(), OrderSymbol(), TimeToStr(OrderOpenTime(),TIME_DATE), TimeToStr(OrderCloseTime(),TIME_DATE), OrderLots(), OrderOpenPrice(), OrderClosePrice(), OrderProfit(), OrderCommission(), OrderSwap(), netProfit );
   }
   FileClose( fileHandle );
}

//+------------------------------------------------------------------+
//| Export Brokers Data to ASCII Format                              |
//+------------------------------------------------------------------+

void Write_ASCII(string symbol, string Folder, ENUM_TIMEFRAMES timeframe, int startDate = 0) 
{
   int handle = FileOpen("ASCII_DataExport\\" + Folder +"\\" + IntegerToString(timeframe) + "\\" + symbol + ".csv", FILE_CSV|FILE_WRITE, ',');

   if ( handle > 0 ) 
   {
      FileWrite(handle,"DATE","TIME","OPEN","HIGH","LOW","CLOSE","VOLUME");
      for(int Bar = iBars(symbol,timeframe)-1; Bar >= 0; Bar --)
      {
         if ( DateCheck(startDate,iTime(symbol,timeframe,Bar)) == false ) continue;
         FileWrite( handle, TimeToStr(iTime(symbol,timeframe,Bar),TIME_DATE), TimeToStr(iTime(symbol,timeframe,Bar),TIME_SECONDS), iOpen(symbol,timeframe,Bar), iHigh(symbol,timeframe,Bar), iLow(symbol,timeframe,Bar), iClose(symbol,timeframe,Bar),iVolume(symbol,timeframe,Bar) );
      }
      FileClose( handle );
   }
}

//+------------------------------------------------------------------+
//| Basic Trade Functions with Error Analysis                        |
//+------------------------------------------------------------------+

// This function returns true if the EA closed a trade on this bar
bool ExitBar( string symbol, ENUM_TIMEFRAMES timeframe, int nMagic )
{
    for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;

        if( OrderSymbol() == symbol && OrderMagicNumber() == nMagic )
        {
            if( iBarShift( symbol, timeframe, OrderCloseTime() ) == 0 )
            {
                return( true );
            }
        }
    }

    return( false );
}  
   
double SymbolToUSD(string symbol)
{
    string BASE = SymbolInfoString( symbol, SYMBOL_CURRENCY_BASE );
    double BASEUSD = iClose( BASE + "USD", PERIOD_D1, 0 );
    double USDBASE = iClose( "USD" + BASE, PERIOD_D1, 0 );
    double M = 0;

    if( BASE == "USD" )
    {
        return( 1 );
    }

    if( BASE == "GBP" )
    {
        if( BASEUSD != 0 )
            return( 100 / BASEUSD );
        else
            return( 0 );
    }

    if( BASEUSD != 0 || USDBASE != 0 )
    {
        if( BASEUSD != 0 )
        {
            return( 1 / BASEUSD );
        }

        if( USDBASE != 0 )
        {
            return( USDBASE );
        }
    }

    return( 0 );
}

double USDtoACCT()
{
   string BASE = AccountCurrency();
   
   // Base is either USD, EUR, GBP, AUD 
   
   if(BASE == "USD")
   {
      return(1);
   }
   
   if(BASE == "AUD")
   {
      return(iClose("AUDUSD",PERIOD_D1,0));
   }
   
   if(BASE == "EUR")
   {
      return(iClose("EURUSD",PERIOD_D1,0));
   }
   
   if(BASE == "GBP")
   {
      return(iClose("GBPUSD",PERIOD_D1,0));
   }
   
   return(0);     
}

bool DateCheck(int startDate, datetime objectDate)
{
   int date = TimeYear(objectDate)*10000 + TimeMonth(objectDate)*100 + TimeDay(objectDate);
   
   if( date > startDate)
   {
      return(true);
   }
   else
   {
      return(false);
   }
}
   
double CurrencyConverter(string symbol)
{
   return( SymbolToUSD(symbol) * USDtoACCT() );
}

double MoneyManagement( double MM, double AA )
{
    double Balance = AccountBalance();
    return( AA * MM * Balance );
}

double PositionSize( string symbol, double Amount, double roundLots, double minlot)
{
    double Exchange = 0;
    double Price = iClose( symbol, NULL, 0 );
    Exchange = CurrencyConverter( symbol );

    if( Exchange == 0 || Price == 0 )
    {
        return( 0 );
    }
      
    double nShares = ( Exchange * Amount ) / Price;
    double LotSize = MathRound( nShares / roundLots ) * roundLots;

    if( LotSize < minlot )
    {
        LotSize = minlot;
    }

    return( NormalizeDouble( LotSize, 0 ) );
}

double ShareValue( string symbol )
{
    double Exchange = 0;
    Exchange = CurrencyConverter( symbol );

    if( Exchange == 0 )
    {
        return( 0 );
    }

    return( iClose( symbol, NULL, 0 ) / Exchange );
}


void EnterLong( string symbol, double Lots, double Price, int Slippage, double StopLossPct, double TakeProfitPct, int nMagic, string Label )
{
    static double stoploss, takeprofit, ticksize;
    ticksize = MarketInfo( symbol, MODE_TICKSIZE );
    int digits = (int)MarketInfo( symbol, MODE_DIGITS );

    if( StopLossPct != 0 )
    {
        stoploss = NormalizeDouble( MathCeil( ( ( Price * ( 1 - StopLossPct * 0.01 ) ) / ticksize ) ) * ticksize, digits );
    }

    if( TakeProfitPct != 0 )
    {
        takeprofit = NormalizeDouble( MathCeil( ( ( Price * ( 1 + TakeProfitPct * 0.01 ) ) / ticksize ) ) * ticksize, digits );
    }

    RefreshRates();

    if( !OrderSend( symbol, OP_BUY, Lots, Price, Slippage, stoploss, takeprofit, Label, nMagic, 0, NULL ) )
    {
        ErrorReport( GetLastError() );
    }
}


void ExitLong( string symbol, double Price, int Slippage, int nMagic, color CLR )
{
    for( int i = OrdersTotal() - 1; i >= 0 ; i-- )
    {
        if( ! OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) ) continue;

        if( OrderSymbol() == symbol && OrderType() == OP_BUY && OrderMagicNumber() == nMagic )
        {
            if( ! OrderClose( OrderTicket(), OrderLots(), Price, Slippage, CLR ) )
                Print( "Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
        }
    }
}

void EnterShort(string symbol, double Lots, double Price, int Slippage, double StopLossPct, double TakeProfitPct, int nMagic, string Label)
{
   static double stoploss,takeprofit,ticksize;
   ticksize = MarketInfo(symbol,MODE_TICKSIZE);
   int digits = (int)MarketInfo( symbol, MODE_DIGITS );
   
   if( StopLossPct != 0 ) 
   {
      stoploss = NormalizeDouble(MathCeil(((Price*(1+StopLossPct*0.01))/ticksize))*ticksize,digits);
   }
   
   if( TakeProfitPct != 0 ) 
   {
      takeprofit = NormalizeDouble(MathCeil(((Price*(1-TakeProfitPct*0.01))/ticksize))*ticksize,digits);
   }
   
   RefreshRates();
   
   if(!OrderSend(symbol,OP_SELL,Lots,Price,Slippage,stoploss,takeprofit,Label,nMagic,0,NULL)) 
   {
      ErrorReport(GetLastError());
   }
}

void ExitShort(string symbol, double Price, int Slippage, int nMagic)
{  
   for(int i=OrdersTotal() -1; i>=0 ; i--)
   {
      if( ! OrderSelect(i,SELECT_BY_POS,MODE_TRADES) ) continue;
      if( OrderSymbol() == symbol && OrderType()==OP_SELL && OrderMagicNumber()==nMagic )
      {
         if( !OrderClose(OrderTicket(),OrderLots(),Price,Slippage,NULL))
            Print("Order Close Failed, order number: ",OrderTicket()," Error ", GetLastError());
      }
   }
}

double NormPrice(double price, double ticksize, double digits)
{
   double P1 = MathRound( price / ticksize) * ticksize;
   double P2 = NormalizeDouble(P1, (int)digits);
   return(P2);
}


void ApplyTakeProfit( string symbol, double TakeProfitPct, int nMagic )
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
                    takeprofit = NormPrice( OrderOpenPrice() * ( 1 + TakeProfitPct * 0.01), ticksize, digits );
                }

                if( OrderType() == OP_SELL )
                {
                    takeprofit = NormPrice( OrderOpenPrice() * ( 1 - TakeProfitPct * 0.01), ticksize, digits );
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

void ApplyStopLoss( string symbol, double StopLossPct, int nMagic )
{
    double stoploss = 0;
    double ticksize = SymbolInfoDouble( symbol, SYMBOL_TRADE_TICK_SIZE );
    int digits = (int)MarketInfo( symbol, MODE_DIGITS );

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;

        {
            if( OrderSymbol() == symbol && OrderMagicNumber() == nMagic )
            {
                if( OrderType() == OP_BUY )
                {
                    stoploss = MathRound( OrderOpenPrice() * ( 1 - ( StopLossPct * 0.01 ) ) / ticksize ) * ticksize;
                }

                if( OrderType() == OP_SELL )
                {
                    stoploss = MathRound( OrderOpenPrice() * ( 1 + ( StopLossPct * 0.01 ) ) / ticksize ) * ticksize;
                }
            }

            if( OrderStopLoss() != stoploss && stoploss != 0 && OrderSymbol() == symbol )
            {
                if( !OrderModify( OrderTicket(), OrderOpenPrice(), stoploss, OrderTakeProfit(), 0 ) )
                    Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
            }
        }
    }
}

void ModifyPosition( string symbol, double TakeProfitPct, double StopLossPct, int nMagic )
{
    double stoploss = 0;
    double takeprofit = 0;
    double ticksize = SymbolInfoDouble( symbol, SYMBOL_TRADE_TICK_SIZE );
    int digits = (int)MarketInfo( symbol, MODE_DIGITS );

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
        {
            if( OrderSymbol() == symbol && OrderMagicNumber() == nMagic )
            {
                if( OrderType() == OP_BUY )
                {
                    if( TakeProfitPct != 0 )
                    {
                        takeprofit = MathRound( OrderOpenPrice() * ( 1 + ( TakeProfitPct * 0.01 ) ) / ticksize ) * ticksize;
                    }
                    if( StopLossPct != 0 )
                    {
                        stoploss = MathRound( OrderOpenPrice() * ( 1 - ( StopLossPct * 0.01 ) ) / ticksize ) * ticksize;
                    }
                }

                if( OrderType() == OP_SELL )
                {
                    if( TakeProfitPct != 0 )
                    {
                        takeprofit = MathRound( OrderOpenPrice() * ( 1 - ( TakeProfitPct * 0.01 ) ) / ticksize ) * ticksize;
                    }
                    if( StopLossPct != 0 )
                    {
                        stoploss = MathRound( OrderOpenPrice() * ( 1 + ( StopLossPct * 0.01 ) ) / ticksize ) * ticksize;
                    }
                }
            }

            if( OrderTakeProfit() != takeprofit || OrderStopLoss() != stoploss)
            {
                if( !OrderModify( OrderTicket(), OrderOpenPrice(), stoploss, takeprofit, 0 ) )
                    Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
            }
        }
    }
}

double OpenPrice( string symbol, int nMagic )
{
    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;

        {
            if( OrderSymbol() == symbol && OrderMagicNumber() == nMagic )
            {
                return( OrderOpenPrice() );
            }
        }
    }

    return( 0 );
}

double TakeProfitPrice( string symbol, double TakeProfitPct, int nMagic )
{
    double takeprofit = 0;

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;

        {
            if( OrderSymbol() == symbol && OrderMagicNumber() == nMagic )
            {
                if( OrderType() == OP_BUY )
                {
                    takeprofit = OrderOpenPrice() * ( 1 + ( TakeProfitPct * 0.01 ) );
                }

                if( OrderType() == OP_SELL )
                {
                    takeprofit = OrderOpenPrice() * ( 1 - ( TakeProfitPct * 0.01 ) );
                }
            }
        }
    }

    return( takeprofit );
}

//+------------------------------------------------------------------+
//| System Status Functions                                          |
//+------------------------------------------------------------------+

double NetDelta()
{
   double delta = 0;
   double brokerFees = 0;
   double posValue = 0;
   double netProfit = 0;
   double netDelta = 0;

   delta = ( OrderClosePrice() - OrderOpenPrice() ) / OrderOpenPrice();
     
   brokerFees = ( OrderCommission() + OrderSwap() );
  
   if(delta == 0)
   {
      delta = 0.00000000001;
   }       
   posValue = OrderProfit() / delta;
   
   netProfit = ( OrderProfit() + OrderCommission() + OrderSwap() );
   
   if( posValue == 0)
   {
      netDelta = 0;
   }
   else
   {
      netDelta = netProfit / posValue ;
   }
   
   return(netDelta);
}

double Exposure()
{
    double Exp = 0;

    for( int i = OrdersTotal() - 1; i >= 0; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) ) continue;

        if( CurrencyConverter( OrderSymbol() ) == 0 ) return( 0 );

        Exp += OrderLots() * OrderOpenPrice() / CurrencyConverter( OrderSymbol() );
    }

    return( Exp );
}

double SystemExposure( int nMagic )
{
    double Exp = 0;

    for( int i = OrdersTotal() - 1; i >= 0; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) ) continue;

        if( CurrencyConverter( OrderSymbol() ) == 0 ) return( 0 );

        if( OrderMagicNumber() == nMagic )
        {
            Exp += OrderLots() * OrderOpenPrice() / CurrencyConverter( OrderSymbol() );
        }
    }

    return( Exp );
}

int TotalTradesHistory( int nMagic, int startDate = 0 )
{
    int NumTrades = 0;

    for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
        if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
        if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
 
        NumTrades += 1;
    }

    return( NumTrades );
}

double SystemProfit( int nMagic, int startDate = 0 )
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

double StartBalance( int startDate = 0 )
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

double SystemProfitPct( int nMagic, int startDate = 0 )
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

double SystemCAR( int nMagic, int startDate = 0 )
{
   double TPY = SystemTPY( nMagic, startDate );
   double TotalTrades = TotalTradesHistory( nMagic, startDate );
   double TWR = SystemProfitPct( nMagic, startDate )/100 + 1;

   double CAR = 100 * ( exp( log(TWR) / (TotalTrades/TPY) ) - 1 );
   
   return(CAR);
}

double SystemAccuracy( int nMagic, int startDate = 0 )
{
    double Wins = 0,
           NumTrades = 0;

    for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
        if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
        if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;

        if( NetDelta() >= 0 )
        {
            Wins += 1;
        }

        NumTrades += 1;
    }

    if( NumTrades == 0 )
        return( 0 );
    else
        return( Wins / NumTrades * 100 );
}

double SystemPayoffRatio( int nMagic, int startDate = 0 )
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

double SystemAverageTrade( int nMagic, int startDate = 0 )
{
    double numTrades = 0,
           totalProfit = 0;

    for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
        if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
        if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;

        numTrades += 1;
        totalProfit += NetDelta();
    }

    if( numTrades == 0 || totalProfit == 0 ) return( 0 );

    return( totalProfit / numTrades );
}

double SystemTPY( int nMagic, int startDate = 0 )
{
    datetime   firstTradeDate = TimeCurrent();
    
    double     numTrades = 0,
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
        
        numTrades += 1;

    }
    
    years = TimeYear(TimeCurrent()) - TimeYear(firstTradeDate);
    days = TimeDayOfYear(TimeCurrent()) - TimeDayOfYear(firstTradeDate);
    
    timeDiff = 365*years + days;
    
    if( numTrades == 0 || timeDiff == 0 ) return( 0 );
    
    double TPY = numTrades / timeDiff * 365;

    return( TPY );
}

double SystemExpectancy( int nMagic, int startDate = 0 )
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

double SystemStDev( int nMagic, int startDate = 0 )
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

double E50( int nMagic, int startDate = 0 )
{
   double E50 = 10000 * SystemAverageTrade( nMagic, startDate ) * SystemTPY( nMagic, startDate );
   return(E50);
}

double MDD( int nMagic, int startDate = 0)
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

double DD( int nMagic, int startDate = 0)
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

double CAR50( int nMagic, int startDate = 0, double FF = 0.1)
{

   double TPY = SystemTPY( nMagic, startDate );
   double mean = SystemAverageTrade( nMagic, startDate);

   double trade = ( 1 + FF * mean );
   double car50 = ( MathPow( trade, TPY) - 1 ) * 100;
   
   return( car50 );

}

double fixedFractionMDD( int nMagic, int startDate = 0, double FF = 0.1)
{
   
   double   trade = 0,
            equity = 1,
            maxEquity = 0,
            drawDown = 0,
            MaxDrawDown = 0;
   
   for( int i = 1 ; i <= OrdersHistoryTotal() ; i++ )
   {
      if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
      if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
      if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
      
      
      trade = equity * FF * NetDelta();
      equity += trade;
      
      if(equity > maxEquity)
      {
         maxEquity = equity;
      }
      
      drawDown = 100 * ( maxEquity - equity ) / equity;
      
      if( MaxDrawDown < drawDown )
      {
         MaxDrawDown = drawDown;
      }      
   } 
   
   return(MaxDrawDown);
}

double fixedFractionDD( int nMagic, int startDate = 0, double FF = 0.1)
{
   
   double   trade = 0,
            equity = 1,
            maxEquity = 0,
            drawDown = 0,
            MaxDrawDown = 0;
   
   for( int i = 1 ; i <= OrdersHistoryTotal() ; i++ )
   {
      if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
      if( OrderSymbol() == "" || OrderMagicNumber() != nMagic ) continue;
      if ( DateCheck(startDate, OrderCloseTime()) == false ) continue;
      
      
      trade = equity * FF * NetDelta();
      equity += trade;
      
      if(equity > maxEquity)
      {
         maxEquity = equity;
      }
      
      drawDown = 100 * ( maxEquity - equity ) / equity;     
   } 
   
   return(drawDown);
}

double SystemTTest( int nMagic, int startDate = 0 )
{
   double stdev = SystemStDev( nMagic, startDate ),
          t = 0;
          
   if (stdev == 0) return(0);  
   
   t = SystemAverageTrade( nMagic, startDate ) / stdev  * sqrt( TotalTradesHistory( nMagic, startDate ) );
   return (t);
}


int ErrorReport( int Error )
{
    switch( Error )
    {
            //Non Critical Errors
        case 4:
        {
            Alert( "Trade server is busy. Trying once again.." );
            Sleep( 3000 );                                              // Simple Solution
            return( 1 );
        }                                                           // Exit the function

        case 135:
        {
            Alert( "Price changed. Trying once again.." );
            RefreshRates();
            return( 1 );
        }

        case 136:
        {
            Alert( "No Prices. Waiting for a new tick.." );

            while( RefreshRates() == false )                            //Till a new tick
                Sleep( 1 );                                              //pause in Loop

            return( 1 );
        }

        case 137:
        {
            Alert( "Broker is Busy. Trying once again.." );
            Sleep( 3000 );
            return( 1 );
        }

        case 146:
        {
            Alert( "Trading System is Busy. Trying once again.." );
            Sleep( 500 );
            return( 1 );
        }

        // Critical Errors
        case 2:
        {
            Alert( "Common Error." );                                   // Terminate the functin
            Sleep( 3000 );
            return( 1 );
        }                                                           // Exit the function

        case 5:
        {
            Alert( "Old Terminal Version." );
            return( 0 );
        }

        case 64:
        {
            Alert( "Account Blocked." );
            return( 0 );
        }

        case 133:
        {
            Alert( "Trading Forbidden." );
            return( 0 );
        }

        case 134:
        {
            Alert( "Not Enough Money to Execute Operation" );
            return( 0 );
        }
    }

    return( 0 );
}

//+------------------------------------------------------------------+
//| Dormant Functions                                                |
//+------------------------------------------------------------------+


/*double CurrencyConverter(string symbol)
{   
   string BASE = SymbolInfoString(symbol,SYMBOL_CURRENCY_BASE);

   if(BASE == "USD")
   {
      return(1);
   }
   
   if(BASE == "GBP")
   {
      if( iClose("GBPUSD",PERIOD_D1,1) != 0 )
         return(100/iClose("GBPUSD",PERIOD_D1,1));
      else
         return(0);
   }
   
   if(BASE == "EUR")
   {
      if( iClose("EURUSD",PERIOD_D1,1) != 0 )
         return(1/iClose("EURUSD",NULL,1));
      else
         return(0);
   }

   if(BASE == "AUD")
   {
      if( iClose("AUDUSD",PERIOD_D1,1) != 0 )
         return(1/iClose("AUDUSD",NULL,1));
      else
         return(0);
   }  

   if(BASE == "JPY")
   {
      return(iClose("USDJPY",PERIOD_D1,1));
   }   
    
   if(BASE == "CAD")
   {
      return(iClose("USDCAD",PERIOD_D1,1));
   }  

   if(BASE == "CHF")
   {
      return(iClose("USDCHF",PERIOD_D1,1));
   }

   if(BASE == "PLN")
   {
      return(iClose("USDPLN",PERIOD_D1,1));
   }  

   if(BASE == "NOK")
   {
      return(iClose("USDNOK",PERIOD_D1,1));
   }   
    
   if(BASE == "HKD")
   {
      return(iClose("USDHKD",PERIOD_D1,1));
   }
   
   if(BASE == "SEK")
   {
      return(iClose("USDSEK",PERIOD_D1,1));
   }
   
   if(BASE == "HUF")
   {
      return(iClose("USDHUF",PERIOD_D1,1));
   }   
   
   return(0);   
}
*/