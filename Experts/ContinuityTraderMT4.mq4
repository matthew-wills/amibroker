//+------------------------------------------------------------------+
//|                                            valterri_EA_v1.o.mq4 |
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
MqlRates rates[];

//#include <myFunctionsPro.mqh>

//+------------------------------------------------------------------+
//| User Inputs                                                      |
//+------------------------------------------------------------------+
enum ENUM_STRENGTH_MODE{ STRONGEST, // trade only the strongest
                         WEAKEST,   // trade only the weakest
                         ALL        // trade all symbols 
                       };

input string     GENERAL_SETTINGS      = "----- General Settings -----";
input bool sendNotification = false;// Send Push Notifications 
input bool sendAlerts = false; // Generate Alerts
input bool sendEmails = false; // Send Email Alerts

input bool onTesterMode = false; // Turn this on for strategy tester
input int magicNumber = 12345; // magicNumber
input ENUM_TIMEFRAMES timeFrame = PERIOD_M15; // Operation TimeFrame

input string US500_name = ".US500Cash"; //SP500 name
input string US30_name = ".US30Cash"; //DJ30 name
input string USTEC_name = ".USTECHCash"; //NDAQ name

input string     RULE_1      = "----- Set Trading Time Slots -----";
input bool trade_Monday = true;
input bool trade_Tuesday = true;
input bool trade_Wednesday = true;
input bool trade_Thursday = true;
input bool trade_Friday = true;
input int timeSlot_1_start = 1030; //time slot 1 start
input int timeSlot_1_end = 1315;//time slot 1 end
input int timeSlot_2_start = 1700;//time slot 2 start
input int timeSlot_2_end = 1900;//time slot 2 end
input int timeSlot_3_start = 2100;//time slot 3 start
input int timeSlot_3_end = 2230;//time slot 3 end
input int timeSlot_4_start = 0000;//time slot 4 start
input int timeSlot_4_end = 0000;//time slot 4 end

input int maxTradesPerTimeSlot = 1; // Max Number of Trades per Time Slot

input string     RULE_3      = "----- Distance from Previous Close -----";
input double minDistancePct = 0.3; // Minimum Distance from previous day close (%)
input double maxDistancePct = 3.5;// Maximum Distance from previous day close (%)

input string     RULE_4      = "----- Symbol Strength Test -----";
input ENUM_STRENGTH_MODE strengthMode = STRONGEST; // Strength Test Mode

input string     POSITION_SIZING_RULES      = "----- Position Sizing Rules -----";
input double StopLoss_Points = 20; // Stop loss above / below the Prior Candle (in points)
input double maximum_StopLoss = 10000;// Maximum StopLoss Size to cancel trade (in_Points)

input string     NORMAL_SETTING      = "----- Normal Settings -----";
input double Normal_PositionSize = 1.8;// Normal Position Size (Lots)
input double Normal_TakeProfit = 50;// TP percentage of SL (%)

input string     REDUCED_RISK_SETTING      = "----- Reduced Risk Settings -----";
input double RR_StopLoss_Min = 700; // StopLoss Size less than (to activate) in _Points
input double RR_StopLoss_Max = 2500; // StopLoss Size greater than (to activate) in _Points
input double RR_Relative_Min = 200;// Relative High/Low achieved less than (to activate) in _Points
input double RR_PositionSize = 1.2;// Normal Position Size (Lots)
input double RR_TakeProfit = 50;// TP percentage of SL (%)

input string     HIGHLY_REDUCED_RISK_SETTING      = "----- Highly Reduced Risk Settings -----";
input double HRR_StopLoss_Max = 3750; // StopLoss Size greater than (to activate) in _Points
input double HRR_PositionSize = 0.6;// Highly Reduced Position Size (Lots)
input double HRR_TakeProfit = 30;// TP percentage of SL (%)

int maxSlippage = 30;// Max Acceptable Slippage 

//+------------------------------------------------------------------+
//| Global Variable Definitions                                      |
//+------------------------------------------------------------------+

//--- variables
double prevDayClose = 0;
double candleSize = 0;
int checkTimeFilter = 0;
int checkDistance = 0;
int checkTrend = 0;
int checkSignal = 0;
int checkStrength = 0;
double relativeHigh = 0;
double relativeLow = 0;

