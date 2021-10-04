//+------------------------------------------------------------------+
//|                                              sharesWatchlist.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

string FOREX[] =        
{ 
   "AUDUSD","AUDNZD","AUDCHF","AUDJPY","CADCHF","CADJPY","CHFJPY","USDJPY","GBPUSD","GBPNZD","EURGBP","EURUSD","NZDUSD","NZDJPY","EURCHF","USDCHF"                     
}; 

string INDICIES[] =        
{ 
   "DAX30","CAC40","SMI20","UK100","ESX50","SP500","WS30","NAS100","AUS200","ESP35","HK50","JPN225","IBX35F6"                         
}; 

string COMMODITIES[] =        
{ 
   "GOLD","SILVER","BRENT","WTI"
};


//FxPro Shares
string FXPRO_ALL[] =
{
"#21stFOX","#3I","#3M","#A.X.A","#Ab&Fitch","#Adidas","#Adobe","#AIG","#AirbusGr","#Airfrance","#Alcoa","#Alibaba","#Allianz","#AltriaGrp","#Amazon","#AmericanEx",
"#Apple","#AT&T","#Aviva","#B.M.W","#B.P.","#BAESystems","#Baidu","#Barclays","#BarratsDev","#BASFN","#Bayer","#Billiton","#BNPParibas","#Boeing","#BofAmerica",
"#BristlMyer","#BTelecom","#Burberry","#Carrefour","#Caterpilar","#Chevron","#ChinaMobil","#Cisco","#Citigroup","#CocaCola","#Colg-Palm","#Comcast",
"#Commerzbnk","#ConPhillip","#Costco","#CrAgricole","#Daimler","#Danone","#DeutscBank","#DeutscPost","#Disney","#E.bay","#E.ON","#Easyjet","#ExxonMobil","#Facebook",
"#FedEx","#Ferrari","#Ford","#GenElec","#GenMotors","#GlaxoSmitK","#Glencore","#GoldmSachs","#Google","#Groupon","#Haliburton","#HarleyDav","#HomeDepot","#Honeywell",
"#HPackard","#HSBC","#IBM","#Intel","#J&J","#JPMorgan","#KraftHeinz","#L.V.Sands","#LloydsTSB","#LondonExch","#LOreal","#LouVuitton","#Lufthansa","#M.Stanley",
"#ManGroup","#Mastercard","#McDonalds","#MerkCo","#MGMResorts","#Microsoft","#Mondelez","#MoodysCorp","#Motorola","#Netflix","#NewsCorp","#Next","#Nike","#Novartis",
"#Nvidia","#Oracle","#Orange","#P&G","#Pepsico","#PetroleoBr","#Peugeot","#Pfizer","#PhilMorris","#Prudential","#PUMA","#Qualcomm","#R.B.S","#RalpLauren","#Renault",
"#RioTinto","#RollsRoyce","#S.A.P","#Sainsburys","#Schwabb","#ShakeShack","#Shell","#Siemens","#SocGeneral","#Sony","#SportDirct","#Sprint","#StanLife","#Starbucks",
"#StdCharter","#Symantec","#Tesco","#TeslaMotor","#Tiffanys","#TimeWarner","#Total","#Toyota","#Travelers","#TrpAdvisor","#Twitter","#U.P.S","#Unilever","#UnitedTech",
"#Vale","#Verizon","#Visa","#Vivendi","#Vodafone","#Volkswagen","#Walmart","#WellFargo","#WestUnion","#Y.E.L.P","#Yandex","#YumFoods","#Zynga"

};


