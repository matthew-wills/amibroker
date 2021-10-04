//+------------------------------------------------------------------+
//|                                                   myTemplate.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Import Structures Classes and Include Files                      |
//+------------------------------------------------------------------+  
MqlTick  m_tick;
MqlRates m_rates;

// remove after final itteration and paste in all functions needed
//#include <myFunctionsPro.mqh>

//+------------------------------------------------------------------+
//| User Inputs                                                      |
//+------------------------------------------------------------------+

string systemName = "Incrementum_Scale_In";

extern string     GENERAL_SETTINGS     = "----- general settings -----";
extern bool allowTrading = true; // Allow EA to Trade
extern bool sendAlerts = false; // Generate Alerts 
extern bool sendEmails = false; // Send Email Alerts
extern bool sendNotification = false; // Send Notificaitons

extern int magicNumber = 1;// Magic Number (original system)

extern string     SCALE_IN_LEVELS     = "----- scale in level settings -----";
extern double GRID_LEVEL_1 = 100;
extern double GRID_LEVEL_2 = 100;
extern double GRID_LEVEL_3 = 100;
extern double GRID_LEVEL_4 = 100;
extern double GRID_LEVEL_5 = 100;
extern string     SCALE_IN_MULTIPLES     = "----- scale in mult settings -----";
extern double GRID_MULT_1 = 1.60;
extern double GRID_MULT_2 = 2.56;
extern double GRID_MULT_3 = 4.10;
extern double GRID_MULT_4 = 6.55;
extern double GRID_MULT_5 = 10.49;

extern string    TAKE_PROFIT_SETTINGS     = "----- Take Profit Settings -----";
extern double TP_PCT = 1; // Hard Stop TakeProfit Percent

extern string     BREAK_EVEN     = "----- Break EvenSettings -----";
extern bool useBreakEvenStop = true; // BreakEven Stop On/Off
extern double breakEvenTrigger = 600; // Points at which breakEven stops are set
extern double breakEvenBuffer = 10; // Points above breakEven to ensure costs are covered  

extern string     EXTREME_BREAK_EVEN     = "----- Break EvenSettings -----";
extern bool useExtremeBreakEvenStop = true; // Extreme Safety Mode BreakEven Stop On/Off
extern double extremeBreakEvenTrigger = 1200; // Extreme BreakEven Points
extern double extremeBreakEvenDrawDown = 10;// Percent of DrawDown above which positions will be closed  

extern string     STOP_LOSS_SETTINGS     = "----- Stop Loss Settings -----";
extern double SL_PCT = 20; // Hard Stop StopLoss Percent;
extern double VOLATILITY_STOP_MULTI = 2; // Volatility Stop Mulitplier;

int maxSlippage = 30000;// Max Acceptable Slippage 

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+

// primary system global variables
double rsi1 = -1;

int primarySignal_Long = 0;
int primarySignal_Short = 0;
double primaryOpenPrice = 0;
double primaryLots = 0;

double points = 0;

// scale in global variables
int magicNumber2;

int totalOpenLong = 0;
int totalOpenShort = 0;

double averagePriceLong = 0;
double averagePriceShort = 0;

double balance = 0;
double pnlPct = 0;
double breakEvenPrice = 0;
int breakEvenFlag = 0;

double volatilityScore = 0;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   magicNumber2 = generateMagicNumber(magicNumber);
    
   Comment("Expert Initialized");

return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   Comment("Expert Removed - Please See Log For Details");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   Load_Position_Info();   
   
   ExpertMain();   
   
   GenerateComments();
   
   RunBasicSystem();
   
}

//+------------------------------------------------------------------+
//| Expert Specific functions                                        |
//+------------------------------------------------------------------+