double dailyMove_US30 = 0;
double dailyMove_US500 = 0;
double dailyMove_USTEC = 0;

//--- position counters
int numOpenExpert = 0;
int numOpenSymbol = 0;

//--- flags
int flag_6B = 0;
int flag_OpenTradeThisTimeSlot = 0;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   EventSetTimer( 1 );  
   
   RefreshVariables();
   GenerateComments();

return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   Comment("Expert Removed");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   if(onTesterMode == true) Main();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTimer()
{
//---        
   if(onTesterMode == false) Main();
}  
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert Specific functions                                        |
//+------------------------------------------------------------------+

void Main(){
//--- This is the main function which will run on either Tick() or Timer()
      
   //--- check for new bar
   if(NewBar(_Symbol,timeFrame)){
      
      //--- refresh variables
      RefreshVariables();
   
      //--- count number of positions
      RefreshPositionCounters();        
      
      //--- generate comments on current variables
      GenerateComments();            
      
      //--- check for position already open
      if(numOpenSymbol >= 1) return;
      
      //--- if necessary check for entry on rule 6b else reset flag
      if(flag_6B != 0){
         if(flag_6B == 1 && rates[1].close > rates[2].close){
            AlertUser("Long Signal Detected - Rule6B",sendAlerts,sendEmails,sendNotification);
            EnterLongFunction();
         }
         if(flag_6B == -1 && rates[1].close < rates[2].close){
            AlertUser("Short Signal Detected - Rule6B",sendAlerts,sendEmails,sendNotification);
            EnterShortFunction();
         }
         flag_6B = 0;
      }
      
      //--- check rules for long entry
      CheckEntryLong();
      
      //--- check rules for long entry
      CheckEntryShort();
           
   }
}

// Refresh Variables
void RefreshVariables(){
   RefreshRates();   
   CopyRates(_Symbol,PERIOD_M15,0,100,rates);
   ArraySetAsSeries(rates,true);
   
   prevDayClose = iClose(_Symbol,PERIOD_D1,1);
   candleSize = MathAbs((rates[1].close - rates[1].open) / _Point);
   
   dailyMove_US500 = DailyMove(US500_name);
   dailyMove_US30 = DailyMove(US30_name);
   dailyMove_USTEC = DailyMove(USTEC_name);
      
   if( checkTimeFilter != CheckTimeFilter() ){
      //AlertUser("New Time Zone Detected",sendAlerts,sendEmails,sendNotification);
      flag_OpenTradeThisTimeSlot = 0;
      checkTimeFilter = CheckTimeFilter();
   }
   
   checkDistance = CheckDistance();
   checkTrend = CheckTrendDirection();
   checkSignal = CheckSignal();
   checkStrength = CheckStrength(_Symbol);
   relativeHigh = RelativeHigh();
   relativeLow = RelativeLow(); 
}

void RefreshPositionCounters(){
   numOpenSymbol = CountOrders(_Symbol,magicNumber,ORDER_TYPE_BUY) + CountOrders(_Symbol,magicNumber,ORDER_TYPE_SELL);
}

void CheckEntryLong(){
   if(TimeDayOfWeek(TimeCurrent())==1 && trade_Monday==false)return;
   if(TimeDayOfWeek(TimeCurrent())==2 && trade_Tuesday==false)return;
   if(TimeDayOfWeek(TimeCurrent())==3 && trade_Wednesday==false)return;
   if(TimeDayOfWeek(TimeCurrent())==4 && trade_Thursday==false)return;
   if(TimeDayOfWeek(TimeCurrent())==5 && trade_Friday==false)return;
   
   if(checkTimeFilter == 0)return;  // Rule 1
   if(checkDistance != 1)return;    // Rule 3  
   if(checkTrend != 1)return;       // Rule 2
   if(checkSignal != 1)return;      // Rule 2
   if(checkStrength != 1)return;    // Rule 5 - Check US500 and US30 for biggest mover
   flag_6B = 1;   
   if(relativeHigh > 0){
      AlertUser("Long Signal Detected - Rule6A",sendAlerts,sendEmails,sendNotification);
      flag_6B = 0;
      EnterLongFunction();
   }
}