// JFD Shares
string JFD_ALL[] =
{
"AA","AAL.L","AAPL","ABT","ACA.P","ADBE","ADM.L","ADS.D","AEP","AET","AF.P","AGK.L","AGN.A","AH.A","AHT.L","AIG","AIR.P","AIRG.D","AIRP.P","AIXA.D",
"AKAM","ALB","ALV.D","AMA.MC","AMAT","AMD","AMGN","AMZN","AN","ANF","ANTO.L","AOBC","APA","ARL.D","ASML.A","ATST.L","ATVI","AUTOA.L","AV.L","AVGO",
"AVP","AXP","AZN.L","AZO","BA","BA.L","BABA","BAC","BAS.D","BATS.L","BAYN.D","BB","BBBY","BBVA.MC","BDEV.L","BEI.D","BIDU","BIIB","BION.D","BITA",
"BK","BKNG","BLK","BLND.L","BLT.L","BMW.D","BMY","BNP.P","BNRG.D","BOLL.P","BOS3.D","BP.L","BRKb","BSTI","BSX","BT.L","BXP","C","CAP.P","CAT","CBK.D",
"CCE","CCL","CCL.L","CELG","CHRW","CI","CIEN","CL","CLDR","CMCSK","CME","CMG","CNA.L","CNP","CONT.D","COP","COST","CPI.L","CS.P","CSCO","CSX","CTAS",
"CTSH","CTXS","CVS","CVX","DAI.D","DAL","DANO.P","DB","DB1.D","DBK.D","DE","DEZG.D","DG","DGX","DIDA.MC","DIOR.P","DIS","DISCA","DISH","DLGS.D","DPW.D",
"DSM.A","DTE","DTE.D","DUK","DVN","DWDP","EA","EBAY","EDF.P","EEM.L","EFA.L","EMG.L","EMR","EN.P","EOAN.D","EPED.P","ESRX","EWT.L","EWY.L","EXC","EXPD",
"EXPE","EZJ.L","F","FAST","FB","FCAU","FDX","FISV","FITB","FME.D","FNAC.P","FNTG.D","FP.P","FPEG.D","FRAG.D","FRE.D","FSLR","FUR.A","FXI.L","G1A.D",
"GBFG.D","GD","GE","GENE.L","GFS.L","GGAL","GILD","GILG.D","GKN.L","GLE.P","GM","GNC.L","GOOG","GRLS.MC","GS","GSG.L","GSK.L","GWPH","HAL","HAYS.L",
"HD","HDDG.D","HEI.D","HEIA.A","HEN3.D","HMSO.L","HNRG.D","HOG","HOTG.D","HPQ","HSBA.L","IBB.OQ","IBE.MC","IBM","ICAD.P","ICE","ICP.L","IFX.D","ILD.P",
"IMI.L","INGA.A","INTC","INTU","INTUP.L","IP","ISRG","ITV.L","IVV.L","IXC.L","IYR.L","JAG","JNJ","JPM","JUP.L","KCOG.D","KGF.L","KHC","KLAC","KO","KPN.A",
"KRNG.D","LEOG.D","LGEN.L","LHA.D","LIN.D","LLOY.L","LMT","LSE.L","LVMH.P","LVS","LXSG.D","MA","MANG.D","MAR","MAT","MCD","MCO","MDLZ","MDT","MGGT.L",
"MKS.L","ML.P","MMM","MO","MON","MORG.D","MRK.D","MRO","MRW.L","MS","MSFT","MSI","MT","MTXG.D","MU","MUV2.D","NDA.D","NDAQ","NDX1.D","NEE","NEM","NEX.L",
"NFLX","NG.L","NKE","NOK","NTAP","NTRS","NUS","NVDA","NVS","NXT.L","OML.L","OR.P","ORAN.P","ORCL","OXY","PAYX","PCAR","PCG","PCLN","PEP","PFC.L","PFE",
"PG","PM","PRU","PRU.L","PSHG.D","PSMG.D","PTEC.L","PUB.P","PV.D","PYPL","QCOM","QGEN.D","QQQ.L","QSCG.D","RACE","RB.L","RBS.L","RCOP.P","RDSA.A","RDSA.L",
"REE.MC","REGN","REP.MC","RHKG.D","RHMG.D","RI.P","RIG","RL","RNO.P","ROK","ROST","RR.L","RRS.L","RSA.L","RTN","RWE.D","RYAAY","SAN.MC","SAP.D","SBRY.L",
"SBUX","SDF.D","SGCG.D","SGE.L","SHP.L","SIE.D","SIG","SIRI","SKYB.L","SLB","SMH.D","SN.L","SNAP","SOW.D","SPRG.D","SPY.L","SRP.L","SSE.L","STAG.D","STAN.L",
"STI","STM.P","STX","SU.P","SY1G.D","SYMC","SYY","SZGG.D","SZUG.D","T","TALK.L","TCG.L","TEF","TEVA","TIF","TKA.D","TLW.L","TPK.L","TPR","TRCO","TRP","TRV",
"TRVG","TSLA","TSO","TUIG.D","TWTR","TWX","TXN","UA","UAL","UBIP.P","UG.P","ULTA","ULVR.L","UNH","UNI.D","UNP","UPS","USB","UTDI.D","UTX","UU.L","V","VK.P",
"VLO","VOD.L","VOW.D","VOW3.D","VRSN","VRTX","VXX.L","VXZ.L","VZ","WCH.D","WDIG.D","WFC","WHA.A","WHR","WING.D","WKL.A","WMH.L","WMT","WPP.L","WTB.L","WU",
"WYNN","X","XIV.L","XLNX","XOM","XRAY","XRX","YUM","ZALn.D","ZILG.D","ZTO"

};

