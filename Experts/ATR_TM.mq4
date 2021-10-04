// +=================================================================================================================+
// |                                                                                        ATR Trade Manager EA.mq4 |
// |                                                                                           Release Ver. 09032012 |
// |     ****  Use at your own risk  ****                                                                            |
// |                                                                                           by Plainkoi@yahoo.com |
// |                                                                      Considerable contributions by Bubo of FXAW |
// +=================================================================================================================+

#define        SIGNAL_NONE          0
#define        SIGNAL_BUY           1
#define        SIGNAL_SELL          2
#define        SIGNAL_CLOSEBUY      3
#define        SIGNAL_CLOSESELL     4

extern string	ATR_TM_EA            = "========= ATR Trade Manager EA =========";
string	Manual_Comments      = "To manage by Comments, manual entry must match Comments, else leave blank";
string  Comments             = "";
extern int     ATRPeriod            = 14;
extern int     Primary_TF           = 1440;
extern double  RiskPercent          = 5;
int     Scale_In_Intervals   = 2;                                          // 1 Period ATR divided by this number.
string	ATR_Exit_Settings    = "--- Standard iATR - SL / TS /TP Settings ---";
       bool    Use_ATR_Function     = True;
       double  ATR_SL_Divider       = 0.0;  double ATR_SL_Multiplier = 1.75; // Stop Loss - Divider Ex: 2 = 50% of ATR, 4 = 25%, etc...
       double  ATR_TS_Divider       = 0.0;  double ATR_TS_Multiplier = 1.75; // Trailing Stop - Divider Ex: 2 = 50% of ATR, 4 = 25%, etc...
       double  ATR_TP_Divider       = 0.0;  double ATR_TP_Multiplier = 4.77; // Take Profit - Divider Ex: 2 = 50% of ATR, 4 = 25%, etc...

extern bool    EachTickMode         = False;

int            BarCount, Current, Shift = 1;                                                
bool           TickCheck = False;
datetime 	   Prior_TF_Bar_Time;
double         spread, point, SwapL, SwapS, GetLots;
bool select, close, modif;

// +------------------------------------------------------------------+
// |                                                                  |
// +------------------------------------------------------------------+                 
                                                                              
   int init()
      {
      BarCount = Bars; if (EachTickMode) Current = 0; else Current = 1;
    
      return(0);
      }
      
// +------------------------------------------------------------------+
// | expert deinitialization function                                 |
// +------------------------------------------------------------------+
   
   int deinit()
      {
      return(0);
      }
      
// +------------------------------------------------------------------+
// | expert start function                                            |
// +------------------------------------------------------------------+

   int start()

