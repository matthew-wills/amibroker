//+------------------------------------------------------------------+
//|                                               myFunctionsPro.mqh |
//|                                                    Matthew Wills |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Matthew Wills"
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
// This function returns true when a new bar is placed on the chart
bool NewBar(string _symbol, ENUM_TIMEFRAMES _timeFrame){
   static datetime lastBarOpenTime = 0;
   datetime thisBarOpenTime = iTime(_symbol,_timeFrame,0);//Time[0];  
   if( lastBarOpenTime == 0 ){
      lastBarOpenTime = thisBarOpenTime;  
      return(false);
   }
   if( thisBarOpenTime != lastBarOpenTime ){
      lastBarOpenTime = thisBarOpenTime;
      return(true);
   }  
   return(false);
}

bool NewBarOnChart(){
   static datetime lastBarOpenTime = 0;
   datetime thisBarOpenTime = Time[0];  
   if( lastBarOpenTime == 0 ){
      lastBarOpenTime = thisBarOpenTime;  
      return(false);
   }
   if( thisBarOpenTime != lastBarOpenTime ){
      lastBarOpenTime = thisBarOpenTime;
      return(true);
   }  
   return(false);
}

bool NewMinute(){
    static datetime LastMinute = -1;
    datetime ThisMinute = TimeMinute( TimeGMT() );
    if( ThisMinute != LastMinute ){
        LastMinute = ThisMinute;
        return ( true );
    }
    return ( false );
}

int CountOrders( string _symbol = "all_Symbols", int nOrderType = -1, int _magicNumber = -1 ){
   int nOrderCount = 0;
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      if( _magicNumber != -1 && OrderMagicNumber() != _magicNumber )continue;
      if( _symbol != "all_Symbols" && OrderSymbol() != _symbol ) continue; 
      if( nOrderType != -1 && OrderType() != nOrderType )continue;
      nOrderCount++;
   }
   return( nOrderCount );
}

double RoundPrice( string _symbol, double _price ){
   double tickSize = MarketInfo( _symbol, MODE_TICKSIZE );
   return(NormalizeDouble(MathCeil( _price / tickSize)*tickSize,(int)MarketInfo( _symbol, MODE_DIGITS)));
}

double RoundVolume( string _symbol, double Lots ){
   double maxVolume = MarketInfo( _symbol, MODE_MAXLOT );
   double minVolume = MarketInfo( _symbol, MODE_MINLOT );
   double minVolumeStep = MarketInfo( _symbol, MODE_LOTSTEP );
   if( Lots < minVolume ){
      Print( "Volume is less than minimum order... I will submit minimum volume for the order" );
      return(minVolume);
   }   
   if( Lots > maxVolume ){
      Print( "Volume is greater than maximum order... I will submit maximum volume for the order" );
      return(maxVolume);
   }
   return( MathRound( Lots / minVolumeStep ) * minVolumeStep );
}

bool EnterPosition( string _symbol, ENUM_ORDER_TYPE _orderType, double _lots, double _price, int _slippage, double _stopLoss, double _takeProfit, int _magicNumber, string _label )
{
   double lots = RoundVolume( _symbol, _lots );
   double entry_price = RoundPrice(_symbol, _price );   
   double stoploss = RoundPrice( _symbol, _stopLoss  );
   double takeprofit = RoundPrice( _symbol, _takeProfit);
  
   RefreshRates();
   
   if( OrderType() == OP_BUY ) _price = MarketInfo(_symbol,MODE_ASK);
   if( OrderType() == OP_SELL) _price = MarketInfo(_symbol,MODE_BID);

   if( !OrderSend( _symbol, _orderType, lots, entry_price, _slippage, stoploss, takeprofit, _label, _magicNumber, 0, Green ) )
   {
     ErrorReport( GetLastError() );
     return(false);
   }
   return(true);
}

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

