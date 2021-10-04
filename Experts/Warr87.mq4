//+------------------------------------------------------------------+
//|                                                     duc-warr.mq4 |
//|                                                           warr87 |
//|https://www.aussiestockforums.com/threads/warr-duc-aus-yen.35969/ |
//+------------------------------------------------------------------+
#property copyright "warr87"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property show_inputs

int magicNB = 11241;
input double riskPerTrade = 0.02;

input ENUM_TIMEFRAMES MTF_TF = PERIOD_D1;                 //Multi Timeframe - Moving Average Timeframe
input int MTF_PERIOD = 10;                                //Multi Timeframe - Moving Average Period
input ENUM_MA_METHOD MTF_METHOD = MODE_EMA;               //Multi Timeframe - Moving Average Method
input ENUM_APPLIED_PRICE MTF_PRICE = PRICE_CLOSE;         //Multi Timeframe - Moving Average Applied Price
input int MTF_SHIFT = 0;                                  //Multi Timeframe - Moving Average Shift
input int MA_SHIFT  = 0;                                  //Current Price chart MA shift
input int MA_PERIOD = 40;                                 //Current Price chart MA
input int ATR_PERIOD = 10;                                //Period for ATR lot sizing
input double ATR_MULT = 2.0;                              //ATR multiplier for sizing
input int ATR_SHIFT = 0;                                  //ATR shift for sizing


//+------------------------------------------------------------------+
//| functions                                                        |
//+------------------------------------------------------------------+
void ExitPosition(string _symbol, ENUM_ORDER_TYPE _orderType, int _maxSlippage, int _magicNumber){
   for( int i = OrdersTotal() - 1; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) )continue; 
      if( OrderSymbol() != _symbol )continue;
      if( OrderType() != _orderType )continue;
      if( OrderMagicNumber() != _magicNumber )continue;
      if( OrderType() == OP_BUY ){
         RefreshRates();
         if( OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(),MODE_BID), _maxSlippage, Red) )continue;
         Print( _symbol, " Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }
      if( OrderType() == OP_SELL ){
         RefreshRates();
         if( OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(),MODE_ASK), _maxSlippage, Red) )continue;
         Print( _symbol, " Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }     
   }
}

void tStopDon(string symb, double bsl, double ssl, int MN)// Symbol + stop in pips + magic number
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         if(OrderMagicNumber()==MN)
            if(OrderSymbol()==symb)

               if(OrderType()==OP_BUY && (OrderStopLoss()<bsl || OrderStopLoss()==0))
                  if(OrderModify(OrderTicket(),OrderOpenPrice(),bsl,OrderTakeProfit(),0,clrNONE))
                    {
                     Print(symb+" Buy's Stop Trailled to "+(string)bsl);
                       }else{
                     Print(symb+" Buy's Stop Trail ERROR");
                    }

               if(OrderType()==OP_SELL && (OrderStopLoss()>ssl || OrderStopLoss()==0))
                  if(OrderModify(OrderTicket(),OrderOpenPrice(),ssl,OrderTakeProfit(),0,clrNONE))
                    {
                     Print(symb+" Sell's Stop Trailled to "+(string)ssl);
                       }else{
                     Print(symb+" Sell's Stop Trail ERROR");
                    }
     }
  }

double GetPipValue()
{
   if(_Digits >=4)
   {
      return 0.0001;
   }
   else
   {
      return 0.01;
   }
}

double OptimalLotSize(double maxRiskPrc, int maxLossInPips)
{

  double accEquity = AccountEquity();
  Print("accEquity: " + accEquity);
  
  double lotSize = MarketInfo(NULL,MODE_LOTSIZE);
  Print("lotSize: " + lotSize);
  
  double tickValue = MarketInfo(NULL,MODE_TICKVALUE);
  
  if(Digits <= 3)
  {
   tickValue = tickValue /100;
  }
  
  Print("tickValue: " + tickValue);
  
  double maxLossDollar = accEquity * maxRiskPrc;
  Print("maxLossDollar: " + maxLossDollar);
  
  double maxLossInQuoteCurr = maxLossDollar / tickValue;
  Print("maxLossInQuoteCurr: " + maxLossInQuoteCurr);
  
  double optimalLotSize = NormalizeDouble(maxLossInQuoteCurr /(maxLossInPips * GetPipValue())/lotSize,2);
  
  return optimalLotSize;
 
}