// JFD US Shares
string JFD_US[] =
{
 "AA","AAPL","ABT","ADBE","AEP","AET","AIG","AKAM","AMAT","AMD","AMGN","AMZN","AN","ANF","AOBC","APA","ATVI","AVP","AXP","AZO","BA","BABA","BAC","BBBY",
 "BBRY","BIDU","BIIB","BITA","BK","BLK","BMY","BSX","BXP","C","CAT","CCE","CCL","CELG","CHRW","CI","CIEN","CL","CMCSK","CME","CMG","CNP","COH","COP","COST",
 "CSCO","CSX","CTAS","CTSH","CTXS","CVS","CVX","DAL","DB","DD","DE","DG","DGX","DIS","DISCA","DISH","DOW","DTE","DUK","DVN","EA","EBAY","EMR","ESRX","EXC",
 "EXPD","EXPE","F","FAST","FB","FCAU","FDX","FISV","FITB","FSLR","GD","GE","GGAL","GILD","GM","GOOG","GOOGC","GS","HAL","HD","HOG","HPQ","IBM","ICE","INTC",
 "INTU","IP","ISRG","JAG","JNJ","JPM","KLAC","KO","LMT","LVS","MA","MAR","MAT","MCD","MCO","MDT","MMM","MO","MON","MRO","MS","MSFT","MSI","MT","NEE","NEM",
 "NFLX","NKE","NOK","NTAP","NTRS","NUS","NVDA","ORCL","OXY","PAYX","PCAR","PCLN","PEP","PFE","PG","PM","PRU","PYPL","QCOM","RACE","REGN","RIG","RL","ROK",
 "ROST","SBUX","SIG","SIRI","SLB","SNAP","SPLS","STI","STX","SYMC","SYY","T","TEF","TEVA","TIF","TRCO","TRP","TRVG","TRYJPY","TSLA","TSO","TWX","TXN","UA",
 "UAL","ULTA","UNH","UNP","UPS","USB","UTX","V","VLO","VRSN","VRTX","VZ","WFC","WFM","WHR","WMT","WU","WYNN","X","XLNX","XOM","XRAY","XRX","YHOO","YUM","ZTO"
};