void ExitAllPositions(int _maxSlippage){
   for( int i = OrdersTotal() - 1; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) )continue;  
      if( OrderType() == OP_BUY ){
         RefreshRates();
         if( OrderClose( OrderTicket(), OrderLots(),MarketInfo(OrderSymbol(),MODE_BID), _maxSlippage, Red) )continue;
         Print( "Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }
      if( OrderType() == OP_SELL ){
         RefreshRates();
         if( OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(),MODE_ASK), _maxSlippage, Red) )continue;
         Print( "Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }     
   }     
}

void DeleteAllPendingOrders(){
   for( int i = OrdersTotal() - 1; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) )continue;  
      if( OrderType() != OP_BUY && OrderType() != OP_SELL )continue;
      if( OrderDelete(OrderTicket()) )continue;
      Print( "Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
   }
}

void DeletePendingOrder(string _symbol, ENUM_ORDER_TYPE _orderType, int _magicNumber){
   for( int i = OrdersTotal() - 1; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) )continue;  
      if( OrderSymbol() != _symbol )continue;
      if( OrderType() != _orderType )continue;
      if( OrderMagicNumber() != _magicNumber )continue;
      if( OrderDelete(OrderTicket()) )continue;
      Print( "Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
   }
}

bool ModifyPosition( string _symbol, double _takeProfit, double _stopLoss, int _magicNumber ){
   double stoploss = RoundPrice(_symbol,_stopLoss);
   double takeprofit = RoundPrice(_symbol,_takeProfit);
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;        
      if( OrderSymbol() != _symbol || OrderMagicNumber() != _magicNumber ) continue;
      if( OrderTakeProfit() == takeprofit && OrderStopLoss() == stoploss) return(true);
      if( OrderModify( OrderTicket(), OrderOpenPrice(), stoploss, takeprofit, clrNONE ) ){
         return(true);
      }
      else{
         Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }
   }
   Print("OrderModify Failed ...");
   return(false);
}

bool DateCheck(datetime _startDate, datetime _objectDate){
   if( _objectDate > _startDate){
      return(true);
   }
   else{
      return(false);
   }
}

int TotalTradesHistory( string _symbol, int _magicNumber, datetime _startDate ){
   int nTrades = 0;
   for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
      if( _symbol != "" && OrderSymbol() != _symbol )continue;
      if( _magicNumber != NULL && OrderMagicNumber() != _magicNumber ) continue;
      if ( DateCheck(_startDate, OrderCloseTime()) == false ) continue;   
      nTrades += 1;
   }
return( nTrades );
}

double LastTrade_Profit(string _symbol, int _magicNumber, datetime _startDate){
   double profit = 0;
   datetime orderCloseTime = 0;
   for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
      if( _symbol != "" && OrderSymbol() != _symbol ) continue;
      if( _magicNumber != NULL && OrderMagicNumber() != _magicNumber ) continue;
      if ( DateCheck(_startDate, OrderCloseTime()) == false ) continue;   
      if(OrderCloseTime() > orderCloseTime){
         orderCloseTime = OrderCloseTime();
         profit = OrderProfit();
      };
   }
   return(profit);
}

bool newTradeClosed(string _symbol, int _magicNumber, datetime _startDate){
   static double actNumTrades = -1;
   int currentNumTrades = TotalTradesHistory(_symbol,_magicNumber,_startDate);      
   if( currentNumTrades != actNumTrades && currentNumTrades > 0 ){
      actNumTrades = currentNumTrades;
      Print(_Symbol + " ... new trade found in history");
      return(true);
   }
   return(false);
}

