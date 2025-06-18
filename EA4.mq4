//+------------------------------------------------------------------+
//|                                                          EA4.mq4 |
//|                                                          Mikhail |
//|                                              textyping@yandex.ru |
//+------------------------------------------------------------------+
#property copyright "Mikhail"
#property link      "textyping2@gmail.com"
#property version   "1.00"
#property strict

input    int               magic                   = 168737;                                    // Magic Number
input    double            lot                     = 0.1;                                       // Lot Size
input    int               Slippage                = 100;                                       // Slippage (points)
input    double            slDol                   = 20;                                        // SL ($)
input    double            tpDol                   = 20;                                        // TP ($)
input    double            minMarginLevel          = 50;                                        // MIN MARGIN LEVEL % 
input    int               spreadMax               = 100;                                       // Max Spread (points)
input    bool              TSon                    = false;                                     // Trailing Stop ON
input    double            TSdistance              = 0;                                         // TRAILER STOP START DISTANCE (PIPS)
input    double            TSstep                  = 0;                                         // TRAILER STEPS (PIPS)
input    bool              BEon                    = false;                                     // Break Even ON
input    double            BEstart                 = 0;                                         // Break Even START (PIPS)
input    double            BEprofit                = 0;                                         // Break Even PROFIT (PIPS)

input    string            workingHours            = "------------------------";                // ----- EA WORKING HOURS -----
input    string            startTime               = "00:00";                                   // Start
input    string            stopTime                = "24:00";                                   // End

input    double            soeHoeLevel             = 17;                                        // ----- INDICATOR 1 SOEHOE ID PEAK LEVEL -----  
input    int               limitOrders             = 0;                                         // NUMBER OF SELL LIMIT/BUY LIMIT 
input    double            limitStep               = 50;                                        // SELL LIMIT/BUY LIMIT STEPS (pips)
input    bool              definedStops            = false;                                     // FIRST TRADE SL&TP CURRENT FOR ALL TRADES

input    string            ind4                    = "------------------------";                // ----- INDICATOR 2 Golden Finger -----        
input    int               RISK                    = 4; 

datetime curCandle, openTrade;

double   dotBuy, dotSell, SLtemp, TPtemp, SLpoint, TPpoint;

bool     lastBuy, lastSell, buyExceededPrev, sellExceededPrev, buyPermitted, sellPermitted;

string   comment1, comment2;

double   _point,  pipsMultiplier;

int      lotsDigits, digits;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   comment1 = "Type 1";
   comment2 = "Type 2";
   lastBuy = lastSell = false;
   pointCalculation();
   curCandle = iTime (_Symbol, PERIOD_CURRENT, 0);
   buyExceededPrev = sellExceededPrev = false;
   
   SLpoint = riskPointsCalculation (slDol, lot);
   TPpoint = riskPointsCalculation (tpDol, lot);
   
   buyPermitted = sellPermitted = false;
   openTrade = TimeCurrent();

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
//---
   double soeGreen = iCustom (_Symbol, _Period, "SoeHoe.ID_Peak", 0, 1);
   double soeRed = iCustom (_Symbol, _Period, "SoeHoe.ID_Peak", 1, 1);
   
   
   if (soeGreen >= soeHoeLevel) buyPermitted = true;
   if (soeRed >= soeHoeLevel) sellPermitted = true;

// Open limit orders
   if (numberOfOpenedBuySell(magic) + numberOfOpenedBuySell(magic + 1) > 0)
    {
     if (numberOfPending (magic + 1) == 0)
      {
       if (numberOfOpenedBuy (magic) + numberOfOpenedBuy (magic + 1) > 0)
        {
         double openPrice = Ask - limitStep * _Point;
         openBuyLimit(openPrice, openPrice - SLpoint, openPrice + TPpoint, "hedge", magic + 1);
        }
       else if (numberOfOpenedSell (magic) + numberOfOpenedSell (magic + 1) > 0)
        {
         double openPrice = Bid + limitStep * _Point;
         openSellLimit(openPrice, openPrice + SLpoint, openPrice - TPpoint, "hedge", magic + 1);
        }
      }
    }
    
// And When sum of the trades for related currency equal to ZERO EA will close all trades ( and delate remaining untouched steps sell limit/buy limit)
   if (numberOfOpenedBuySell(magic + 1) > 0)
    {
     double profCur = profitOfOpenedTrades (magic) + profitOfOpenedTrades (magic + 1) + profitOfClosed (openTrade, magic) + profitOfClosed (openTrade, magic + 1);
     if (profCur >= 0)
      {
       deleteAllPending(magic + 1);
       closeAll(magic + 1);
       closeAll(magic);
      }
    }
    