// JFD UK Shares
string JFD_UK[] =
{
 "AAL.L","ADM.L","ADN.L","AGK.L","AHT.L","ANTO.L","ASL.L","ATST.L","AUTOA.L","AV.L","AVV.L","AZN.L","BA.L","BAB.L","BATS.L","BDEV.L","BLND.L","BLT.L",
 "BNZL.L","BP.L","BT.L","BWY.L","CCL.L","CNA.L","CPI.L","DFSD.L","DIA.L","EEM.L","EFA.L","EMG.L","EPP.L","EWT.L","EWY.L","EWZ.L","EZJ.L","FCPT.L","FXI.L",
 "GENE.L","GFS.L","GKN.L","GNC.L","GPOR.L","GSG.L","GSK.L","HAYS.L","HDB.L","HMC.L","HMSO.L","HSBA.L","ICP.L","IMI.L","INF.L","INTUP.L","INVP.L","ITV.L",
 "IVV.L","IXC.L","IYR.L","JMG.L","JUP.L","KGF.L","LAD.L","LAND.L","LGEN.L","LLOY.L","LSE.L","MGGT.L","MKS.L","MRCM.L","MRW.L","NEX.L","NG.L","NOGN.L","NXT.L",
 "OML.L","PAYP.L","PFC.L","PRU.L","PSN.L","PSON.L","PTEC.L","PTR.L","QQQ.L","RB.L","RBS.L","RDSA.L","RDSB.L","RR.L","RRS.L","RSA.L","SBRY.L","SDR.L","SGE.L",
 "SHP.L","SKYB.L","SMIN.L","SN.L","SNE.L","SPY.L","SRP.L","SSE.L","STAN.L","SVT.L","TALK.L","TCG.L","TEM.L","TLW.L","TM.L","TPK.L","ULVR.L","UU.L","VED.L",
 "VOD.L","VTI.L","VXX.L","VXZ.L","WEIR.L","WG.L","WMH.L","WOS.L","WPP.L","WTB.L","XIV.L","ZIV.L"

};

// JFD EU Shares
string JFD_EU[] =
{
"AGN.A","AH.A","AKZA.A","ASML.A","DSM.A","FUR.A","HEIA.A","INGA.A","KPN.A","PHIA.A","RAND.A","RDSA.A","SBMO.A","TOM2.A","UNA.A","WHA.A","WKL.A","ADS.D",
"AIRG.D","AIXA.D","ALV.D","ARL.D","BAS.D","BAYN.D","BEI.D","BION.D","BMW.D","BNRG.D","BOS3.D","CBK.D","CONT.D","DAI.D","DB1.D","DBK.D","DEZG.D","DLGS.D",
"DPW.D","DTE.D","EOAN.D","FME.D","FNTG.D","FPEG.D","FRAG.D","FRE.D","G1A.D","GBFG.D","GILG.D","HDDG.D","HEI.D","HEN3.D","HNRG.D","HOTG.D","IFX.D","KCOG.D",
"KRNG.D","LEOG.D","LHA.D","LIN.D","LXSG.D","MANG.D","MEOG.D","MORG.D","MRK.D","MTXG.D","MUV2.D","NDA.D","NDX1.D","PSHG.D","PSMG.D","PV.D","QGEN.D",
"QSCG.D","RHKG.D","RHMG.D","RWE.D","SAP.D","SDF.D","SGCG.D","SIE.D","SMH.D","SOW.D","SPRG.D","STAG.D","SY1G.D","SZGG.D","SZUG.D","TKA.D","TUIG.D","UNI.D",
"UTDI.D","VOW.D","VOW3.D","WCH.D","WDIG.D","WING.D","ZALn.D","ZILG.D","ABE.MC","ACS.MC","ACX.MC","AENA.MC","AMA.MC","ANA.MC","BBVA.MC","BKIA.MC","BKT.MC",
"CABK.MC","CLNX.MC","DIDA.MC","ELE.MC","ENAG.MC","FER.MC","GAM.MC","GAS.MC","GRLS.MC","IBE.MC","ICAG.MC","IDR.MC","ITX.MC","MAP.MC","MEL.MC","MRL.MC",
"MTS.MC","POP.MC","REE.MC","REP.MC","SABE.MC","SAN.MC","TEF.MC","TL5.MC","TRE.MC","VIS.MC","AC.P","ACA.P","AF.P","AIR.P","AIRP.P","AKE.P","ALO.P","BNP.P",
"BOLL.P","BVI.P","CA.P","CAP.P","CASP.P","CS.P","DANO.P","DAST.P","DG.P","DIOR.P","EDEN.P","EDF.P","EI.P","EN.P","EPED.P","FNAC.P","FOUG.P","FP.P","GLE.P",
"HRMS.P","ICAD.P","ILD.P","JCDX.P","KN.P","LAGA.P","LEGD.P","LVMH.P","MAUP.P","ML.P","OR.P","ORAN.P","PLOF.P","PRTP.P","PUB.P","RCOP.P","RI.P","RNO.P",
"SAF.P","SAN.P","SEV.P","SGO.P","STM.P","SU.P","TCFP.P","TCH.P","UBIP.P","UG.P","VCTP.P","VIE.P","VIV.P","VK.P","ZODC.P","ABBN.Z","ADEN.Z","ATLN.Z","BAER.Z",
"CFR.Z","CSGN.Z","GEBN.Z","GIVN.Z","LHN.Z","NESN.Z","NOVN.Z","ROG.Z","SCMN.Z","SGSN.Z","SLHN.Z","SREN.Z","SYNN.Z","UBSG.Z","UHRN.Z","ZURN.Z"

};