void Load_Position_Info(){
   primarySignal_Long = CountOrders(_Symbol,OP_BUY,magicNumber);
   primarySignal_Short = CountOrders(_Symbol,OP_SELL,magicNumber);

   primaryOpenPrice = OpenPrice(_Symbol,magicNumber);
   primaryLots = OpenLots(_Symbol,magicNumber);
   
   points = (Bid - primaryOpenPrice)/_Point;
   
   totalOpenLong = primarySignal_Long + CountOrders(_Symbol,OP_BUY,magicNumber2);
   totalOpenShort = primarySignal_Short + CountOrders(_Symbol,OP_SELL,magicNumber2);
   
   if( totalOpenLong == 0 && totalOpenShort == 0){
      breakEvenFlag = 0;
      breakEvenPrice = 0;
      points = 0;
   }
   
   averagePriceLong = AverageEntryPrice(_Symbol,OP_BUY);
   averagePriceShort = AverageEntryPrice(_Symbol,OP_SELL);
}

void Load_Variables(){
   balance = AccountBalance();
   pnlPct = PnlPct();
   volatilityScore = VolatilityScore();
}

void RunBasicSystem(){
   if(NewBar(_Symbol,PERIOD_CURRENT)){
      rsi1 = iRSI(_Symbol,PERIOD_CURRENT,4,PRICE_CLOSE,1);
      int numOpenLong = CountOrders(_Symbol,OP_BUY,magicNumber);
      int numOpenShort = CountOrders(_Symbol,OP_SELL,magicNumber);
      
      if(numOpenLong == 0 && numOpenShort == 0){
         if(rsi1 < 20 ){
            Comment("Entering Long Position");
            EnterPosition(_Symbol,OP_BUY,0.1,Ask,maxSlippage,0,0, magicNumber,"rsiLongEntry"); 
            return; 
         }   
      }
      if(numOpenLong != 0 && rsi1 > 90){
         ExitPosition(_Symbol,OP_BUY,maxSlippage,magicNumber);
         return; 
      }
      
      if(numOpenLong == 0 && numOpenShort == 0){
         if(rsi1 > 80 ){
            Comment("Entering Short Position");
            EnterPosition(_Symbol,OP_SELL,0.1,Bid,maxSlippage,0,0,magicNumber,"rsiShortEntry");
            return;   
         }   
      }
      if(numOpenShort != 0 && rsi1 < 10){
         ExitPosition(_Symbol,OP_SELL,maxSlippage,magicNumber);
         return; 
      }
   }
   return; 
}

void ExpertMain(){
   Load_Variables();
   
   if(totalOpenLong != 0){
      TradeManagerLong();
      return;
   }      
   if(totalOpenShort != 0){
      TradeManagerShort();
      return;
   }
}   

void TradeManagerLong(){
//--- check for exits  
   // if primary signal is closed
   if(primarySignal_Long == 0){
      AlertUser("Primary Signal Closed - Exiting all other positions");
      ExitLongPositions(magicNumber2);
   }  
   // check breakEven settings
   if(useBreakEvenStop == true){
      if(breakEvenFlag < 1){
         if(Ask < primaryOpenPrice-breakEvenTrigger*_Point){
            AlertUser("Break Even Stop Activated");             
            breakEvenFlag = 1;
            breakEvenPrice = averagePriceLong + breakEvenBuffer * _Point;
         }
      }
   }
   if(useExtremeBreakEvenStop == true && breakEvenFlag < 2){
      if(Ask < primaryOpenPrice-extremeBreakEvenTrigger*_Point){         
         breakEvenFlag = 2;
         AlertUser("Extreme Break Even Stop Activated");
      }
   }
   
   if( breakEvenFlag == 1){
      if( Bid > breakEvenPrice ){
         AlertUser("Exiting all positions at Break Even");
         CloseAllOpenPositions();
      }
   }
   if(breakEvenFlag == 2){
      if(pnlPct > -extremeBreakEvenDrawDown){
         AlertUser("Exiting all positions at Extreme Break Even");
         CloseAllOpenPositions();
      } 
   }
   
   // check hard stop (both TP and SL)
   CheckHardStop();  
   // check volatility stop (non directional - indicates high volatility in either direction)
   CheckVolatilityStop();
   
//--- check for entries
   double nextLevel = primaryOpenPrice - ComputePoints(totalOpenLong);
   double posSize = primaryLots * ComputeMultiple(totalOpenLong);
   
   if(Ask < nextLevel && posSize != 0 && volatilityScore < 100){
      RefreshRates();
      EnterPosition(_Symbol,OP_BUY,posSize,Ask,maxSlippage,0,0,magicNumber2,"");
      return;
   } 
}