// Close pending orders if no opened trades
   {
    if (numberOfOpenedBuySell(magic) + numberOfOpenedBuySell(magic + 1) == 0)
     {
      deleteAllPending(magic + 1);
     }
   }

   if (TSon) trailingStop (TSdistance, TSstep, magic);
   
   if (BEon) breakEven (BEstart, BEprofit, magic);

   bool tradeDenied = false;
   string com = "";
   
   com = "soeHoeBuy: " + DoubleToString (soeGreen, 2) + ": " + IntegerToString (buyPermitted) + "\nsoeHoeSell: " + DoubleToString (soeRed, 2) + ": " + IntegerToString (sellPermitted) + "\n";

   double spread = MarketInfo (_Symbol, MODE_SPREAD);
   if (spread > spreadMax)
    {
     tradeDenied = true;
     com += "Trade is denied: Spread.\n";
    }
   if (!tradeByTimePermitted (startTime, stopTime))
    {
     tradeDenied = true;
     com += "Trade is denied: Time.";
    }
// MIN MARGIN LEVEL % 
   double margin = AccountMargin();
   double equity = AccountEquity();
   if (margin > 0)
    {
     if (equity / margin * 100 < minMarginLevel)
      {
       tradeDenied = true;
       com += "Trade is denied: MIN MARGIN LEVEL.";
      }
    }
   Comment (com);
   

   if (curCandle != iTime (_Symbol, PERIOD_CURRENT, 0))
    {
     curCandle = iTime (_Symbol, PERIOD_CURRENT, 0);
      {
               
// Open trades conditions
       double goldenFingerBuy = iCustom (_Symbol, PERIOD_CURRENT, "Golden Finger", RISK, 0, 1);
       double goldenFingerSell = iCustom (_Symbol, PERIOD_CURRENT, "Golden Finger", RISK, 1, 1);
       
       if (goldenFingerBuy != EMPTY_VALUE) 
        {
// Buy Arrow
         if (buyPermitted)
          {
           if (numberOfOpenedBuySell(magic) + numberOfOpenedBuySell(magic + 1) == 0) 
            {
             openBuy (Ask + spread * _Point - SLpoint, Ask + spread * _Point + TPpoint, "");
             openTrade = TimeCurrent();
            }
           buyPermitted = false;
          }
        }
       if (goldenFingerSell != EMPTY_VALUE) 
        {
// Sell Arrow 
         
         if (sellPermitted)
          {
           if (numberOfOpenedBuySell(magic) + numberOfOpenedBuySell(magic + 1) == 0) 
            {
             openSell (Bid - spread * _Point + SLpoint, Bid - spread * _Point - TPpoint, "");
             openTrade = TimeCurrent();
            }
           sellPermitted = false;
          }
        }

      }
    }
  }
  
//+------------------------------------------------------------------+
  
void trailingStop (double trailingPips, double trailingParam, int Magic)
 {
  for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
    if (!OrderSelect (i,SELECT_BY_POS)) continue;
    if (OrderSymbol() != Symbol()) continue;
    if (OrderMagicNumber() != Magic) continue;
    double orderClose = OrderClosePrice();
    double orderSL = OrderStopLoss();
    double orderOpen = OrderOpenPrice();
    if (OrderType() == OP_BUY)
     {
      if (orderClose - orderOpen > trailingPips * _point)
       {
        double newSL = NormalizeDouble (orderClose - trailingParam * _point, _Digits);
        
        if (orderClose - orderSL > trailingParam * _point + Point && Bid - newSL > MarketInfo(NULL, MODE_STOPLEVEL) * Point)
         {
          int Ans = OrderModify (OrderTicket(), orderOpen, newSL, OrderTakeProfit(), 0);
         }
       }
     }
    else if (OrderType() == OP_SELL)
     {
      if (orderOpen - orderClose > trailingPips * _point)
       {
        double newSL = NormalizeDouble (orderClose + trailingParam * _point, _Digits);
       
        if (orderSL == 0 || (orderSL - orderClose > trailingParam * _point + Point && newSL - Ask > MarketInfo(NULL, MODE_STOPLEVEL) * Point))
         {
          int Ans = OrderModify (OrderTicket(), orderOpen, newSL, OrderTakeProfit(), 0);
         }
       }
     }
   }
 }