void TrailingStop_Bars( string _symbol, int _magicNumber, int _timeFrame, int _bars ){
   double trailingStopValue = 0;
   
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){  
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      if( OrderSymbol() != _symbol ) continue;      
      if( OrderMagicNumber() != _magicNumber ) continue;
      if( OrderType() != OP_BUY && OrderType() != OP_SELL ) continue;

      
      double currentTakeProfit = OrderTakeProfit();
      double currentStopLoss = OrderStopLoss();
         
      if( OrderType() == OP_BUY ){
         trailingStopValue = LLV( _symbol, _timeFrame, _bars,1 );
         Print("trailingStopValue = ", trailingStopValue);
         if( trailingStopValue <= currentStopLoss ) continue;
         RefreshRates();
         if( OrderModify( OrderTicket(), OrderOpenPrice(), trailingStopValue, currentTakeProfit, 0 ) ) continue;
         Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }
   
      if( OrderType() == OP_SELL )
      {
         trailingStopValue = HHV( _symbol, _timeFrame, _bars,1 );
         if( trailingStopValue >= currentStopLoss ) continue;
         RefreshRates();
         if( OrderModify( OrderTicket(), OrderOpenPrice(), trailingStopValue, currentTakeProfit, 0 ) ) continue;
         Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }
   }
}

double OpenPrice( string _symbol, int _magicNumber ){
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      if( OrderSymbol() != _symbol )continue;
      if( OrderMagicNumber() != _magicNumber)continue;
      return(OrderOpenPrice());
   }
   return(0);
}

double OpenLots( string _symbol, int _magicNumber ){
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      if( OrderSymbol() != _symbol )continue;
      if( OrderMagicNumber() != _magicNumber)continue;
      return(OrderLots());
   }
   return(0);
}

double HHV( string _symbol, int _timeFrame, int _bars,int _shift){
   int shift = iHighest(_symbol, _timeFrame, MODE_HIGH,_bars,_shift);
   return( iHigh(_symbol, _timeFrame, shift) );
}

double LLV( string _symbol, int _timeFrame, int _bars,int _shift){
   int shift = iLowest(_symbol, _timeFrame, MODE_LOW,_bars,_shift);
   return( iLow(_symbol, _timeFrame, shift) );
}

// This function returns the number of Bars Since the selected order was entered
int BarsSinceEntry( string symbol, ENUM_TIMEFRAMES timeframe, int nMagic ){
    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
        if( OrderSymbol() == symbol && OrderMagicNumber() == nMagic ){
            return( iBarShift( symbol, timeframe, OrderOpenTime() ) );
        }
    }
    return( 0 );
}

// This function returns true if the EA closed a trade on this bar
bool ExitBar( string _symbol, ENUM_TIMEFRAMES _timeFrame, int _magicNumber ){
   for( int i = OrdersHistoryTotal() ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) continue;
      if( OrderSymbol() != _symbol ) continue;
      if( OrderMagicNumber() != _magicNumber )continue;
      if( iBarShift( _symbol, _timeFrame, OrderCloseTime() ) == 0 ) return(true);
   }
   return( false );
}  

void TerminateEA(){
   ExpertRemove();
}

void AlertUser(string _message, bool _sendAlert, bool _sendEmail, bool _sendNotification)
{
   string label = StringConcatenate(Symbol()," ");
   string completeMessage = StringConcatenate(label,_message);
   if(_sendAlert){
      Alert(completeMessage);
   }
   else{
      Print(completeMessage);
   }   
   if(_sendEmail){
      SendEmail("",completeMessage);
   }
   if(_sendNotification){
      SendNotification(completeMessage);
   }
}

void SendEmail( string _expertName, string _message )
{        
   string subject = StringConcatenate(
      "\n", _expertName, Symbol()
   );
   
   string body = StringConcatenate(subject,"\n",_message);
   SendMail(subject,body);
}