void CheckEntryShort(){
   if(TimeDayOfWeek(TimeCurrent())==1 && trade_Monday==false)return;
   if(TimeDayOfWeek(TimeCurrent())==2 && trade_Tuesday==false)return;
   if(TimeDayOfWeek(TimeCurrent())==3 && trade_Wednesday==false)return;
   if(TimeDayOfWeek(TimeCurrent())==4 && trade_Thursday==false)return;
   if(TimeDayOfWeek(TimeCurrent())==5 && trade_Friday==false)return;
   
   if(checkTimeFilter == 0)return;  // Rule 1
   if(checkDistance != 1)return;    // Rule 3
   if(checkTrend != -1)return;      // Rule 2
   if(checkSignal != -1)return;     // Rule 2
   if(checkStrength != 1)return;    // Rule 5 - Check US500 and US30 for biggest mover
   flag_6B = -1;   
   if(relativeLow > 0){
      AlertUser("Short Signal Detected - Rule6A",sendAlerts,sendEmails,sendNotification);
      flag_6B = 0;
      EnterShortFunction();
   }
}

void GenerateComments(){
   string com = "";
   com+="\n=========================";
   com+="\n          TimeZone Settings";
   com+="\n=========================";
   com+="\n-TimeZone_1 [ " + (string)timeSlot_1_start +" - "+(string)timeSlot_1_end+" ]";
   com+="\n-TimeZone_2 [ " + (string)timeSlot_2_start +" - "+(string)timeSlot_2_end+" ]";
   com+="\n-TimeZone_3 [ " + (string)timeSlot_3_start +" - "+(string)timeSlot_3_end+" ]";
   com+="\n-TimeZone_4 [ " + (string)timeSlot_4_start +" - "+(string)timeSlot_4_end+" ]";
   com+="\n=========================";
   com+="\n          Previous Candle Variables";
   com+="\n=========================";
   
   com+="\n-candleTime = " + (string)rates[1].time;
   com+="\n-Time_Zone = " + IntegerToString(checkTimeFilter);
   com+="\n-Prev_Day_Close ==> " + DoubleToString(iClose(_Symbol,PERIOD_D1,1),_Digits);
   
   if(checkTrend == 1){com+="\n-Trend_Direction ==> Up";}
   else{com+="\n-Trend_Direction ==> Down";}
   
   com+="\n=========================";
   com+="\n-dailyMove_US30 = " + DoubleToString(dailyMove_US30,2);
   com+="\n-dailyMove_US500 = " + DoubleToString(dailyMove_US500,2);
   com+="\n-dailyMove_USTEC = " + DoubleToString(dailyMove_USTEC,2);   
   
   com+="\n=========================";   
   
   if(checkTimeFilter > 0){com+="\n-Rule1_TimeZone  ==>Pass";}
   else{com+="\n-Rule1_TimeZone  ==> Fail";} 
      
   if(checkTrend == 1){  
      if(checkSignal == 1){com+="\n-Rule2_Pattern     ==> Pass";}
      else{com+="\n-Rule2_Pattern     ==> Fail";}
   }
   
   if(checkTrend == -1){
      if(checkSignal == -1){com+="\n-Rule2_Pattern     ==> Pass";}
      else{com+="\n-Rule2_Pattern     ==> Fail";}
   }
      
   if(checkDistance == 1){com+="\n-Rule3_Distance    ==> Pass";}
   else{com+="\n-Rule3_Distance    ==> Fail";}
   
   if(checkStrength){com+="\n-Rule5_Strength   ==> Pass";}
   else{com+="\n-Rule5_Strength   ==> Fail";}
   
   if(checkTrend == 1 && checkSignal == 1){
      if(relativeHigh > 0){ com+="\n-Rule6A_RelativeHigh ==> Pass"; }
      else{
         com+="\n-Rule6A_RelativeHigh ==> Fail";
         if(flag_6B == 1)  com+="\n-Rule6B_Checking Next Candle";
      }
   }
   
   if(checkTrend == -1 && checkSignal == -1){
      if(relativeLow > 0){com+="\n-Rule6A_RelativeLow = Pass";}
      else{
         com+="\n-Rule6A_RelativeLow = Fail";
         if(flag_6B == -1)  com+="\n-Rule6B_Checking Next Candle";
      }
   }

   com+="\n=========================";
   Comment(com);
}
int CheckSignal(){
   if( rates[1].close > rates[1].open && rates[2].close < rates[2].open ){
      return(1);
   }  
   if( rates[1].close < rates[1].open && rates[2].close > rates[2].open ){
      return(-1);
   }  
   return(0);
}