//+------------------------------------------------------------------+

void breakEven(double Start, double prof, int Magic)
 {
  int ans;
  for(int i = OrdersTotal()-1; i >= 0; i--)
   {
    if(!OrderSelect(i,SELECT_BY_POS)) continue;
    if(OrderSymbol() != Symbol()) continue;
    if(OrderMagicNumber() != Magic) continue;
    if(OrderType() == OP_BUY) 
     {
      if (OrderClosePrice() > OrderOpenPrice() + Start * _point)
       {
        double newStopLoss = NormalizeDouble (OrderOpenPrice() + prof * _point, _Digits);
        if (OrderStopLoss() < newStopLoss - 0.5 * _point && Bid - newStopLoss > MarketInfo(NULL, MODE_STOPLEVEL) * Point)
         {
          ans = OrderModify(OrderTicket(), OrderClosePrice(), newStopLoss, OrderTakeProfit(), 0);
         }
       }
     }
    if(OrderType() == OP_SELL) 
     {
      if (OrderClosePrice() < OrderOpenPrice() - Start * _point)
       {
        double newStopLoss = NormalizeDouble (OrderOpenPrice() - prof * _point, _Digits);
        if (OrderStopLoss() == 0 || (OrderStopLoss() > newStopLoss + 0.5 * _point && newStopLoss - Ask > MarketInfo(NULL, MODE_STOPLEVEL) * Point))
         {
          ans = OrderModify(OrderTicket(), OrderClosePrice(), newStopLoss, OrderTakeProfit(), 0);
         }
       }
     }
   }
 }
 
//+------------------------------------------------------------------+

int findBuffer (int pos)
 {        
  if (StringFind (_Symbol, "USD") == pos) return 0;
  if (StringFind (_Symbol, "EUR") == pos) return 1;
  if (StringFind (_Symbol, "GBP") == pos) return 2;
  if (StringFind (_Symbol, "CHF") == pos) return 3;
  if (StringFind (_Symbol, "JPY") == pos) return 4;
  if (StringFind (_Symbol, "AUD") == pos) return 5;
  if (StringFind (_Symbol, "CAD") == pos) return 6;
  if (StringFind (_Symbol, "NZD") == pos) return 7;
  
  return 100;
 }
//+------------------------------------------------------------------+

void closePendings()
 {
  for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
    if (!OrderSelect (i, SELECT_BY_POS)) continue;
    if (OrderSymbol() != _Symbol) continue;
    if (OrderMagicNumber() != magic) continue;
    if (OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLLIMIT) 
     {
      int order = int (StringToInteger (StringSubstr (OrderComment(), 8)));
      if (!openedOrder (order)) 
       {
        bool Ans = OrderDelete (OrderTicket());
        
        if (Ans)
         {
          Print (_Symbol, ": Pending order is deleted.");
         }
        else
         {
          Print (_Symbol, ": Failed to delete Pending order.");
         }
       }
     }
   }
 }
    
//+------------------------------------------------------------------+

bool openedOrder (int order)
 {
  for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
    if (!OrderSelect (i, SELECT_BY_POS)) continue;
    if (OrderSymbol() != _Symbol) continue;
    if (OrderMagicNumber() != magic) continue;
    if (OrderType() == OP_BUY || OrderType() == OP_SELL) 
     {
      if (OrderTicket() == order) return true;
     }
   }
  return false;
 }
    
//+------------------------------------------------------------------+

bool soeHoeBuy()
 {
  for (int i = 1; i < iBars (_Symbol, PERIOD_CURRENT); i++)
   {
    double soeGreen = iCustom (_Symbol, _Period, "SoeHoe.ID_Peak", 0, i);
    if (soeGreen >= soeHoeLevel) 
     {
      return true;
     }
    else
     {
      double goldenFingerBuy = iCustom (_Symbol, PERIOD_CURRENT, "Golden Finger", RISK, 0, i);
      double goldenFingerSell = iCustom (_Symbol, PERIOD_CURRENT, "Golden Finger", RISK, 1, i);
       
      if (i > 1 && (goldenFingerBuy != EMPTY_VALUE || goldenFingerSell != EMPTY_VALUE))
       {
        return false;
       } 
     }
   }
  return false;
 }
    
//+------------------------------------------------------------------+