{      int Order = SIGNAL_NONE, Total;
   
         if (EachTickMode && Bars != BarCount) {TickCheck = False;}
            Total = OrdersTotal(); Order = SIGNAL_NONE;
      
      double Spread = MarketInfo(Symbol(),MODE_SPREAD);


   // START ATR Exit Functions / MM Calculations *************************************************************
   
      double ATRV, ATRTS, ATRSL, ATRTP;
      double ATR = MathMax (NormalizeDouble(iATR(Symbol(),Primary_TF,ATRPeriod,1),Digits),Point);
   
      int Multiplier = 0;
         if (Digits == 2) Multiplier = 10; 
         if (Digits == 3) Multiplier = 100;
         if (Digits == 4) Multiplier = 1000;
         if (Digits == 5) Multiplier = 10000;
         if (Digits == 6) Multiplier = 100000;
   
         ATRV  = (ATR * Multiplier);

         if (ATR_SL_Multiplier > 0) ATRSL = (ATRV * ATR_SL_Multiplier) + Spread;
         if (ATR_TS_Multiplier > 0) ATRTS = (ATRV * ATR_TS_Multiplier);
         if (ATR_TP_Multiplier > 0) ATRTP = (ATRV * ATR_TP_Multiplier) + Spread;
   
      double   MSL, MTS, MTP, SL, TS, TP;  //Stands for Modified.
   
         if (Use_ATR_Function == True)
            {
            SL = (ATRSL); MSL = (ATRSL / Multiplier);
            TS = (ATRTS); MTS = (ATRTS / Multiplier);
            TP = (ATRTP); MTP = (ATRTP / Multiplier);
            }
   
   // Risk Money Management Funtion -------------------------------------------------------

      double   Risk             = (AccountBalance() * (RiskPercent / 100));
      double   PipValue         = (Risk / SL);   
      double   NominalPipValue  = (MarketInfo(Symbol(), MODE_TICKVALUE) / MarketInfo(Symbol(), MODE_TICKSIZE) / Multiplier);
      double   Lot              = (PipValue / NominalPipValue);
      double   FullSL           = (SL * PipValue), FullTP = (TP * PipValue);
   
   // Open Order Reference Check ------------------------------------------------------------   
      
      double   Fl_Pip, Sum_Profit;
      bool     IsOrder = False, BuyOpenOrder = False, SellOpenOrder = False;

   for(int cnt=OrdersTotal()-1; cnt>=0; cnt--)
      {
      select = OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if (
         (OrderType() == OP_BUY || OrderType() == OP_SELL) && OrderSymbol() == Symbol() && OrderComment() == Comments)

         {//now start adding the profits
         Sum_Profit = (Sum_Profit + OrderProfit() + OrderSwap());
      
      // Pair floating pips.
         Fl_Pip = ((Sum_Profit / Lot) / 10);
         Fl_Pip = ((Sum_Profit / Lot) / 10);         
          
      // Is there an open order - Determine if open lot size.
         if (OrderLots() >= 0.01) IsOrder = True;
         if (OrderLots() >= 0.01) IsOrder = True;
      
      // Lot Size of open order or calculated position size.
         if (IsOrder == True)  {Lot = OrderLots();}
         if (IsOrder == False) {Lot = (PipValue / NominalPipValue);}

         }
      }
      // end orderselect
      
    
      // END ATR Exit Functions / MM Calculations ***************************************************************
   
    
  //Prior_TF_Bar_Time
 
            
      // END SL / TP Lines --------------------------------------------------------------------

      // Get Lots Total  ----------------------------------------------------------------------                                                 |

  
   double lots_total=0;
   for(int ia=0;ia<OrdersTotal();ia++)
     {
      if(OrderSelect(ia,SELECT_BY_POS,MODE_TRADES)==true)
        {
         //if(OrderMagicNumber()==MagicNumber)
           {
            if(OrderSymbol()==Symbol())
              {
               lots_total=lots_total+OrderLots();
              }
           }
        }
     }
  // return(lots_total);
  

      // Display Comments ---------------------------------------------------------------------
      
         {
         Comment
         ("\n",
         "\n",
         "\n","                      ================================",
         "\n","                      ================================",
         "\n","                      ================================",
         "\n",
         "\n","                      ============ Lot : " + DoubleToStr(Lot,2), ""," =============",
         "\n",   
         "\n","                      ================================",
         "\n","                      ================================",
         "\n","                      ================================");
         
         
         }

      // --------------------------------------------------------------------------------------------------------
   
      //Check position
      bool IsTrade = False;

      for(int i=0;i<OrdersTotal();i++) 
      {
         select = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if(OrderType() <= OP_SELL &&  OrderSymbol() == Symbol()) {
         IsTrade = True;
         if(OrderType() == OP_BUY) {
            //Close

            //+------------------------------------------------------------------+
            //| Signal Begin(Exit Buy)                                           |
            //+------------------------------------------------------------------+

              if (OrderProfit() == FullSL) Order = SIGNAL_CLOSEBUY;
              //if (  ) Order = SIGNAL_CLOSEBUY;

            //+------------------------------------------------------------------+
            //| Signal End(Exit Buy)                                             |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSEBUY && ((EachTickMode && !TickCheck) || (!EachTickMode && (Bars != BarCount)))) {
               close = OrderClose(OrderTicket(), OrderLots(), Bid, 0, MediumSeaGreen);
               if (!EachTickMode) BarCount = Bars;
               IsTrade = False;
               continue;
            }
            //ATR Trailing stop
            if (ATRTS > 0 && OrderComment() == Comments) {                 
               if(Bid - OrderOpenPrice() > MTS) {
                  if(OrderStopLoss() < Bid - MTS) {
                     modif = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - MTS, OrderTakeProfit(), 0, MediumSeaGreen);
                     if (!EachTickMode) BarCount = Bars;
                     continue;
                  }
               }
            }
        } else {
            //Close

            //+------------------------------------------------------------------+
            //| Signal Begin(Exit Sell)                                          |
            //+------------------------------------------------------------------+

              if (OrderProfit() == FullSL) Order = SIGNAL_CLOSESELL;
              //if (  ) Order = SIGNAL_CLOSESELL;

            //+------------------------------------------------------------------+
            //| Signal End(Exit Sell)                                            |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSESELL && ((EachTickMode && !TickCheck) || (!EachTickMode && (Bars != BarCount)))) {
               close = OrderClose(OrderTicket(), OrderLots(), Ask, 0, DarkOrange);
               if (!EachTickMode) BarCount = Bars;
               IsTrade = False;
               continue;
            }
            //ATR Trailing stop
            if(ATRTS > 0 && OrderComment() == Comments) {                 
               if(OrderOpenPrice() - Ask > MTS) {
                  if(OrderStopLoss() > Ask + MTS) {
                     modif = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + MTS, OrderTakeProfit(), 0, DarkOrange);
                     if (!EachTickMode) BarCount = Bars;
                     continue;
                  }
               }
            }            
         }
      }
   }

   for (i = OrdersTotal()-1; i>=0; i--) {
      select = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      //Buy TP / SL Modification
         if (
         OrderType()==OP_BUY &&
         OrderSymbol()==Symbol() && (OrderStopLoss()==0 || OrderTakeProfit()==0) && OrderComment() == Comments
            )
		      {
			while (!IsTradeAllowed()) Sleep(300);
            modif = OrderModify(OrderTicket(),OrderOpenPrice(), Bid - MSL, Ask + MTP, 0, Aqua);
            Print(Symbol(),"BUY order, adjusted to ",OrderOpenPrice(),", ",0,", ",MTP);
            return(0);
            }
   
      //Sell TP / SL Modification
         if (
         OrderType()==OP_SELL &&
         OrderSymbol()==Symbol() && (OrderStopLoss()==0 || OrderTakeProfit()==0) && OrderComment() == Comments
            )
		      {
         while (!IsTradeAllowed()) Sleep(300);
            modif = OrderModify(OrderTicket(),OrderOpenPrice(), Ask + MSL, Bid - MTP, 0, Red);
            Print(Symbol(),"SELL order, adjusted to ",OrderOpenPrice(),", ",0,", ",MTP);
            return(0);
            }
            }
   if (!EachTickMode) BarCount = Bars;

   return(0);
}
//+------------------------------------------------------------------+