//+------------------------------------------------------------------+
//|                                            MA_CROSS_ATR_STOP.mq4 |
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

//+------------------------------------------------------------------+
//| User Inputs                                                      |
//+------------------------------------------------------------------+
extern string userName = "Arwan";

extern string text_info_1 = "Guardian of the Galaxy EA v1";
extern string text_info_2 = "Be wise & trade with responsibility";

extern bool sendNotification = true;// Send Push Notifications 
extern bool sendAlerts = false; // Generate Alerts
extern bool sendEmails = false; // Send Email Alerts

extern string     POSITIVE_PROFIT      = "----- positive profit -----";
extern double profit_MoneyStop = 0; // Close all trade when profit money > 
extern double profit_ProfitPct = 0; // Close all trade when profit % >
extern double profit_EquityStop = 0; // Close all trade when Equity (USD) >  

extern string     NEGATIVE_PROFIT      = "----- negative profit -----";
extern double loss_MoneyStop = 0; // Close all trade when loss money > 
extern double loss_ProfitPct = 0; // Close all trade when loss % >
extern double loss_EquityStop = 0; // Close all trade when Equity (USD) <  

extern string     ANY_CONDITION      = "----- any condition -----";
extern int time_Friday = -1; // Close all trade on friday format = HH:MM (-1 ==> Off)
extern int time_AnyDay = -1; // Close all trade daily format = HH:MM (-1 ==> Off)

extern string     COMMENT_LOCATION   = "----- location of comments -----";
int x_pixels_shift = 0; // Number of pixels from left of window
extern int y_pixel_shift = 350; // Number of pixels up from bottom of window


int maxSlippage = 30;// Max Acceptable Slippage 

//+------------------------------------------------------------------+
//| USER SECURITY SECTION                                            |
//+------------------------------------------------------------------+
// Arwan Set your security details here then complie the MQL4 Code
string accountName = "Arwan";
int accountNumber = 1111785884;
int expiryTime = 20210101; //YYYYMMDD;

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   EventSetTimer( 1 );  
   Comment("Expert Initialized");
   
   int dateTime = TimeYear(TimeCurrent())*10000 + TimeMonth(TimeCurrent())*100 + TimeDay(TimeCurrent());
   if(accountNumber != AccountNumber()){
      Print("Account Number = " + (string)AccountNumber());
      AlertUser("This Expert Advisor is not Authorised on this Metatrader Account",true,false,false);
      TerminateEA();
   }
   if(dateTime > expiryTime){
      AlertUser("This Expert Advisoy has Expired Time Limit... please renew your lisence",true,false,false);
      TerminateEA();
   }
   if(accountName != userName){
      AlertUser("Incorrect User Name... Please Try Again",true,false,true);
      TerminateEA();
   }
   
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
void OnTimer()
{
//---        
   GenerateComment(x_pixels_shift, y_pixel_shift);
   Main();
}  
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert Specific functions                                        |
//+------------------------------------------------------------------+

void Main(){
//--- This is the main function which will run on either Tick() or Timer()
   double numOpenPositions = CountOrders("",-1,-1);
   if(numOpenPositions == 0) return;

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
   
   if(numOpenPositions > 0){
      if( profit >= profit_MoneyStop && profit_MoneyStop != 0){
         ActivateGuardian(profit,"profit_MoneyStop");
         return;   
      }   
      if( profitPct >= profit_ProfitPct && profit_ProfitPct != 0){ 
         ActivateGuardian(profit,"profit_ProfitPct");
         return;
      }
      if( equity >= profit_EquityStop && profit_EquityStop != 0){ 
         ActivateGuardian(profit,"profit_EquityStop");
         return;
      }
      if( loss >= loss_MoneyStop && loss_MoneyStop != 0){
         ActivateGuardian(profit,"loss_MoneyStop");
         return;   
      }   
      if( lossPct >= loss_ProfitPct && loss_ProfitPct != 0){ 
         ActivateGuardian(profit,"loss_ProfitPct");
         return;
      }
      if( equity <= loss_EquityStop && loss_EquityStop != 0){ 
         ActivateGuardian(profit,"loss_EquityStop");
         return;
      }
      if( currentTime >= time_AnyDay && time_AnyDay != -1){ 
         ActivateGuardian(profit,"Daily_TimeLimit");
         return;
      }
      if( TimeDayOfWeek(TimeCurrent() == 5) && currentTime >= time_Friday && time_Friday != -1){ 
         ActivateGuardian(profit,"Friday_timeLimit");
         return;
      }     
   }   
}