void TradeManagerShort(){
//--- check for exits  
   // if primary signal is closed
   if(primarySignal_Short == 0){
      AlertUser("Primary Signal Closed - Exiting all other positions");
      ExitShortPositions(magicNumber2);
   }  
   // check breakEven settings
   if(useBreakEvenStop == true){
      if(breakEvenFlag < 1){
         if(Bid > primaryOpenPrice+breakEvenTrigger*_Point){
            AlertUser("Break Even Stop Activated");            
            breakEvenFlag = 1;
            breakEvenPrice = averagePriceShort - breakEvenBuffer * _Point;
         }
      }
   }
   if(useExtremeBreakEvenStop == true && breakEvenFlag < 2){
      if(Bid > primaryOpenPrice+extremeBreakEvenTrigger*_Point){
         breakEvenFlag = 2;
         breakEvenPrice = averagePriceShort*(1+extremeBreakEvenDrawDown*0.01);
         AlertUser("Extreme Break Even Stop Activated");
      }
   }
   
   if( breakEvenFlag == 1 ){
      if( Ask < breakEvenPrice ){
         AlertUser("Exiting all positions at Break Even");
         CloseAllOpenPositions();
      }
   }
   if(breakEvenFlag == 2){
      if(pnlPct > -extremeBreakEvenDrawDown){
         AlertUser("Exiting all positions at Extreme Break Even");
         CloseAllOpenPositions();
      } 
   }

   // check hard stop (both TP and SL)
   CheckHardStop();  
   // check volatility stop (non directional - indicates high volatility in either direction)
   CheckVolatilityStop();
   
//--- check for entries
   double nextLevel = primaryOpenPrice + ComputePoints(totalOpenShort);
   double posSize = primaryLots * ComputeMultiple(totalOpenShort);
   
   if(Bid > nextLevel && posSize != 0 && volatilityScore < 100){
      RefreshRates();
      EnterPosition(_Symbol,OP_SELL,posSize,Bid,maxSlippage,0,0,magicNumber2,"");
      return;
   } 
}

void CheckHardStop(){
   if(pnlPct < -SL_PCT){
      Print("Hard StopLoss Triggered");
      CloseAllOpenPositions();
   }  
   if(pnlPct > TP_PCT){
      Print("Hard TakeProfit Triggered");
      CloseAllOpenPositions();
   } 
}

double PnlPct(){
   double bal = AccountBalance();
   double pnl = 0;  
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      if( OrderSymbol() != _Symbol) continue;
      if( OrderMagicNumber() != magicNumber && OrderMagicNumber() != magicNumber2 ) continue;
      pnl += OrderProfit() + OrderSwap() + OrderCommission();
   }  
   if(bal == 0) return(0);
   return(pnl/(bal)*100);
}

double VolatilityScore(){
   if( VOLATILITY_STOP_MULTI == 0 )return(0);
   double atr0 = iATR(_Symbol,PERIOD_D1,1,0);
   double atr14 = iATR(_Symbol,PERIOD_D1,14,1);   
   if( atr14 == 0 )return(0);
   return(atr0 / (VOLATILITY_STOP_MULTI*atr14)*100); 
}

void CheckVolatilityStop(){
   if(volatilityScore > 100){
      Print("Volatility Stop Triggered");
      CloseAllOpenPositions();
   }
}