double OptimalLotSize(double maxRiskPrc, double entryPrice, double stopLoss)
{
   int maxLossInPips = MathAbs(entryPrice - stopLoss)/GetPipValue();
   return OptimalLotSize(maxRiskPrc,maxLossInPips);
}


int CountExpertOrders( string _symbol, int _nOrderType, int _nMagic )
{
    int nOrderCount = 0;

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;

        if( OrderType() == _nOrderType && OrderMagicNumber() == _nMagic && OrderSymbol() == _symbol )
        {
            nOrderCount++;
        }
    }

    return( nOrderCount );
}

bool IsNewBar() {

   datetime          currentBarTime = iTime(Symbol(), Period(), 0);
   static datetime   prevBarTime    = currentBarTime;
   if(prevBarTime<currentBarTime){
      prevBarTime = currentBarTime;
      return(true);
   }
   return(false);
}

double ATRlots(int _ATR_PERIOD, double _ATR_MULT, int _ATR_SHIFT, double _risk){
   double    _ATR_SIZING     =     iATR(Symbol(),PERIOD_CURRENT,_ATR_PERIOD,_ATR_SHIFT);
   double    _ATR_PIPS       =     NormalizeDouble(MathAbs((_ATR_SIZING * _ATR_MULT)),Digits());
   double    riskAmmount     =     AccountBalance() * 0.02;
   double    atickValue      =     SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE);

   double lots = NormalizeDouble((_risk / ((_ATR_PIPS) / _Point * atickValue)),2);
   return(lots);
}
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
  int       mtfbuff        =     0;
  double    mtf1           =     iMA(Symbol(),MTF_TF,MTF_PERIOD,MTF_SHIFT,MTF_METHOD,MTF_PRICE,MTF_SHIFT);
  double    MA1            =     iMA(Symbol(),PERIOD_CURRENT,MA_PERIOD,MA_SHIFT,MODE_SMA,PRICE_CLOSE,MA_SHIFT);
  double    ATR_SIZING     =     iATR(Symbol(),PERIOD_CURRENT,ATR_PERIOD,ATR_SHIFT);
  double    ATR_PIPS       =     NormalizeDouble((ATR_SIZING * ATR_MULT),Digits());
  
  int numOpenShort = CountExpertOrders(Symbol(),OP_SELL,magicNB);
  int numOpenLong = CountExpertOrders(Symbol(),OP_BUY,magicNB);
  int totalOpenPos = numOpenShort + numOpenLong;
  
   string com = "";
   com+="\n-numOpenShort = " + (string)numOpenShort;
   com+="\n-numOpenLong = " + (string)numOpenLong;
   com+="\n-Total Open Positions = " + (string)numOpenLong;

   Comment(com);
  

if (!IsNewBar()) return; // --> this is good because it stops the code execution and saves resources
if(MA1 > mtf1){ // if MA indicates long position
   if(totalOpenPos == 0){ // if number of open positions == 0
      // --- place order to buy and return error if fails
      int buyticket = OrderSend(Symbol(),OP_BUY,0.10,Ask,5,mtf1,NULL,"Long entry: " + magicNB,magicNB,0,Green);      
      if(buyticket<0){
         Comment("Order failed to send: " + GetLastError());
      }
   }
}
  

  
  //exit long
  if(CountExpertOrders(Symbol(),OP_BUY,magicNB)==1 && MA1 < mtf1){
  ExitPosition(Symbol(),OP_BUY,5,magicNB);
  
  }
  
  
  
  if(MA1 < mtf1 && ((CountExpertOrders(Symbol(),OP_SELL,magicNB)==0) || CountExpertOrders(Symbol(),OP_BUY,magicNB)==0)) { //go short
         int sellticket = OrderSend(Symbol(),OP_SELL,0.10,Ask,5,mtf1,NULL,"Short entry: " + magicNB,magicNB,0,Green);
            if(sellticket<0){
                Comment("Order failed to send: " + GetLastError());
    }
  }
  //exit short
  if(CountExpertOrders(Symbol(),OP_SELL,magicNB)==1 && MA1 > mtf1){
  ExitPosition(Symbol(),OP_SELL,5,magicNB);
  
  }
  
  //trailing stop
   tStopDon(Symbol(),mtf1,mtf1,magicNB);
}


//+------------------------------------------------------------------+