// JFD EU Shares
string FOREXTIME_ALL[] =
{
"#AABA","#AAL","#AAPL","#ABT","#ADBE","#AEO","#AGNC","#AIG","#AMAT","#AMGN","#AMZN","#APC","#ASNA","#ATVI","#AVGO","#AXP","#BABA","#BAC","#BBBY","#BHGE",
"#BIDU","#BK","#BP","#BSX","#BX","#C","#CA","#CAT","#CDNS","#CELG","#CFG","#CLR","#CNP","#COG","#COP","#COST","#CSCO","#CTRP","#CTSH","#CVS","#CVX","#CY",
"#DAL","#DIS","#DLTR","#DVN","#EA","#EBAY","#ENDP","#EPD","#ESRX","#ESV","#ETE","#ETP","#EXC","#F","#FB","#FIT","#FITB","#FLEX","#FOX","#FOXA","#FSLR",
"#GE","#GG","#GILD","#GLNG","#GLW","#GM","#GOOGL","#GPS","#HAL","#HBAN","#HLT","#HPQ","#HST","#HTZ","#HZNP","#INTC","#JBLU","#JD","#JNJ","#JNPR","#JPM",
"#KEY","#KHC","#KMI","#KO","#KR","#LC","#LULU","#LUV","#M","#MAT","#MCD","#MDLZ","#MDT","#MET","#MO","#MOS","#MPC","#MPLX","#MRK","#MRO","#MS","#MSFT",
"#MU","#MXIM","#MYL","#NAVI","#NE","#NEM","#NFLX","#NKE","#NOV","#NRG","#NTAP","#NUAN","#NVDA","#NWL","#NWSA","#ON","#ORCL","#OXY","#P","#PAA","#PBCT","#PCAR",
"#PFE","#PG","#PTEN","#PYPL","#QCOM","#RIG","#ROST","#RRC","#SBUX","#SCHW","#SLB","#SNAP","#SPWR","#STLD","#STX","#SWKS","#SYF","#SYMC","#T","#TERP","#TSLA","#TSM",
"#TWTR","#TWX","#UNP","#URBN","#USB","#V","#VIAB","#VLO","#VOD","#VRX","#VZ","#WBA","#WFC","#WLL","#WMB","#WMT","#WYNN","#XOM","#XRX","#YNDX","#ZION"
};