double ComputeMultiple( int n ){  
   if(n<1 || n>6){return(0);}
   
   double m[7];
   double mult = 1;
   m[0] = 0;
   m[1] = GRID_MULT_1;
   m[2] = GRID_MULT_2;
   m[3] = GRID_MULT_3;
   m[4] = GRID_MULT_4;
   m[5] = GRID_MULT_5;
   m[6] = 0;
   
   mult = m[n];
   return ( mult );
}

double ComputePoints( int n ){
   if(n<1 || n>6){return(0);}
   double l[7];
   double level = 1;
   
   l[0] = 0;
   l[1] = GRID_LEVEL_1;
   l[2] = GRID_LEVEL_1+GRID_LEVEL_2;
   l[3] = GRID_LEVEL_1+GRID_LEVEL_2+GRID_LEVEL_3;
   l[4] = GRID_LEVEL_1+GRID_LEVEL_2+GRID_LEVEL_3+GRID_LEVEL_4;
   l[5] = GRID_LEVEL_1+GRID_LEVEL_2+GRID_LEVEL_3+GRID_LEVEL_4+GRID_LEVEL_5;
   l[6] = 0;
   
   level = l[n];
   return ( level * _Point );
}

////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+//
//|                     my Include Functions                         |//
//+------------------------------------------------------------------+//  
////////////////////////////////////////////////////////////////////////


void GenerateComments(){
   string com = "";
   com+="\n====================";
   com+="\n "+systemName;
   com+="\n Primary Magic Number = " + IntegerToString(magicNumber);   
   com+="\n====================\n";
   com+="\n Account Balance = "+ DoubleToString(balance,2);
   // Long Position Info
   if(totalOpenLong!=0){
      com+="\n\n============================";
      com+="\n MANAGING LONG POSITIONS";
      com+="\n============================";

      com+="\n number of Positions = "+ IntegerToString(totalOpenLong);
      com+="\n primary OpenPrice = "+ DoubleToString(primaryOpenPrice,_Digits);
      //com+="\n points = "+ DoubleToString(points,0);
      com+="\n\n average OpenPrice = "+ DoubleToString(averagePriceLong,_Digits);
      com+="\n volatilityScore = "+ DoubleToString(volatilityScore,2);    
   }
   // Short Position Info
   if(totalOpenShort!=0){
      com+="\n\n============================";
      com+="\n MANAGING SHORT POSITIONS";
      com+="\n============================";
      
      com+="\n number of Positions = "+ IntegerToString(totalOpenShort);
      com+="\n primary OpenPrice = "+ DoubleToString(primaryOpenPrice,_Digits);
      //com+="\n points = "+ DoubleToString(points,0);
      com+="\n average OpenPrice = "+ DoubleToString(averagePriceShort,_Digits);
      com+="\n\n Profit / Loss % = "+ DoubleToString(pnlPct,2);
      com+="\n volatilityScore = "+ DoubleToString(volatilityScore,2);    
   }
   
   if( breakEvenFlag == 1){
      com+="\n\n=======================";
      com+="\n    BREAKEVEN ACTIVATED";      
      com+="\n=======================";
      com+="\n breakEvenPrice = "+ DoubleToString(breakEvenPrice,_Digits);
   }
   
   if( breakEvenFlag == 2){
      com+="\n\n===============================";
      com+="\n    EXTREME BREAKEVEN ACTIVATED";      
      com+="\n===============================";
      com+="\n DrawDown % = "+ DoubleToString(-pnlPct,1);
   }
   
   if( volatilityScore >=100 ){
      com+="\n\n===============================";
      com+="\n    VOLATILITY STOP ACTIVATED";      
      com+="\n===============================";
      com+="\n volatilityScore = "+ DoubleToString(volatilityScore,2); 
   }
   
   Comment(com);
}