int CheckStrength(string _symbol){
   if(strengthMode == ALL)return(1);
   if(strengthMode == STRONGEST){
      if(_symbol == USTEC_name && MathAbs(dailyMove_USTEC) > MathAbs(dailyMove_US30) && MathAbs(dailyMove_USTEC) > MathAbs(dailyMove_US500)) return(1);
      if(_symbol == US500_name && MathAbs(dailyMove_US500) > MathAbs(dailyMove_US30) && MathAbs(dailyMove_US500) > MathAbs(dailyMove_USTEC)) return(1);
      if(_symbol == US30_name  && MathAbs(dailyMove_US30) > MathAbs(dailyMove_US500) && MathAbs(dailyMove_US30) > MathAbs(dailyMove_USTEC)) return(1);
   }
   if(strengthMode == WEAKEST){
      if(_symbol == USTEC_name && MathAbs(dailyMove_USTEC) < MathAbs(dailyMove_US30) && MathAbs(dailyMove_USTEC) < MathAbs(dailyMove_US500)) return(1);
      if(_symbol == US500_name && MathAbs(dailyMove_US500) < MathAbs(dailyMove_US30) && MathAbs(dailyMove_US500) < MathAbs(dailyMove_USTEC)) return(1);
      if(_symbol == US30_name  && MathAbs(dailyMove_US30) < MathAbs(dailyMove_US500) && MathAbs(dailyMove_US30) < MathAbs(dailyMove_USTEC)) return(1);
   }   
   return(0);
}

double RelativeHigh(){
   for( int i = 2; i <= 99 ; i++ ){
      if( rates[i].close > rates[i].open ){
         if( rates[1].close > rates[i].close ){
            return((rates[1].close - rates[i].close));
         }
         else{
            return(0);
         }
      }
   }
   return(0);
}

double RelativeLow(){
   for( int i = 2; i <= 99 ; i++ ){
      if( rates[i].close < rates[i].open ){
         if( rates[1].close < rates[i].close ){
            return((rates[i].close - rates[1].close));
         }
         else{
            return(0);
         }
      }
   }
   return(0);
}

int CheckTrendDirection(){
   if(rates[1].close > prevDayClose)return(1);
   if(rates[1].close < prevDayClose)return(-1);
   return(0);
}

int CheckDistance(){
   double distance = 0;
   if(prevDayClose != 0){
      distance = MathAbs(rates[1].close - prevDayClose) / prevDayClose * 100;
   }
   if(distance <= maxDistancePct && distance >= minDistancePct){
      return(1);
   }
   return(0);
}

double DailyMove(string _symbol){
   double prevClose = 0, currentPrice = 0;
   prevClose = iClose(_symbol,PERIOD_D1,1);
   currentPrice = iClose(_symbol,timeFrame,1);
   if(prevClose != 0 && currentPrice != 0){
      return((currentPrice - prevClose)/prevClose *100);
   }
   return(0);
}

int CheckTimeFilter(){
   if(TimeCheck(timeSlot_1_start,timeSlot_1_end))return(1);
   if(TimeCheck(timeSlot_2_start,timeSlot_2_end))return(2);
   if(TimeCheck(timeSlot_3_start,timeSlot_3_end))return(3);
   if(TimeCheck(timeSlot_4_start,timeSlot_4_end))return(4);
   return(0);   
}

// This Function returns True when the Current Time is equal to or between the Start and Finish times
bool TimeCheck(int _start, int _finish){
   if(_start == 0 && _finish == 0)return(false);
   int currentTime = TimeConvert(rates[1].time);
   if( _start == 0 ) _start = 2400; 
   if( _finish == 0 ) _finish = 2400; 
   if( currentTime == 0 ) currentTime = 2400;

   if ( ( _start < _finish && ( currentTime < _start || currentTime > _finish )) || 
            ( _start > _finish && ( currentTime < _start && currentTime > _finish ) ) ){
      return(false);
   }
   return(true);   
}

