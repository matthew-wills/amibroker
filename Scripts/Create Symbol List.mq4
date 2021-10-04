//+------------------------------------------------------------------+
//|                                           Create Symbol List.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   
   string fileName = "SymbolList.csv";
   int fileHandle = FileOpen(fileName,FILE_CSV|FILE_READ | FILE_WRITE,',');
   
   for(int i=0; i<SymbolsTotal(false); i++)
   {  
      FileWrite(fileHandle,SymbolName(i,false));
   }
   
   FileClose(fileHandle);
   
  }
//+------------------------------------------------------------------+