bool OrderClosedByStop(string _symbol, int _magicNumber){
   datetime lastOrder_closeTime = 0;
   string lastOrder_comment = "";
   double lastOrder_closePrice = 0;
   double lastOrder_takeProfit = 0;
   double lastOrder_stopLoss = 0;
   int numOrdersSelected = 0;
   for( int i = 0; i <= OrdersHistoryTotal() - 1; i++ )
   {     
      if( !OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) ) continue;
      if( OrderSymbol() != _symbol )continue;
      if( OrderMagicNumber() != _magicNumber ) continue;
      numOrdersSelected += 1;
      if( OrderCloseTime() > lastOrder_closeTime ){
         lastOrder_comment = OrderComment();
         lastOrder_closePrice = OrderClosePrice();
         lastOrder_takeProfit = OrderTakeProfit();
         lastOrder_stopLoss = OrderStopLoss();    
      }
   }
   if(numOrdersSelected == 0 || lastOrder_comment == "[sl]" || lastOrder_comment == "[tp]"){
      //Print(" EA detected order closed by SL or TP ");
      return(true);
   }
   Print(" EA Detected last order not closed by SL or TP");
   return(false);     
}

void GenerateComment(int _xPixels, int _yPixels){   
   int currentTime = TimeHour(TimeCurrent())*100 + TimeMinute(TimeCurrent());   
   double accountBalance = AccountBalance();
   double equity = AccountEquity();
   double openPnL = equity - accountBalance;
   double loss = 0;
   double profit = 0;
   
   if(openPnL >= 0){
      profit = openPnL;
   }
   else{
      loss = -1 * openPnL;
   }  
   double profitPct = profit / accountBalance * 100;
   double lossPct = loss/accountBalance *100;   
   
   
   string com;
   com+="\n=========================";   
   com+="\n   ";
   com+="\n=========================";
   com+="\n                   Positive Profit";
   com+="\n=========================";
   com+="\n-Profit Money = ";
   com+="\n-Profit %       = ";
   com+="\n-Profit Equity = ";
   com+="\n=========================";
   
   CommentXY(com, _xPixels, _yPixels); 
}

void CommentXY( string Str, long x = 0, long y = 0 )
{
   /*--- set window size   
   //--- chart window size
   long x_distance;
   long y_distance;
  
   if(!ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,x_distance)){
      Print("Failed to get the chart width! Error code = ",GetLastError());
      return;
   }
   
   if(!ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,y_distance)){
      Print("Failed to get the chart height! Error code = ",GetLastError());
      return;
   }
   */
   long X = x;//x_distance - x;
   long Y = y;//y_distance - y;  
  
   string Shift = NULL; 
   StringInit(Shift, (int)X >> 2, ' '); 
   if(StringLen(Shift)){
      StringReplace(Str, "\n", "\n" + Shift);   
      Str = Shift + Str;
   }
   if(Y){
      StringInit(Shift, (int)Y / 14, '\n');   
      Str = Shift + Str;
   }    
   Comment(Str);  
}


int ErrorReport( int Error )
{
   switch( Error ){
   //Non Critical Errors
      case 4:{
         Print( "Trade server is busy. Trying once again.." );
         Sleep( 3000 );                                           // Simple Solution
         return( 1 );
      }                                                           // Exit the function
      
      case 135:{
         Print( "_price changed. Trying once again.." );
         RefreshRates();
         return( 1 );
      }
      
      case 136:{
         Print( "No _prices. Waiting for a new tick.." );  
         while( RefreshRates() == false )                         //Till a new tick
             Sleep( 1 );                                          //pause in Loop 
         return( 1 );
      }
      
      case 137:{
         Print( "Broker is Busy. Trying once again.." );
         Sleep( 3000 );
         return( 1 );
      }
      
      case 146:{
         Print( "Trading System is Busy. Trying once again.." );
         Sleep( 500 );
         return( 1 );
      }
      
      // Critical Errors
      case 2:{
         Print( "Common Error." );                                // Terminate the functin
         Sleep( 3000 );
         return( 1 );
      }                                                           // Exit the function
      
      case 5:{
         Print( "Old Terminal Version." );
         return( 0 );
      }
      
      case 64:{
         Print( "Account Blocked." );
         return( 0 );
      }
      
      case 133:{
         Print( "Trading Forbidden." );
         return( 0 );
      }
      
      case 134:{
         Print( "Not Enough Money to Execute Operation" );
         return( 0 );
      }
   }  
   return( 0 );
}