double StopLoss_Long(){
   for( int i = 2; i <= 99 ; i++ ){
      if( rates[i].close < rates[i].open ){
         return(NormalizeDouble(MathMin(rates[i].low,rates[i-1].low) - StopLoss_Points * _Point,_Digits));
      }
   }
   return(0);   
}

double StopLoss_Short(){
   for( int i = 2; i <= 99 ; i++ ){
      if( rates[i].close > rates[i].open ){
         return(NormalizeDouble(MathMax(rates[i].high,rates[i-1].high) + StopLoss_Points * _Point,_Digits));
      }
   }
   return(0);   
}

void EnterLongFunction(){
//--- check for trade open or max trades per slot
   if(numOpenSymbol > 0) return;   
   if(flag_OpenTradeThisTimeSlot >= maxTradesPerTimeSlot){ 
      AlertUser("Max Trades per time slot reached",sendAlerts,sendEmails,sendNotification);
      return;
   }
      
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);   
   double stopLoss = StopLoss_Long();
   double stopLossGap = MathAbs(stopLoss - ask);
   double takeProfit = 0;
   
   //--- Check StopLoss Size and Cancel trade if too large
   if( stopLossGap > maximum_StopLoss*_Point ){
      AlertUser("StopLoss is too large - trade will not be taken",sendAlerts,sendEmails,sendNotification);
      return;
   }
   
   //--- Check Highly Reduced Risk Setting Conditions
   if( stopLossGap > HRR_StopLoss_Max*_Point ){
      takeProfit = ask + HRR_TakeProfit*0.01*stopLossGap;
      EnterLongPosition(_Symbol,HRR_PositionSize,ask,maxSlippage,stopLoss,takeProfit,magicNumber,"Highly Reduced Risk Entry");
      flag_OpenTradeThisTimeSlot += 1;
      return;
   }

//--- Check Reduced Risk Conditions
   if( stopLossGap < RR_StopLoss_Min*_Point || stopLossGap > RR_StopLoss_Max*_Point || relativeHigh < RR_Relative_Min*_Point ){
      if(stopLossGap < RR_StopLoss_Min*_Point)  AlertUser("Reduced Risk Entry - stopLoss < Minimum",sendAlerts,sendEmails,sendNotification);
      if(stopLossGap > RR_StopLoss_Max*_Point)  AlertUser("Reduced Risk Entry - stopLoss > Max",sendAlerts,sendEmails,sendNotification);
      if(relativeHigh < RR_Relative_Min*_Point) AlertUser("Reduced Risk Entry - relativeHigh < Minimum",sendAlerts,sendEmails,sendNotification);     
      takeProfit = ask + RR_TakeProfit*0.01*stopLossGap;
      EnterLongPosition(_Symbol,RR_PositionSize,ask,maxSlippage,stopLoss,takeProfit,magicNumber,"Reduced Risk Entry");
      flag_OpenTradeThisTimeSlot += 1;
      return;   
   }
//--- Use Normal Entry Settings
   AlertUser("Normal Entry",sendAlerts,sendEmails,sendNotification);
   takeProfit = ask + Normal_TakeProfit*0.01*stopLossGap;
   EnterLongPosition(_Symbol,Normal_PositionSize,ask,maxSlippage,stopLoss,takeProfit,magicNumber,"Normal Entry");
   flag_OpenTradeThisTimeSlot += 1;
   return; 
}

void EnterShortFunction(){
//--- check for trade open or max trades per slot
   if(numOpenSymbol > 0) return;   
   if(flag_OpenTradeThisTimeSlot >= maxTradesPerTimeSlot){ 
      AlertUser("Max Trades per time slot reached",sendAlerts,sendEmails,sendNotification);
      return;
   }
    
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_ASK);   
   double stopLoss = StopLoss_Short();
   double stopLossGap = MathAbs(stopLoss - bid);
   double takeProfit = 0;
   
   //--- Check StopLoss Size and Cancel trade if too large
   if( stopLossGap > maximum_StopLoss*_Point ){
      AlertUser("StopLoss is too large - trade will not be taken",sendAlerts,sendEmails,sendNotification);
      return;
   }
   
   //--- Check Highly Reduced Risk Setting Conditions
   if( stopLossGap > HRR_StopLoss_Max*_Point ){
      takeProfit = bid - HRR_TakeProfit*0.01*stopLossGap;
      EnterShortPosition(_Symbol,HRR_PositionSize,bid,maxSlippage,stopLoss,takeProfit,magicNumber,"Highly Reduced Risk Entry");
      flag_OpenTradeThisTimeSlot += 1;
      return;
   }

