//+------------------------------------------------------------------+
//|                                                      ea-test.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Mt4Redis/RedisPubSub.mqh>
#include <JAson.mqh>
#include <hash.mqh>


RedisPubSub *client=NULL;
Hash *config = new Hash();

int OnInit()
  {
//--- create timer
   EventSetTimer(1); //1s
   
   readConfig();
   string redisHost = config.hGetString("REDIS_HOST");
   int redisPort = StrToInteger(config.hGetString("REDIS_POST"));
   RedisContext *c=RedisContext::connect(redisHost,redisPort);
  
   if(c==NULL)
     {
      return INIT_FAILED;
     }
   client=new RedisPubSub(c);
 
 
   
   string out = GetInforSymbol(Symbol());
   client.publish("Symbol-info", out);
   
   
   if(client.hasError())
     {
      Print("Error occured when publishing to treids. Prepare to quit");
      return INIT_FAILED;
     }
   
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
/*
   printf("Symbol=%s",Symbol());
   printf("Last incoming bid price=%f",SymbolInfoDouble(Symbol(),SYMBOL_BID));
   printf("SYMBOL_BIDHIGH bid price=%f",SymbolInfoDouble(Symbol(),SYMBOL_BIDHIGH));
   printf("SYMBOL_BIDLOW bid price=%f",SymbolInfoDouble(Symbol(),SYMBOL_BIDLOW));
   printf("Last incoming ask price=%f",SymbolInfoDouble(Symbol(),SYMBOL_ASK));
   printf("SYMBOL_ASKHIGH bid price=%f",SymbolInfoDouble(Symbol(),SYMBOL_ASKHIGH));
   printf("SYMBOL_ASKLOW bid price=%f",SymbolInfoDouble(Symbol(),SYMBOL_ASKLOW));
   */
   //printf("tick");
   CJAVal js(NULL,jtUNDEF);
   js["Symbol"] = Symbol();
   js["MODE_TIME"] = MarketInfo(Symbol(),MODE_TIME);
   js["MODE_BID"] = MarketInfo(Symbol(),MODE_BID);
   js["MODE_ASK"] = MarketInfo(Symbol(),MODE_ASK);
   string out="";
   js.Serialize(out);
   client.publish("tick",out);
   return;
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---

  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+
string GetInforSymbol(string symbol)
{
   CJAVal js(NULL,jtUNDEF);
   js["Symbol"] = symbol;
   js["MODE_DIGITS"] = MarketInfo(symbol,MODE_DIGITS);
   js["MODE_LOTSIZE"] = MarketInfo(symbol,MODE_LOTSIZE);
   js["MODE_SWAPLONG"] = MarketInfo(symbol,MODE_SWAPLONG);
   js["MODE_SWAPSHORT"] = MarketInfo(symbol,MODE_SWAPSHORT);
   js["MODE_MINLOT"] = MarketInfo(symbol,MODE_MINLOT);
   js["MODE_MAXLOT"] = MarketInfo(symbol,MODE_MAXLOT);
   js["MODE_LOTSTEP"] = MarketInfo(symbol,MODE_LOTSTEP);
   string out="";
   js.Serialize(out);
   return out;
}

void readConfig(){
   ResetLastError();
   string InpFileName = "config.ini";
   int file_handle=FileOpen(InpFileName,FILE_READ);
   if(file_handle!=INVALID_HANDLE)
     {
      PrintFormat("%s file is available for reading",InpFileName);
      PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));
      //--- additional variables
      
      string str;
      //--- read data from the file
      while(!FileIsEnding(file_handle))
        {
         //--- find out how many symbols are used for writing the time
         
         //--- read the string
         str=FileReadString(file_handle);         
         
         string pair[];
         int pairSize = StringSplit(str, StringGetCharacter("=",0), pair);
         if(pairSize !=2){            
            continue;
         }
         config.hPutString(pair[0], pair[1]);
         //--- print the string
         Print(str," - key: ", pair[0], ", value: ", pair[1]);
         
        }
      //--- close the file
      FileClose(file_handle);
      PrintFormat("Data is read, %s file is closed",InpFileName);
     }
   else
      PrintFormat("Failed to open %s file, Error code = %d",InpFileName,GetLastError());
}