double AverageEntryPrice( string _symbol, int _nOrderType ){
    double ticksize = SymbolInfoDouble( _symbol, SYMBOL_TRADE_TICK_SIZE );
    int digits = (int)MarketInfo( _symbol, MODE_DIGITS );
    
    double sumLots = 0;
    double sumLotsPrice = 0;
    double averagePrice = 0;

    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
        if( OrderType() != _nOrderType) continue;
        if( OrderSymbol() != _symbol) continue;
        if( OrderMagicNumber() != magicNumber && OrderMagicNumber() != magicNumber2 ) continue;
        sumLots += OrderLots();
        sumLotsPrice += OrderLots() * OrderOpenPrice();
    }
    
    if( sumLots == 0 )
    {
      return(0);
    }
    
    averagePrice = sumLotsPrice / sumLots;    
    return( averagePrice);
}

void CloseAllOpenPositions(){
   ExitLongPositions(magicNumber);
   ExitLongPositions(magicNumber2);
   ExitShortPositions(magicNumber);
   ExitShortPositions(magicNumber2);
}

void ExitLongPositions(int _magicNumber){
   for( int i = OrdersTotal() - 1; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) )continue;  
      if( OrderType() == OP_BUY && OrderMagicNumber() == _magicNumber ){
         RefreshRates();
         if( OrderClose( OrderTicket(), OrderLots(), RoundPrice(OrderSymbol(),MarketInfo(OrderSymbol(),MODE_BID)), maxSlippage, Red) )continue;
         Print( "Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }   
   }     
}
void ExitShortPositions(int _magicNumber){
   for( int i = OrdersTotal() - 1; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) )continue;  
      if( OrderType() == OP_SELL && OrderMagicNumber() == _magicNumber ){
         RefreshRates();
         if( OrderClose( OrderTicket(), OrderLots(), RoundPrice(OrderSymbol(),MarketInfo(OrderSymbol(),MODE_ASK)), maxSlippage, Red) )continue;
         Print( "Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }     
   }     
}

void ApplyTakeProfitMulti( string symbol,double averagePrice, double TakeProfitPct, int nMagic )
{
    double takeprofit = 0;
    double ticksize = SymbolInfoDouble( symbol, SYMBOL_TRADE_TICK_SIZE );
    int digits = (int)MarketInfo( symbol, MODE_DIGITS );
    int magic2 = generateMagicNumber(magicNumber);
    for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- )
    {
        if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
        if( OrderMagicNumber() != nMagic && OrderMagicNumber() != magic2) continue;
        if( OrderSymbol() != symbol ) continue;
        {

          if( OrderType() == OP_BUY )
          {
              takeprofit = NormPrice( averagePrice * ( 1 + TakeProfitPct * 0.01), ticksize, digits );
          }

          if( OrderType() == OP_SELL )
          {
              takeprofit = NormPrice( averagePrice * ( 1 - TakeProfitPct * 0.01), ticksize, digits );
          }
            

         if( OrderTakeProfit() != takeprofit && takeprofit != 0 && OrderSymbol() == symbol)
         {
             if( !OrderModify( OrderTicket(), OrderOpenPrice(), OrderStopLoss(), takeprofit, 0 ) )
                 Print( "Order Modify Failed, order number: ", OrderTicket(), " Error ", GetLastError(), OrderTakeProfit(), takeprofit );
         }
        }
    }
}

double NormPrice(double price, double ticksize, double digits)
{
   double P1 = MathRound( price / ticksize) * ticksize;
   double P2 = NormalizeDouble(P1, (int)digits);
   return(P2);
}

int generateMagicNumber(int _magicNumber){
   return(_magicNumber*1000000+1);
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

void AlertUser(string _message)
{
   string label = StringConcatenate(Symbol()," ");
   string completeMessage = StringConcatenate(label,_message);
   if(sendAlerts){
      Alert(completeMessage);
   }
   else{
      Print(completeMessage);
   }   
   if(sendEmails){
      SendEmail("",completeMessage);
   }
   if(sendNotification){
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