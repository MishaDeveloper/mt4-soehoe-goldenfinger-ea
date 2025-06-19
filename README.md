# MT4 SoeHoe + Golden Finger Expert Advisor

This is a MetaTrader 4 Expert Advisor (EA) that trades based on two custom indicators: **SoeHoe.ID Peak** and **Golden Finger**. The robot uses a hedging strategy with optional trailing stop, break-even, dollar-based SL/TP, and a recovery mechanism using pending limit orders.

---

## 🧠 Strategy Logic

- **Main signal**: Triggered by SoeHoe.ID_Peak indicator
- **Confirmation**: Golden Finger indicator provides Buy/Sell confirmation
- **Initial trade**: One market order based on signal
- **Hedging**: Automatically places Buy Limit / Sell Limit in opposite direction
- **Close logic**: When combined profit from both sides reaches break-even or better, all trades and pending orders are closed

---

## ⚙️ Input Parameters

- `lot` — trade volume  
- `slDol` / `tpDol` — dollar-based Stop Loss / Take Profit  
- `TSon`, `TSdistance`, `TSstep` — Trailing Stop control  
- `BEon`, `BEstart`, `BEprofit` — Break Even activation  
- `limitOrders`, `limitStep` — Recovery grid settings  
- `definedStops` — Apply same SL/TP to hedge orders  
- `soeHoeLevel` — Entry threshold for SoeHoe.ID indicator  
- `RISK` — Risk level setting for Golden Finger  
- `startTime` / `stopTime` — Working time window  
- `minMarginLevel`, `spreadMax` — Risk protection filters  

---

## 📈 Features

- ✅ Multi-signal logic (SoeHoe + Golden Finger)
- ✅ Time-based and spread-based entry filtering
- ✅ Dynamic risk calculation based on lot size and dollar-based SL/TP
- ✅ Optional trailing stop and break-even
- ✅ Automatic hedge entry with customizable step
- ✅ Pending order deletion and full position closure when in profit

---

## 📂 File Structure

mt4-soehoe-goldenfinger-ea/

├── EA4.mq4

└── README.md

---

## 🛠 Platform

- MetaTrader 4 (MT4)
- Language: MQL4
- Indicators required:
  - `SoeHoe.ID_Peak.ex4`
  - `Golden Finger.ex4`

---

## 💾 Installation

1. Copy `EA4.mq4` to `MQL4/Experts/` in your MT4 terminal directory
2. Compile the file in MetaEditor
3. Place required indicators (`SoeHoe.ID_Peak`, `Golden Finger`) into `MQL4/Indicators/`
4. Attach the EA to a chart and configure input parameters

---

## 🙋 Author

**Mikhail Krygin**  
Kyiv, Ukraine  
📧 textyping2@gmail.com  
🔗 [GitHub](https://github.com/MishaDeveloper)

---

## 📄 License

This EA is provided for personal or educational use only.  
If you'd like to use it commercially, please contact the author.