//--- Check Reduced Risk Conditions
   if( stopLossGap < RR_StopLoss_Min*_Point || stopLossGap > RR_StopLoss_Max*_Point || relativeLow < RR_Relative_Min*_Point ){
      if(stopLossGap < RR_StopLoss_Min*_Point)  AlertUser("Reduced Risk Entry - stopLoss < Minimum",sendAlerts,sendEmails,sendNotification);
      if(stopLossGap > RR_StopLoss_Max*_Point)  AlertUser("Reduced Risk Entry - stopLoss > Max",sendAlerts,sendEmails,sendNotification);
      if(relativeHigh < RR_Relative_Min*_Point) AlertUser("Reduced Risk Entry - relativeLow < Minimum",sendAlerts,sendEmails,sendNotification);     
      takeProfit = bid - RR_TakeProfit*0.01*stopLossGap;
      EnterShortPosition(_Symbol,RR_PositionSize,bid,maxSlippage,stopLoss,takeProfit,magicNumber,"Reduced Risk Entry");
      flag_OpenTradeThisTimeSlot += 1;
      return;   
   }
//--- Use Normal Entry Settings
   AlertUser("Normal Entry",sendAlerts,sendEmails,sendNotification);
   takeProfit = bid - Normal_TakeProfit*0.01*stopLossGap;
   EnterShortPosition(_Symbol,Normal_PositionSize,bid,maxSlippage,stopLoss,takeProfit,magicNumber,"Normal Entry");
   flag_OpenTradeThisTimeSlot += 1;
   return; 
}

////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+//
//|                     my Include Functions                         |//
//+------------------------------------------------------------------+//  
////////////////////////////////////////////////////////////////////////

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

int TimeConvert( datetime time )
{
   int value = TimeHour(time)*100 + TimeMinute(time);
   return(value);
}

void SendEmail( string _expertName, string _message )
{        
   string subject = StringConcatenate(
      "\n", _expertName, Symbol()
   );
   
   string body = StringConcatenate(subject,"\n",_message);
   SendMail(subject,body);
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

bool EnterLongPosition( string _symbol, double _lots, double _price, int _slippage, double _stopLoss, double _takeProfit, int _magicNumber, string _label )
{
   double lots = RoundVolume( _symbol, _lots );
   double entry_price = RoundPrice(_symbol, _price );   
   double stoploss = RoundPrice( _symbol, _stopLoss  );
   double takeprofit = RoundPrice( _symbol, _takeProfit);
  
   RefreshRates();
   
   if( OrderType() == OP_BUY ) _price = MarketInfo(_symbol,MODE_ASK);
   if( OrderType() == OP_SELL) _price = MarketInfo(_symbol,MODE_BID);

   if( !OrderSend( _symbol, ORDER_TYPE_BUY, _lots, _price, _slippage, stoploss, takeprofit, _label, _magicNumber, 0, Green ) )
   {
     ErrorReport( GetLastError() );
     return(false);
   }
   return(true);
}

bool EnterShortPosition( string _symbol, double _lots, double _price, int _slippage, double _stopLoss, double _takeProfit, int _magicNumber, string _label )
{
   double lots = RoundVolume( _symbol, _lots );
   double entry_price = RoundPrice(_symbol, _price );   
   double stoploss = RoundPrice( _symbol, _stopLoss  );
   double takeprofit = RoundPrice( _symbol, _takeProfit);
  
   RefreshRates();
   
   if( OrderType() == OP_BUY ) _price = MarketInfo(_symbol,MODE_ASK);
   if( OrderType() == OP_SELL) _price = MarketInfo(_symbol,MODE_BID);

   if( !OrderSend( _symbol, ORDER_TYPE_SELL, _lots, _price, _slippage, stoploss, takeprofit, _label, _magicNumber, 0, Green ) )
   {
     ErrorReport( GetLastError() );
     return(false);
   }
   return(true);
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