void ActivateGuardian(double _profit, string _reason){
   ExitAllPositions(maxSlippage);
   Print(StringConcatenate( "Guardian Activated Because: ",_reason ));
   string alertMessage = StringConcatenate("Your Guardian of the Galaxy has closed all the trade Account Balance = ... ",DoubleToString(AccountBalance(),2));
   AlertUser(alertMessage,sendAlerts,sendEmails,sendNotification);
}


////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+//
//|                     my Include Functions                         |//
//+------------------------------------------------------------------+//  
////////////////////////////////////////////////////////////////////////

void ExitAllPositions(int _maxSlippage){
   for( int i = OrdersTotal() - 1; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) )continue;  
      if( OrderType() == OP_BUY ){
         RefreshRates();
         if( OrderClose( OrderTicket(), OrderLots(), RoundPrice(OrderSymbol(),MarketInfo(OrderSymbol(),MODE_BID)), _maxSlippage, Red) )continue;
         Print( "Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }
      if( OrderType() == OP_SELL ){
         RefreshRates();
         if( OrderClose( OrderTicket(), OrderLots(), RoundPrice(OrderSymbol(),MarketInfo(OrderSymbol(),MODE_ASK)), _maxSlippage, Red) )continue;
         Print( "Order Close Failed, order number: ", OrderTicket(), " Error ", GetLastError() );
      }     
   }     
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
      string subject = StringConcatenate
      (
         "\n", _expertName, Symbol()
      );
      
      string body = StringConcatenate(subject,"\n",_message);
      SendMail(subject,body);
}

int CountOrders( string _symbol = "", int nOrderType = -1, int _magicNumber = -1 ){
   int nOrderCount = 0;
   for( int i = OrdersTotal() - 1 ; i >= 0 ; i-- ){
      if( !OrderSelect( i, SELECT_BY_POS ) ) continue;
      if( _magicNumber != -1 && OrderMagicNumber() != _magicNumber )continue;
      if( _symbol != "" && OrderSymbol() != _symbol ) continue; 
      if( nOrderType != -1 && OrderType() != nOrderType )continue;
      nOrderCount++;
   }
   return( nOrderCount );
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
   com+="\n   "+text_info_1;
   com+="\n   "+text_info_2;
   com+="\n=========================";
   com+="\n                   Positive Profit";
   com+="\n=========================";
   com+="\n-Profit Money = " + OnOff(profit_MoneyStop);
   com+="\n-Profit %       = " + OnOff(profit_ProfitPct);
   com+="\n-Profit Equity = " + OnOff(profit_EquityStop);
   com+="\n=========================";
   com+="\n                   Negative Profit";
   com+="\n=========================";
   com+="\n-Loss Money = " + OnOff(loss_MoneyStop);
   com+="\n-Loss %       = " + OnOff(loss_ProfitPct);
   com+="\n-Loss Equity  = " + OnOff(loss_EquityStop);
   com+="\n=========================";
   com+="\n                   Any Condition";
   com+="\n=========================";
   com+="\n-Friday Close Time     = " + OnOffTime(time_Friday);
   com+="\n-Any Day Close Time = " + OnOffTime(time_AnyDay);
   com+="\n=========================";
   com+="\n                   Current Levels";
   com+="\n=========================";     
   com+="\n-profit = " + DoubleToString(profit,2);
   com+="\n-profit % = " + DoubleToString(profitPct,2);
   com+="\n-loss = " + DoubleToString(loss,2);  
   com+="\n-loss % = " + DoubleToString(lossPct,2);
   com+="\n-CurrentTime = " + IntegerToString(currentTime); 
   com+="\n-Equity = " + DoubleToString(equity,2);     
   
   CommentXY(com, _xPixels, _yPixels); 
}

void CommentXY( string Str, long x = 0, long y = 0 )
{
   //--- chart window size
   long x_distance;
   long y_distance;
   
   //--- set window size
   if(!ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,x_distance)){
      Print("Failed to get the chart width! Error code = ",GetLastError());
      return;
   }
   
   if(!ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,y_distance)){
      Print("Failed to get the chart height! Error code = ",GetLastError());
      return;
   }
  
   long X = x;
   long Y = y_distance - y;  
  
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

string OnOff(double _setting){
   if(_setting > 0){
      return(DoubleToString(_setting,2));
   }
   return("OFF");
}

string OnOffTime(int _time){
   if(_time > 0){
      return(IntegerToString(_time));
   }
   return("OFF");
}

double RoundPrice( string _symbol, double _price ){
   double tickSize = MarketInfo( _symbol, MODE_TICKSIZE );
   return(NormalizeDouble(MathCeil( _price / tickSize)*tickSize,(int)MarketInfo( _symbol, MODE_DIGITS)));
}