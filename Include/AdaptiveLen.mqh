//+------------------------------------------------------------------+
//|                                                  AdaptiveLen.mqh |
//|                              Copyright © 2014 Adaptrade Software |
//|                                         http://www.Adaptrade.com |
//+------------------------------------------------------------------+
#property copyright   "2014, Adaptrade Software"
#property link        "http://www.Adaptrade.com"

int AdaptiveLen(const int rates_total, const int prev_calculated, const double& price[],
                double& PrSm[], const int Len, const int MaxLen, const double TrParam, 
                double& res[])
// 
// Adaptive Length function. Used in the calculation of adaptive indicators, such as AdaptiveVMA.
//  In Tushar Chande's VIDYA indicator, the smoothing constant (alpha) adapts to
//  market volatility or trend strength. In Chande's version, the effective period
//  of the moving average decreases with the trend strength so that highly trending
//  markets have a short moving average period and sideways or choppy markets have
//  a long period moving average.
//  
//  This function provides a similarly adaptive look-back length but adds an extra input, 
//  TrParam, which can be used to change the relationship between trend and period
//  length. Positive values of TrParam give the same relationship as in Chande's VIDYA, 
//  where a TrParam of 1 is similar to the relationship in VIDYA. Negative values of 
//  TrParam reverse the relationship, so that the period increases with the trend 
//  strength and decreases with flat or trendless markets. A TrParam of zero returns
//  the input value Length. Reasonable values of TrParam are between roughly -5 and +5.
// 
//  Trend strength is based on the efficiency ratio. The calculated look-back length is 
//  limited to the value of input MaxLen.
//
{
   int MinBack = Len + 6;
   
   if (Len < 1 || rates_total < MinBack)
       return (0);
            
   // Set starting bar for calculations
   int i, j, istart;
   
   if (prev_calculated <= 0) {  // First calculation or number of bars was changed
       istart = MinBack;
              
       PrSm[0] = price[0];
       for (i = 1; i < 4; i++)
           PrSm[i] = price[i - 1];

       for (i = 4; i < istart; i++)
           PrSm[i] = (price[i - 1] + 2 * price[i - 2] + 2 * price[i - 3] + price[i - 4])/6.;
           
       for (i = 0; i < istart; i++)
           res[i] = Len;
   }
   else
       istart = prev_calculated;
    
   // Main calculations
   double NetChg, SumChg, EffRatio, Alpha, AdaptAlpha, VER;
   int VLength;
   
   Alpha = 2./(Len + 1);
   
   for (i = istart; i < rates_total; i++) {

       // Smoothed price
       PrSm[i] = (price[i - 1] + 2 * price[i - 2] + 2 * price[i - 3] + price[i - 4])/6.;
       
       // Efficiency ratio
       NetChg = fabs(PrSm[i] - PrSm[i - Len]);
       SumChg = 0;
       for (j = 0; j < Len; j++)
           SumChg += fabs(PrSm[i - j] - PrSm[i - j - 1]);

       if (SumChg > 0)
           EffRatio = NetChg/SumChg;
       else
           EffRatio = 0;
           
        // Variable length
        VER = MathPow((EffRatio - (2 * EffRatio - 1)/2. * (1 - TrParam) + 0.5), 2.); 
        AdaptAlpha = Alpha * VER;             // Variable adaptive smoothing factor
           
        if (AdaptAlpha > 0) {
            VLength = (int)(2./AdaptAlpha - 1);
            VLength = MathMin(VLength, MaxLen);      // Limit length to MaxLength
            VLength = MathMax(VLength, 1);           // Length must be at least 1
        }
        else
            VLength = MaxLen;

        res[i] = VLength;
   }
          
   return(rates_total);
}