bool soeHoeSell()
 {
  for (int i = 1; i < iBars (_Symbol, PERIOD_CURRENT); i++)
   {
    double soeRed = iCustom (_Symbol, _Period, "SoeHoe.ID_Peak", 1, i);
    if (soeRed >= soeHoeLevel) 
     {
      return true;
     }
    else
     {
      double goldenFingerBuy = iCustom (_Symbol, PERIOD_CURRENT, "Golden Finger", RISK, 0, i);
      double goldenFingerSell = iCustom (_Symbol, PERIOD_CURRENT, "Golden Finger", RISK, 1, i);
       
      if (i > 1 && (goldenFingerBuy != EMPTY_VALUE || goldenFingerSell != EMPTY_VALUE))
       {
        return false;
       } 
     }
   }
  return false;
 }
    
//+------------------------------------------------------------------+

void pointCalculation()
 {
  _point = 1;
  pipsMultiplier = 1;
  digits = 0;
   
  if( MarketInfo ("EURUSD", MODE_DIGITS) == 5)
   {
    _point = Point * 10;
    pipsMultiplier = 10;
    digits = 1;
    
   }
  else
   {
    _point = Point;
    pipsMultiplier = 1;
    digits = 0;
   }
   
  lotsDigits = int(MathCeil(MathAbs(MathLog( MarketInfo(_Symbol, MODE_LOTSTEP) )/MathLog(10))));
 }
 
//+------------------------------------------------------------------+ 

double riskPointsCalculation (double risk, double lotSize)
 {
  double  pointPrice = MarketInfo (_Symbol, MODE_TICKVALUE) / Point;

  if (pointPrice == 0)
   {
    Alert ("The broker does not provide the cost of one point for this instrument.");
    ExpertRemove();
   }
  
  double result = NormalizeDouble (risk / (lotSize * pointPrice), _Digits);
   
  return result; 
 }
  
//+------------------------------------------------------------------+ 

int numberOfOpenedBuySell(int Magic)
 {
  int result = 0;
  for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
    if (!OrderSelect(i,SELECT_BY_POS)) continue;
    if (OrderSymbol() != _Symbol) continue;
    if (OrderMagicNumber() != Magic) continue;
    if (OrderType() == OP_SELL || OrderType() == OP_BUY) 
     {
      result++;
     }
   }
  return result;
 }
  
//+------------------------------------------------------------------+ 

int numberOfPending(int Magic)
 {
  int result = 0;
  for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
    if (!OrderSelect(i,SELECT_BY_POS)) continue;
    if (OrderSymbol() != _Symbol) continue;
    if (OrderMagicNumber() != Magic) continue;
    if (OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT) 
     {
      result++;
     }
   }
  return result;
 }

//+------------------------------------------------------------------+ 

int numberOfOpenedBuy(int Magic)
 {
  int result = 0;
  for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
    if (!OrderSelect(i,SELECT_BY_POS)) continue;
    if (OrderSymbol() != _Symbol) continue;
    if (OrderMagicNumber() != Magic) continue;
    if (OrderType() == OP_BUY) 
     {
      result++;
     }
   }
  return result;
 }
 
//+------------------------------------------------------------------+ 

int openBuyLimit(double openPrice, double SL, double TP, string comment, int Magic)
 {
  int Ans = OrderSend(Symbol(), OP_BUYLIMIT, lot, openPrice, Slippage, SL, TP, comment, Magic, 0);
  if (Ans > 0) 
   {
    Print ("BUY LIMIT order placed. Entry price = ", openPrice, ", Lot size = ", lot, ", SL = ", SL, ", TP = ", TP); 
   }
  else
   {
    Alert ("Error of placing the BUY LIMIT order. Entry price = ", openPrice, ", Lot size = ", lot, ", SL = ", SL, ", TP = ", TP, ". Error: ", GetLastError());
   }
  return Ans;
 }
 
//+------------------------------------------------------------------+ 

int numberOfOpenedSell(int Magic)
 {
  int result = 0;
  for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
    if (!OrderSelect(i,SELECT_BY_POS)) continue;
    if (OrderSymbol() != _Symbol) continue;
    if (OrderMagicNumber() != Magic) continue;
    if (OrderType() == OP_SELL) 
     {
      result++;
     }
   }
  return result;
 }
  
//+------------------------------------------------------------------+

int openSellLimit(double openPrice, double SL, double TP, string comment, int Magic)
 {
  int Ans = OrderSend(_Symbol, OP_SELLLIMIT, lot, openPrice, Slippage, SL, TP, comment, Magic, 0);
  if (Ans > 0)
   {
    Print ("SELL LIMIT order is opened. Entry price = ", openPrice, ", Lot size = ", lot, ", SL = ", SL, ", TP = ", TP); 
   }
  else
   {
    Alert ("Error of opening the SELL LIMIT order. Entry price = ", openPrice, ", Lot size = ", lot, ", SL = ", SL, ", TP = ", TP, ". Error: ", GetLastError());
   }
  return Ans;
 }
 
//+------------------------------------------------------------------+ 

double profitOfOpenedTrades(int Magic)
 {
  double result = 0;
  for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
    if (!OrderSelect(i,SELECT_BY_POS)) continue;
    if (OrderSymbol() != _Symbol) continue;
    if (OrderMagicNumber() != Magic) continue;
    if (OrderType() == OP_SELL || OrderType() == OP_BUY) 
     {
      result += OrderProfit() + OrderCommission() + OrderSwap();
     }
   }
  return result;
 }
  
//+------------------------------------------------------------------+

double profitOfClosed(datetime startT, int Magic)
 {
  
  double result = 0;
  for (int i = OrdersHistoryTotal() - 1; i >= 0; i--)
   {
    if (!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) continue;
    if (OrderType() > 1) continue;
    if (OrderMagicNumber() != Magic) continue;
    if (OrderCloseTime() >= startT)
     {
      result += OrderProfit() + OrderCommission() + OrderSwap();
     }
   }
  return result;
 }
    
//+------------------------------------------------------------------+
 
void deleteAllPending(int Magic)
 {
  for (int i = OrdersTotal()-1; i >= 0; i--)
   {
    if (!OrderSelect(i,SELECT_BY_POS)) continue;
    if (OrderSymbol() != _Symbol) continue;
    if (OrderMagicNumber() != Magic) continue;
    if (OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP) 
     {
      Print ("Trying to delete order.");
      int Ans = OrderDelete(OrderTicket());
      if (Ans)
       {
        Print (_Symbol, ": Order is deleted.");
       }
      else
       {
        Print (_Symbol, ": Failed to delete the order.");
       }
     }
   }
 }

//+------------------------------------------------------------------+
 
void closeAll(int Magic)
 {
  for (int i = OrdersTotal()-1; i >= 0; i--)
   {
    if (!OrderSelect(i,SELECT_BY_POS)) continue;
    if (OrderSymbol() != _Symbol) continue;
    if (OrderMagicNumber() != Magic) continue;
    if (OrderType() == OP_SELL || OrderType() == OP_BUY) 
     {
      Print ("Trying to close order.");
      int Ans = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), Slippage);
      if (Ans)
       {
        Print (_Symbol, ": Order is closed.");
       }
      else
       {
        Print (_Symbol, ": Failed to close the order.");
       }
     }
   }
 }
 
//+------------------------------------------------------------------+ 

bool tradeByTimePermitted (string startT, string stopT)
 {
  datetime tradeStartTime = StringToTime(startT);
  datetime tradeStopTime = StringToTime(stopT);
  
  if (stopT == "24:00") 
   {
    tradeStopTime = StringToTime("00:00") + 60 * 60 * 24;
   }
  
  if (tradeStopTime < tradeStartTime) tradeStopTime += 60 * 60 * 24;
  if (TimeCurrent() >= tradeStartTime && TimeCurrent() <= tradeStopTime) return true;
  return false;
 }
 
//+------------------------------------------------------------------+ 

int openBuy (double SL, double TP, string comment)
 {

  int Ans = OrderSend(Symbol(), OP_BUY, lot, Ask, Slippage, SL, TP, comment, magic, 0);
  if (Ans > 0) 
   {
    Alert ("BUY order is opened. Lot size = ", lot, ", SL = ", SL, ", TP = ", TP); 
   }
  else
   {
    Alert ("Error of opening the BUY order. Lot size = ", lot, ", SL = ", SL, ", TP = ", TP, ". Error: ", GetLastError());
   }
  return Ans;
 }
           
//+------------------------------------------------------------------+

int openSell (double SL, double TP, string comment)
 {

  int Ans = OrderSend(_Symbol, OP_SELL, lot, Bid, Slippage, SL, TP, comment, magic, 0);
  if (Ans > 0)
   {
    Alert ("SELL order is opened. Lot size = ", lot, ", SL = ", SL, ", TP = ", TP); 
   }
  else
   {
    Alert ("Error of opening the SELL order. Lot size = ", lot, ", SL = ", SL, ", TP = ", TP, ". Error: ", GetLastError());
   }
  return Ans;
 }
 
//+------------------------------------------------------------------+

