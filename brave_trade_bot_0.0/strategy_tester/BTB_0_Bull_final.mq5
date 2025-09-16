//+------------------------------------------------------------------+
//|                                                 BTB_0_Bull_final.mq5 |
//|                                                      MetaQuotes Software Corp. |
//|                                                  https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_plots 0

//--- input parameters
input bool InpShowPivots = true; // Show Pivots
input color InpHighColor = clrRed; // High Color
input color InpLowColor = clrGreen; // Low Color
input ENUM_LABEL_STYLE InpPivotStyle = LABEL_STYLE_TRIANGLE; // Style
input ENUM_LABEL_SIZE InpPivotSize = LABEL_SIZE_AUTO; // Size
input int InpMaxPivots = 100; // Maximum visible pivots

input bool InpShowExtTrend = true; // Show External Trend
input color InpExtTrendColor = clrRed; // External Trend Color
input ENUM_LINE_STYLE InpExtTrendStyle = LINE_STYLE_SOLID; // External Trend Style
input int InpExtTrendWidth = 1; // External Trend Width

input bool InpShowIntTrend = true; // Show Internal Trend
input color InpIntTrendColor = clrRed; // Internal Trend Color
input ENUM_LINE_STYLE InpIntTrendStyle = LINE_STYLE_DASHED; // Internal Trend Style
input int InpIntTrendWidth = 1; // Internal Trend Width

input bool InpShowZones = true; // Show pivot boxes
input int InpZonesRight = 1; // Width (bars)
input color InpZoneHighBg = clrRed; // High bg
input color InpZoneLowBg = clrGreen; // Low bg
input int InpMaxZones = 200; // Maximum boxes
input bool InpShowMergedLabel = false; // Show mergedSize label at 2nd pivot

input bool InpShowBullishPullback = true; // Show Bullish Pullback Zones
input bool InpDetectBullishPullback = true; // Detect Bullish Pullback
input color InpBullishPullbackColor = clrBlue; // Color
input int InpMaxBullishPullbackZones = 50; // Maximum Zones
input int InpBullishPullbackWidth = 30; // Width (bars)

input bool InpUseEma300 = true; // Use EMA 300
input bool InpUseEma100 = true; // Use EMA 100
input bool InpUseEma50 = true; // Use EMA 50
input bool InpUseEma20 = true; // Use EMA 20
input bool InpUsePriceAction = true; // Use Price Action
input int InpMinBullishConfirmation = 2; // Min Bullish Confirmations

input bool InpShowFvg = true; // Show FVG Zones
input int InpFvgBoxLength = 20; // Box Length
input int InpFvgMaxTrackBars = 300; // Max Track Bars
input int InpFvgCheckForwardBars = 300; // Check Forward Bars
input color InpFvgBullishColor = clrYellow; // Bullish FVG Color
input color InpFvgBearishColor = clrRed; // Bearish FVG Color
enum ENUM_FVG_DISPLAY_MODE
  {
   FVG_DISPLAY_IN_TARGET_ZONES, // In Target Zones
   FVG_DISPLAY_OUTSIDE_TARGET_ZONES, // Outside Target Zones
   FVG_DISPLAY_ALL // All
  };
input ENUM_FVG_DISPLAY_MODE InpFvgDisplayMode = FVG_DISPLAY_IN_TARGET_ZONES; // FVG Display Mode

input bool InpShowTargetZones = true; // Show Target Zones
input int InpTargetMaxZones = 50; // Maximum boxes
input color InpTargetZoneColor = clrGreen; // Color

//--- Enums for styles and sizes
enum ENUM_LABEL_STYLE
  {
   LABEL_STYLE_TEXT,
   LABEL_STYLE_TRIANGLE,
   LABEL_STYLE_DOT
  };

enum ENUM_LABEL_SIZE
  {
   LABEL_SIZE_AUTO,
   LABEL_SIZE_TINY,
   LABEL_SIZE_SMALL,
   LABEL_SIZE_NORMAL,
   LABEL_SIZE_LARGE,
   LABEL_SIZE_HUGE
  };

enum ENUM_LINE_STYLE
  {
   LINE_STYLE_SOLID,
   LINE_STYLE_DOTTED,
   LINE_STYLE_DASHED
  };

//+------------------------------------------------------------------+
//| Custom Types (Structs)                                           |
//+------------------------------------------------------------------+
struct PivotType
  {
   double            price;
   datetime          timestamp;
   int               index;
   double            barHigh;
   double            barLow;

   void              copy(const PivotType& from)
     {
      price     = from.price;
      timestamp = from.timestamp;
      index     = from.index;
      barHigh   = from.barHigh;
      barLow    = from.barLow;
     }

   bool              invalid() const { return price == WRONG_VALUE; }
   bool              valid() const { return price != WRONG_VALUE; }

   void              invalidate()
     {
      price     = WRONG_VALUE;
      timestamp = 0;
      index     = 0;
      barHigh   = WRONG_VALUE;
      barLow    = WRONG_VALUE;
     }

   void              set(double _price, datetime _timestamp, int _index, double _barHigh, double _barLow)
     {
      price     = _price;
      timestamp = _timestamp;
      index     = _index;
      barHigh   = _barHigh;
      barLow    = _barLow;
     }

   void              setHigher(const PivotType& pivot)
     {
      if (invalid() || pivot.price > price)
        {
         copy(pivot);
        }
     }

   void              setLower(const PivotType& pivot)
     {
      if (invalid() || pivot.price < price)
        {
         copy(pivot);
        }
     }
  };

// Global constant for invalid price
const double WRONG_VALUE = -1.0;

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
// For PivotType
PivotType eh, el, ih, il;
bool trend_direction = false; // Corresponds to 'var bool trend' in Pine Script, but used differently

// For PivotsType (labels)
string pivotLabels[]; // Array to store label names
int pivotLabelsCount = 0;

// For TrendType (polylines)
string extTrendLineName = "ExtTrendLine";
string intTrendLineName = "IntTrendLine";

// For Pivot Zones (boxes)
string pivotBoxesNames[]; // Array to store box names
int pivotBoxesCount = 0;

// For Bullish Pullback Zones
PivotType lastBullishHigh;
string bullishPullbackBoxesNames[];
int bullishPullbackBoxesCount = 0;

// For FVG Logic
string fvgBoxesNames[];
int fvgBoxesCount = 0;
string fvgLabelsNames[];
int fvgLabelsCount = 0;
int fvgCreatedBars[];
bool fvgIsBullish[];
double fvgCompareLevels[];
double fvgTops[];
double fvgBottoms[];

// For Target Zones
string targetZonesNames[];
int targetZonesCount = 0;
double targetZoneTops[];
double targetZoneBottoms[];
string tzTopLinesNames[];
string tzBottomLinesNames[];
string fvgTopLinesNames[];
string fvgBottomLinesNames[];
bool fvgInTarget[];

// Indicator handles
int iEma300, iEma100, iEma50, iEma20;

//+------------------------------------------------------------------+
//| Indicator Initialization Function                                |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- indicator buffers mapping
   // No indicator buffers needed for this script as it only draws objects

   //--- Initialize custom types/structs
   eh.invalidate();
   el.invalidate();
   ih.invalidate();
   il.invalidate();
   lastBullishHigh.invalidate();

   //--- Create indicator handles for EMAs
   iEma300 = iMA(NULL, 0, 300, 0, MODE_EMA, PRICE_CLOSE);
   iEma100 = iMA(NULL, 0, 100, 0, MODE_EMA, PRICE_CLOSE);
   iEma50  = iMA(NULL, 0, 50, 0, MODE_EMA, PRICE_CLOSE);
   iEma20  = iMA(NULL, 0, 20, 0, MODE_EMA, PRICE_CLOSE);

   if (iEma300 == INVALID_HANDLE || iEma100 == INVALID_HANDLE || iEma50 == INVALID_HANDLE || iEma20 == INVALID_HANDLE)
     {
      Print("Failed to create EMA indicator handle");
      return INIT_FAILED;
     }

   //--- Set indicator short name
   IndicatorSetString(INDICATOR_SHORTNAME, "BTB_0.0");

   //---
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Indicator Deinitialization Function                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //--- Delete all objects created by the indicator
   ObjectsDeleteAll(0, 0, OBJ_LABEL);
   ObjectsDeleteAll(0, 0, OBJ_RECTANGLE);
   ObjectsDeleteAll(0, 0, OBJ_POLYLINE);
  }

//+------------------------------------------------------------------+
//| Indicator Iteration Function                                     |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const long &spread[])
  {
   //--- Check for enough bars
   if (rates_total < 300) return 0; // Need at least 300 bars for EMA300

   //--- Calculate starting index for new bars
   int limit = rates_total - prev_calculated;
   if (prev_calculated > 0) limit = 1; // Process only the last bar on subsequent calls

   for (int i = rates_total - limit; i < rates_total; i++)
     {
      //--- Get EMA values
      double ema300_val = iMAOnArray(close, 0, 300, 0, MODE_EMA, i);
      double ema100_val = iMAOnArray(close, 0, 100, 0, MODE_EMA, i);
      double ema50_val = iMAOnArray(close, 0, 50, 0, MODE_EMA, i);
      double ema20_val = iMAOnArray(close, 0, 20, 0, MODE_EMA, i);

      //--- Bullish Conditions
      int bullishConditions = 0;
      if (InpUseEma300 && close[i] > ema300_val) bullishConditions++;
      if (InpUseEma100 && close[i] > ema100_val) bullishConditions++;
      if (InpUseEma50 && close[i] > ema50_val) bullishConditions++;
      if (InpUseEma20 && close[i] > ema20_val) bullishConditions++;
      if (InpUsePriceAction && close[i] > open[i]) bullishConditions++;

      bool isBullish = (bullishConditions >= InpMinBullishConfirmation);

      //--- Pivot Detection (Simplified for now, needs full translation)
      // This part is complex and needs careful translation of the 'find()' function logic
      // For now, just a placeholder.
      // Pine Script's 'find()' function uses 'var' which implies state persistence across bars.
      // In MQL5, this state needs to be managed explicitly using global variables.

      // Placeholder for pivot detection logic
      // PivotType newh, newl;
      // [newh, newl] = find(); // This needs to be a function call that updates eh, el, ih, il

      //--- FVG Logic (Simplified for now, needs full translation)
      if (InpShowFvg && i >= 3) // Ensure enough bars for FVG calculation
        {
         // Bullish FVG
         if (low[i-1] > high[i-3])
           {
            // f_draw_fvg(i-3, low[i-1], high[i-3], "", InpFvgBullishColor, high[i-3], true, InpFvgBoxLength);
           }
         // Bearish FVG
         if (high[i-1] < low[i-3])
           {
            // f_draw_fvg(i-3, low[i-3], high[i-1], "", InpFvgBearishColor, low[i-3], false, InpFvgBoxLength);
           }
        }

      //--- Cleanup FVG boxes and labels (needs to be a separate function)
      // This logic will be implemented in a helper function

      //--- Target Zones (Simplified for now, needs full translation)
      // This will depend on the FVG and Pullback box logic

      //--- Drawing lines for Target Zones and FVG (needs full translation)
     }

   //--- return value of rates_total, be aware of possible errors during calculation
   return rates_total;
  }

//+------------------------------------------------------------------+
//| Helper Functions (to be translated from Pine Script methods)     |
//+------------------------------------------------------------------+
// Function to get MQL5 color from Pine Script color (simplified for now)
color GetMQLColor(color pineColor)
  {
   // Pine Script color.new(color.red, 50) is clrRed with 50% transparency
   // MQL5 colors are opaque by default, transparency needs to be handled via ObjectSetInteger(OBJPROP_COLOR, ColorToARGB(color, alpha))
   // For now, direct mapping for basic colors
   if (pineColor == clrRed) return clrRed;
   if (pineColor == clrGreen) return clrGreen;
   if (pineColor == clrBlue) return clrBlue;
   if (pineColor == clrYellow) return clrYellow;
   // Add more mappings as needed
   return clrNONE; // Default to no color
  }

// Function to get MQL5 line style from Pine Script style
ENUM_LINE_STYLE GetMQLLineStyle(ENUM_LINE_STYLE pineStyle)
  {
   if (pineStyle == LINE_STYLE_SOLID) return STYLE_SOLID;
   if (pineStyle == LINE_STYLE_DOTTED) return STYLE_DOT;
   if (pineStyle == LINE_STYLE_DASHED) return STYLE_DASH;
   return STYLE_SOLID;
  }

// Function to get MQL5 label style from Pine Script style
int GetMQLLabelStyle(ENUM_LABEL_STYLE pineStyle, bool isHigh)
  {
   switch(pineStyle)
     {
      case LABEL_STYLE_TRIANGLE: return isHigh ? SYMBOL_ARROW_UP : SYMBOL_ARROW_DOWN;
      case LABEL_STYLE_DOT: return SYMBOL_CIRCLE;
      case LABEL_STYLE_TEXT: return 0; // No specific symbol, text only
     }
   return 0;
  }

// Function to get MQL5 label size from Pine Script size
int GetMQLLabelSize(ENUM_LABEL_SIZE pineSize)
  {
   switch(pineSize)
     {
      case LABEL_SIZE_TINY: return 8;
      case LABEL_SIZE_SMALL: return 9;
      case LABEL_SIZE_NORMAL: return 10;
      case LABEL_SIZE_LARGE: return 12;
      case LABEL_SIZE_HUGE: return 14;
      case LABEL_SIZE_AUTO: return 9; // Default to small
     }
   return 9;
  }

// Function to convert MQL5 color to ARGB with transparency
int ColorToARGB(color clr, int alpha)
  {
   return (alpha << 24) | (GetBValue(clr) << 16) | (GetGValue(clr) << 8) | GetRValue(clr);
  }

//+------------------------------------------------------------------+
//| Pivot Detection Function (Translation of Pine Script 'find()')   |
//+------------------------------------------------------------------+
void FindPivots(const int i, const double &high[], const double &low[], const datetime &time[], int &bar_index_val)
  {
   // This function needs to replicate the stateful behavior of Pine Script's 'find()'
   // 'dir', 'h', 'l' are 'var' variables in Pine Script, meaning they retain their values across bars.
   // In MQL5, these need to be global or static variables.

   static bool s_dir = true; // Corresponds to 'var bool dir = true'
   static PivotType s_h;     // Corresponds to 'var pivotType h = pivotType.new(high, time, bar_index, high, low)'
   static PivotType s_l;     // Corresponds to 'var pivotType l = pivotType.new(low, time, bar_index, high, low)'

   // Initialize on first call or if invalid
   if (s_h.invalid())
     {
      s_h.set(high[i], time[i], i, high[i], low[i]);
      s_l.set(low[i], time[i], i, high[i], low[i]);
     }

   PivotType newh, newl;
   newh.invalidate();
   newl.invalidate();

   if (s_dir)
     {
      if (low[i] < s_l.price)
        {
         if (high[i] > s_h.price)
           {
            s_h.set(high[i], time[i], i, high[i], low[i]);
           }
         newh.copy(s_h);
         s_dir = false;
         s_h.set(high[i], time[i], i, high[i], low[i]);
         s_l.set(low[i], time[i], i, high[i], low[i]);
        }
      else if (high[i] > s_h.price)
        {
         s_l.set(low[i], time[i], i, high[i], low[i]);
         s_h.set(high[i], time[i], i, high[i], low[i]);
        }
     }
   else // !s_dir
     {
      if (high[i] > s_h.price)
        {
         if (low[i] < s_l.price)
           {
            s_l.set(low[i], time[i], i, high[i], low[i]);
           }
         newl.copy(s_l);
         s_dir = true;
         s_h.set(high[i], time[i], i, high[i], low[i]);
         s_l.set(low[i], time[i], i, high[i], low[i]);
        }
      else if (low[i] < s_l.price)
        {
         s_h.set(high[i], time[i], i, high[i], low[i]);
         s_l.set(low[i], time[i], i, high[i], low[i]);
        }
     }

   // Assign newh and newl to global eh, el, ih, il if they are valid
   if (newh.valid()) eh.copy(newh);
   if (newl.valid()) el.copy(newl);
   // The Pine Script returns [newh, newl]. We need to decide how to use these.
   // For now, let's assume eh and el are the 


external pivots and ih, il are internal pivots. This part needs clarification from the Pine Script logic.
  }

//+------------------------------------------------------------------+
//| FVG Drawing Function                                             |
//+------------------------------------------------------------------+
void DrawFVG(int barIndex, double top, double bottom, string labelText, color fvgColor, double compare, bool isBullish, int len)
  {
   string objName = StringFormat("FVG_Box_%d", barIndex);
   string labelName = StringFormat("FVG_Label_%d", barIndex);

   double realTop = MathMax(top, bottom);
   double realBot = MathMin(top, bottom);
   double mid = (realTop + realBot) / 2;
   color boxColor = fvgColor; // MQL5 colors are opaque, transparency will be set later

   // Create FVG Box
   if (ObjectFind(0, objName) == -1)
     {
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, Time[barIndex], realTop, Time[barIndex + len], realBot);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, ColorToARGB(boxColor, 85)); // 85% transparency
      ObjectSetInteger(0, objName, OBJPROP_BACK, true);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objName, OBJPROP_ZORDER, 0);
      ArrayResize(fvgBoxesNames, fvgBoxesCount + 1);
      fvgBoxesNames[fvgBoxesCount] = objName;
      fvgBoxesCount++;

      ArrayResize(fvgCreatedBars, ArraySize(fvgCreatedBars) + 1);
      fvgCreatedBars[ArraySize(fvgCreatedBars) - 1] = barIndex;
      ArrayResize(fvgIsBullish, ArraySize(fvgIsBullish) + 1);
      fvgIsBullish[ArraySize(fvgIsBullish) - 1] = isBullish;
      ArrayResize(fvgCompareLevels, ArraySize(fvgCompareLevels) + 1);
      fvgCompareLevels[ArraySize(fvgCompareLevels) - 1] = compare;
      ArrayResize(fvgTops, ArraySize(fvgTops) + 1);
      fvgTops[ArraySize(fvgTops) - 1] = realTop;
      ArrayResize(fvgBottoms, ArraySize(fvgBottoms) + 1);
      fvgBottoms[ArraySize(fvgBottoms) - 1] = realBot;
     }
   else
     {
      // Update existing box if needed (e.g., if length changes dynamically)
      ObjectSetInteger(0, objName, OBJPROP_TIME1, Time[barIndex]);
      ObjectSetDouble(0, objName, OBJPROP_PRICE1, realTop);
      ObjectSetInteger(0, objName, OBJPROP_TIME2, Time[barIndex + len]);
      ObjectSetDouble(0, objName, OBJPROP_PRICE2, realBot);
     }

   // Create FVG Label
   if (ObjectFind(0, labelName) == -1)
     {
      double lbY = isBullish ? mid : mid - (realTop - realBot) * 0.3;
      ObjectCreate(0, labelName, OBJ_TEXT, 0, Time[barIndex], lbY);
      ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, isBullish ? clrLime : clrRed);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 9); // size.small
      ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, labelName, OBJPROP_ZORDER, 1);
      ArrayResize(fvgLabelsNames, fvgLabelsCount + 1);
      fvgLabelsNames[fvgLabelsCount] = labelName;
      fvgLabelsCount++;
     }
   else
     {
      // Update existing label if needed
      double lbY = isBullish ? mid : mid - (realTop - realBot) * 0.3;
      ObjectSetInteger(0, labelName, OBJPROP_TIME1, Time[barIndex]);
      ObjectSetDouble(0, labelName, OBJPROP_PRICE1, lbY);
      ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, isBullish ? clrLime : clrRed);
     }
  }

//+------------------------------------------------------------------+
//| FVG Cleanup Function                                             |
//+------------------------------------------------------------------+
void CleanupFVG(int rates_total, const double &close[])
  {
   for (int i = fvgBoxesCount - 1; i >= 0; i--)
     {
      int createdBar = fvgCreatedBars[i];
      bool isBullish = fvgIsBullish[i];
      double compare = fvgCompareLevels[i];
      string boxName = fvgBoxesNames[i];
      string labelName = fvgLabelsNames[i];

      int age = rates_total - createdBar;

      if (age > InpFvgMaxTrackBars)
        {
         ObjectDelete(0, boxName);
         ObjectDelete(0, labelName);
         ArrayRemove(fvgBoxesNames, i);
         ArrayRemove(fvgLabelsNames, i);
         ArrayRemove(fvgCreatedBars, i);
         ArrayRemove(fvgIsBullish, i);
         ArrayRemove(fvgCompareLevels, i);
         ArrayRemove(fvgTops, i);
         ArrayRemove(fvgBottoms, i);
         fvgBoxesCount--;
         fvgLabelsCount--;
         continue;
        }

      // Check for disrespect only if the current bar is within the check forward bars range
      if (rates_total - 1 > createdBar && rates_total - 1 <= createdBar + InpFvgCheckForwardBars)
        {
         bool disrespect = (isBullish && close[rates_total - 1] < compare) || (!isBullish && close[rates_total - 1] > compare);
         if (disrespect)
           {
            ObjectDelete(0, boxName);
            ObjectDelete(0, labelName);
            ArrayRemove(fvgBoxesNames, i);
            ArrayRemove(fvgLabelsNames, i);
            ArrayRemove(fvgCreatedBars, i);
            ArrayRemove(fvgIsBullish, i);
            ArrayRemove(fvgCompareLevels, i);
            ArrayRemove(fvgTops, i);
            ArrayRemove(fvgBottoms, i);
            fvgBoxesCount--;
            fvgLabelsCount--;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Pivot Box Drawing Function                                       |
//+------------------------------------------------------------------+
void DrawPivotBox(const PivotType& pivot, bool isHigh)
  {
   if (!InpShowZones || !pivot.valid()) return;

   string objName = StringFormat("PivotBox_%d", pivot.index);
   color colBg = isHigh ? InpZoneHighBg : InpZoneLowBg;

   if (ObjectFind(0, objName) == -1)
     {
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, Time[pivot.index], pivot.barHigh, Time[pivot.index + InpZonesRight], pivot.barLow);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, ColorToARGB(colBg, 80)); // 80% transparency
      ObjectSetInteger(0, objName, OBJPROP_BACK, true);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objName, OBJPROP_ZORDER, 0);
      ArrayResize(pivotBoxesNames, pivotBoxesCount + 1);
      pivotBoxesNames[pivotBoxesCount] = objName;
      pivotBoxesCount++;
     }
   else
     {
      ObjectSetInteger(0, objName, OBJPROP_TIME1, Time[pivot.index]);
      ObjectSetDouble(0, objName, OBJPROP_PRICE1, pivot.barHigh);
      ObjectSetInteger(0, objName, OBJPROP_TIME2, Time[pivot.index + InpZonesRight]);
      ObjectSetDouble(0, objName, OBJPROP_PRICE2, pivot.barLow);
     }

   // Manage max zones
   if (pivotBoxesCount > InpMaxZones)
     {
      ObjectDelete(0, pivotBoxesNames[0]);
      ArrayRemove(pivotBoxesNames, 0);
      pivotBoxesCount--;
     }
  }

//+------------------------------------------------------------------+
//| Target Zone Drawing Function                                     |
//+------------------------------------------------------------------+
void DrawTargetZones(int rates_total)
  {
   // Clear previous target zones and lines
   for (int i = targetZonesCount - 1; i >= 0; i--)
     {
      ObjectDelete(0, targetZonesNames[i]);
      ArrayRemove(targetZonesNames, i);
      ArrayRemove(targetZoneTops, i);
      ArrayRemove(targetZoneBottoms, i);
      targetZonesCount--;
     }
   for (int i = ArraySize(tzTopLinesNames) - 1; i >= 0; i--)
     {
      ObjectDelete(0, tzTopLinesNames[i]);
      ArrayRemove(tzTopLinesNames, i);
     }
   for (int i = ArraySize(tzBottomLinesNames) - 1; i >= 0; i--)
     {
      ObjectDelete(0, tzBottomLinesNames[i]);
      ArrayRemove(tzBottomLinesNames, i);
     }

   // Re-evaluate and draw target zones based on FVG and (future) Pullback boxes
   // This part requires the Bullish Pullback Zones logic to be translated first
   // For now, let's just draw FVG lines based on display mode

   // Determine which FVGs to display based on target zone overlap
   ArrayResize(fvgInTarget, fvgBoxesCount);
   for (int i = 0; i < fvgBoxesCount; i++)
     {
      fvgInTarget[i] = false; // Default to false
      double fvgTop = fvgTops[i];
      double fvgBot = fvgBottoms[i];

      // Check for overlap with Bullish Pullback Zones
      for (int j = 0; j < bullishPullbackBoxesCount; j++)
        {
         string pbName = bullishPullbackBoxesNames[j];
         double pbTop = ObjectGetDouble(0, pbName, OBJPROP_PRICE1);
         double pbBot = ObjectGetDouble(0, pbName, OBJPROP_PRICE2);

         if (MathMax(fvgBot, pbBot) <= MathMin(fvgTop, pbTop))
           {
            fvgInTarget[i] = true;
            break;
           }
        }
     }

   // Draw FVG lines based on display mode
   for (int i = ArraySize(fvgTopLinesNames) - 1; i >= 0; i--)
     {
      ObjectDelete(0, fvgTopLinesNames[i]);
      ArrayRemove(fvgTopLinesNames, i);
     }
   for (int i = ArraySize(fvgBottomLinesNames) - 1; i >= 0; i--)
     {
      ObjectDelete(0, fvgBottomLinesNames[i]);
      ArrayRemove(fvgBottomLinesNames, i);
     }

   if (InpShowFvg)
     {
      for (int i = 0; i < fvgBoxesCount; i++)
        {
         bool showThis = false;
         if (InpFvgDisplayMode == FVG_DISPLAY_ALL) showThis = true;
         else if (InpFvgDisplayMode == FVG_DISPLAY_IN_TARGET_ZONES && fvgInTarget[i]) showThis = true;
         else if (InpFvgDisplayMode == FVG_DISPLAY_OUTSIDE_TARGET_ZONES && !fvgInTarget[i]) showThis = true;

         if (showThis)
           {
            double fyTop = fvgTops[i];
            double fyBot = fvgBottoms[i];
            datetime x1 = Time[rates_total - 1];
            datetime x2 = Time[rates_total - 1] + PeriodSeconds(Period()); // Extend to the right

            string topLName = StringFormat("FVG_TopLine_%d", i);
            string botLName = StringFormat("FVG_BotLine_%d", i);

            if (ObjectFind(0, topLName) == -1)
              {
               ObjectCreate(0, topLName, OBJ_TREND, 0, x1, fyTop, x2, fyTop);
               ObjectSetInteger(0, topLName, OBJPROP_COLOR, ColorToARGB(clrYellow, 0));
               ObjectSetInteger(0, topLName, OBJPROP_WIDTH, 1);
               ObjectSetInteger(0, topLName, OBJPROP_STYLE, STYLE_SOLID);
               ObjectSetInteger(0, topLName, OBJPROP_RAY, true);
               ArrayResize(fvgTopLinesNames, ArraySize(fvgTopLinesNames) + 1);
               fvgTopLinesNames[ArraySize(fvgTopLinesNames) - 1] = topLName;
              }
            else
              {
               ObjectSetInteger(0, topLName, OBJPROP_TIME1, x1);
               ObjectSetDouble(0, topLName, OBJPROP_PRICE1, fyTop);
               ObjectSetInteger(0, topLName, OBJPROP_TIME2, x2);
               ObjectSetDouble(0, topLName, OBJPROP_PRICE2, fyTop);
               ObjectSetInteger(0, topLName, OBJPROP_COLOR, ColorToARGB(clrYellow, 0));
              }

            if (ObjectFind(0, botLName) == -1)
              {
               ObjectCreate(0, botLName, OBJ_TREND, 0, x1, fyBot, x2, fyBot);
               ObjectSetInteger(0, botLName, OBJPROP_COLOR, ColorToARGB(clrYellow, 0));
               ObjectSetInteger(0, botLName, OBJPROP_WIDTH, 1);
               ObjectSetInteger(0, botLName, OBJPROP_STYLE, STYLE_SOLID);
               ObjectSetInteger(0, botLName, OBJPROP_RAY, true);
               ArrayResize(fvgBottomLinesNames, ArraySize(fvgBottomLinesNames) + 1);
               fvgBottomLinesNames[ArraySize(fvgBottomLinesNames) - 1] = botLName;
              }
            else
              {
               ObjectSetInteger(0, botLName, OBJPROP_TIME1, x1);
               ObjectSetDouble(0, botLName, OBJPROP_PRICE1, fyBot);
               ObjectSetInteger(0, botLName, OBJPROP_TIME2, x2);
               ObjectSetDouble(0, botLName, OBJPROP_PRICE2, fyBot);
               ObjectSetInteger(0, botLName, OBJPROP_COLOR, ColorToARGB(clrYellow, 0));
              }
           }
         else
           {
            // Hide lines if not shown
            string topLName = StringFormat("FVG_TopLine_%d", i);
            string botLName = StringFormat("FVG_BotLine_%d", i);
            if (ObjectFind(0, topLName) != -1) ObjectDelete(0, topLName);
            if (ObjectFind(0, botLName) != -1) ObjectDelete(0, botLName);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Pivot Label Drawing Function                                     |
//+------------------------------------------------------------------+
void DrawPivotLabel(const PivotType& pivot, bool isHigh)
  {
   if (!InpShowPivots || !pivot.valid()) return;

   string labelName = StringFormat("PivotLabel_%d", pivot.index);
   color textColor = isHigh ? InpHighColor : InpLowColor;
   int labelStyle = GetMQLLabelStyle(InpPivotStyle, isHigh);
   int labelSize = GetMQLLabelSize(InpPivotSize);
   string labelText = "";

   if (InpPivotStyle == LABEL_STYLE_TEXT)
     {
      labelText = isHigh ? "H" : "L";
     }

   if (ObjectFind(0, labelName) == -1)
     {
      ObjectCreate(0, labelName, OBJ_TEXT, 0, pivot.timestamp, pivot.price);
      ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, textColor);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, labelSize);
      ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, isHigh ? ANCHOR_BOTTOM_LEFT : ANCHOR_TOP_LEFT);
      ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, labelName, OBJPROP_ZORDER, 1);
      ArrayResize(pivotLabels, pivotLabelsCount + 1);
      pivotLabels[pivotLabelsCount] = labelName;
      pivotLabelsCount++;
     }
   else
     {
      ObjectSetInteger(0, labelName, OBJPROP_TIME1, pivot.timestamp);
      ObjectSetDouble(0, labelName, OBJPROP_PRICE1, pivot.price);
      ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, textColor);
     }

   // Manage max labels
   if (pivotLabelsCount > InpMaxPivots)
     {
      ObjectDelete(0, pivotLabels[0]);
      ArrayRemove(pivotLabels, 0);
      pivotLabelsCount--;
     }
  }

//+------------------------------------------------------------------+
//| Trend Line Drawing Function                                      |
//+------------------------------------------------------------------+
vvoid DrawTrendLine(string name, bool show, color clr, ENUM_LINE_STYLE style, int width, const MqlDateTime& time[], const double& prices[], int count)
  {
   if (!show || count < 2) return;

   if (ObjectFind(0, name) == -1)
     {
      ObjectCreate(0, name, OBJ_POLYLINE, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, name, OBJPROP_STYLE, GetMQLLineStyle(style));
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
     }
   else
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, name, OBJPROP_STYLE, GetMQLLineStyle(style));
     }

   ObjectSetInteger(0, name, OBJPROP_POINTS, count);
   for (int j = 0; j < count; j++)
     {
      ObjectSetPoint(0, name, j, time[j], prices[j]);
     }
  }

//+------------------------------------------------------------------+
//| Bullish Pullback Zone Drawing Function                           |
//+------------------------------------------------------------------+
void DrawBullishPullbackZone(int barIndex, double top, double bottom)
  {
   if (!InpShowBullishPullback) return;

   string objName = StringFormat("BullishPullbackBox_%d", barIndex);
   color boxColor = InpBullishPullbackColor;

   if (ObjectFind(0, objName) == -1)
     {
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, Time[barIndex], top, Time[barIndex + InpBullishPullbackWidth], bottom);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, ColorToARGB(boxColor, 80)); // 80% transparency
      ObjectSetInteger(0, objName, OBJPROP_BACK, true);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objName, OBJPROP_ZORDER, 0);
      ArrayResize(bullishPullbackBoxesNames, bullishPullbackBoxesCount + 1);
      bullishPullbackBoxesNames[bullishPullbackBoxesCount] = objName;
      bullishPullbackBoxesCount++;
     }
   else
     {
      ObjectSetInteger(0, objName, OBJPROP_TIME1, Time[barIndex]);
      ObjectSetDouble(0, objName, OBJPROP_PRICE1, top);
      ObjectSetInteger(0, objName, OBJPROP_TIME2, Time[barIndex + InpBullishPullbackWidth]);
      ObjectSetDouble(0, objName, OBJPROP_PRICE2, bottom);
     }

   // Manage max zones
   if (bullishPullbackBoxesCount > InpMaxBullishPullbackZones)
     {
      ObjectDelete(0, bullishPullbackBoxesNames[0]);
      ArrayRemove(bullishPullbackBoxesNames, 0);
      bullishPullbackBoxesCount--;
     }
  }

//+------------------------------------------------------------------+
//| Main Logic for Pivot and Trend (needs full translation)          |
//+------------------------------------------------------------------+
void ProcessPivotsAndTrends(int i, const double &high[], const double &low[], const datetime &time[], int rates_total)
  {
   // This function needs to fully translate the Pine Script logic for pivot detection and trend drawing.
   // The Pine Script uses a stateful approach with `var` variables and a `find()` function that returns two pivots.
   // In MQL5, we need to manage these states explicitly.

   // Placeholder for the full pivot detection logic
   // For now, let's just call FindPivots to update eh and el
   FindPivots(i, high, low, time, rates_total);

   // If eh or el are valid, draw them
   if (eh.valid())
     {
      DrawPivotLabel(eh, true);
      DrawPivotBox(eh, true);
     }
   if (el.valid())
     {
      DrawPivotLabel(el, false);
      DrawPivotBox(el, false);
     }

   // Placeholder for trend drawing
   // The Pine Script uses polyline.new, which is a series of points.
   // In MQL5, we would need to manage an array of points and draw OBJ_POLYLINE or multiple OBJ_TREND lines.
   // For simplicity, let's assume we draw a single trend line between the last two valid external pivots.
   // This is a significant simplification and needs to be refined.

   // Example: Draw a line between the last two valid external pivots
   static PivotType prev_eh, prev_el;
   static bool prev_eh_valid = false, prev_el_valid = false;

   if (eh.valid())
     {
      if (prev_eh_valid)
        {
         // Draw line from prev_eh to eh
         // DrawTrendLine(extTrendLineName, InpShowExtTrend, InpExtTrendColor, InpExtTrendStyle, InpExtTrendWidth, prev_eh.timestamp, prev_eh.price, eh.timestamp, eh.price);
        }
      prev_eh.copy(eh);
      prev_eh_valid = true;
     }
   if (el.valid())
     {
      if (prev_el_valid)
        {
         // Draw line from prev_el to el
         // DrawTrendLine(extTrendLineName, InpShowExtTrend, InpExtTrendColor, InpExtTrendStyle, InpExtTrendWidth, prev_el.timestamp, prev_el.price, el.timestamp, el.price);
        }
      prev_el.copy(el);
      prev_el_valid = true;
     }

   // The internal trend logic (ih, il) also needs to be translated.
  }

//+------------------------------------------------------------------+
//| OnCalculate - Main Loop                                          |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const long &spread[])
  {
   if (rates_total < 1) return 0;

   int limit;
   if (prev_calculated == 0) // First call
     {
      limit = rates_total - 1; // Process all bars except the current incomplete one
      // Clear all objects on first run to avoid duplicates on chart refresh
      ObjectsDeleteAll(0, 0, OBJ_LABEL);
      ObjectsDeleteAll(0, 0, OBJ_RECTANGLE);
      ObjectsDeleteAll(0, 0, OBJ_POLYLINE);
      // Reset global counters
      pivotLabelsCount = 0;
      pivotBoxesCount = 0;
      bullishPullbackBoxesCount = 0;
      fvgBoxesCount = 0;
      fvgLabelsCount = 0;
      targetZonesCount = 0;
      extTrendPointsCount = 0;
      intTrendPointsCount = 0;
     }
   else
     {
      limit = rates_total - prev_calculated; // Process only new bars
     }

   for (int i = rates_total - limit; i < rates_total; i++)
     {
      // Skip incomplete bar if it's the last one and not the first calculation
      if (i == rates_total - 1 && prev_calculated != 0) continue;

      //--- Get EMA values
      double ema300_val[1], ema100_val[1], ema50_val[1], ema20_val[1];
      CopyBuffer(iEma300, 0, i, 1, ema300_val);
      CopyBuffer(iEma100, 0, i, 1, ema100_val);
      CopyBuffer(iEma50, 0, i, 1, ema50_val);
      CopyBuffer(iEma20, 0, i, 1, ema20_val);

      //--- Bullish Conditions
      int bullishConditions = 0;
      if (InpUseEma300 && close[i] > ema300_val[0]) bullishConditions++;
      if (InpUseEma100 && close[i] > ema100_val[0]) bullishConditions++;
      if (InpUseEma50 && close[i] > ema50_val[0]) bullishConditions++;
      if (InpUseEma20 && close[i] > ema20_val[0]) bullishConditions++;
      if (InpUsePriceAction && close[i] > open[i]) bullishConditions++;

      bool isBullish = (bullishConditions >= InpMinBullishConfirmation);

      //--- Process Pivots and Trends
      ProcessPivotsAndTrends(i, high, low, time, rates_total);

      //--- FVG Logic
      if (InpShowFvg && i >= 3) // Ensure enough bars for FVG calculation
        {
         // Bullish FVG
         if (low[i-1] > high[i-3])
           {
            DrawFVG(i-3, low[i-1], high[i-3], "", InpFvgBullishColor, high[i-3], true, InpFvgBoxLength);
           }
         // Bearish FVG
         if (high[i-1] < low[i-3])
           {
            DrawFVG(i-3, low[i-3], high[i-1], "", InpFvgBearishColor, low[i-3], false, InpFvgBoxLength);
           }
        }

      //--- Bullish Pullback Zones
      if (InpDetectBullishPullback && isBullish && eh.valid() && el.valid() && eh.price > el.price)
        {
         DrawBullishPullbackZone(eh.index, eh.barHigh, el.barLow);
        }
     }

   //--- Cleanup FVG boxes and labels (after processing all bars)
   CleanupFVG(rates_total, close);

   //--- Draw Target Zones and FVG lines (after all FVG and Pullback boxes are processed)
   DrawTargetZones(rates_total);

   return rates_total;
  }

//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| Pivot Label Drawing Function (Updated to handle MQL5 objects)    |
//+------------------------------------------------------------------+
void DrawPivotLabel(const PivotType& pivot, bool isHigh)
  {
   if (!InpShowPivots || !pivot.valid()) return;

   string labelName = StringFormat("PivotLabel_%d", pivot.index);
   color textColor = isHigh ? InpHighColor : InpLowColor;
   int labelStyle = GetMQLLabelStyle(InpPivotStyle, isHigh);
   int labelSize = GetMQLLabelSize(InpPivotSize);
   string labelText = "";

   if (InpPivotStyle == LABEL_STYLE_TEXT)
     {
      labelText = isHigh ? "H" : "L";
     }

   // Delete old label if it exists and is not the current one
   if (ObjectFind(0, labelName) != -1)
     {
      ObjectDelete(0, labelName);
     }

   ObjectCreate(0, labelName, OBJ_TEXT, 0, pivot.timestamp, pivot.price);
   ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, labelSize);
   ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, isHigh ? ANCHOR_BOTTOM_LEFT : ANCHOR_TOP_LEFT);
   ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, labelName, OBJPROP_ZORDER, 1);

   // Add to array for cleanup
   ArrayResize(pivotLabels, pivotLabelsCount + 1);
   pivotLabels[pivotLabelsCount] = labelName;
   pivotLabelsCount++;

   // Manage max labels
   if (pivotLabelsCount > InpMaxPivots)
     {
      ObjectDelete(0, pivotLabels[0]);
      ArrayRemove(pivotLabels, 0);
      pivotLabelsCount--;
     }
  }

//+------------------------------------------------------------------+
//| ProcessPivotsAndTrends - Main logic for pivot detection and trend|
//+------------------------------------------------------------------+
void ProcessPivotsAndTrends(int i, const double &high[], const double &low[], const datetime &time[], int rates_total)
  {
   static bool s_dir = true; // Corresponds to 'var bool dir = true'
   static PivotType s_h;     // Corresponds to 'var pivotType h = pivotType.new(high, time, bar_index, high, low)'
   static PivotType s_l;     // Corresponds to 'var pivotType l = pivotType.new(low, time, bar_index, high, low)'

   // Initialize on first call or if invalid
   if (s_h.invalid())
     {
      s_h.set(high[i], time[i], i, high[i], low[i]);
      s_l.set(low[i], time[i], i, high[i], low[i]);
     }

   PivotType newh, newl;
   newh.invalidate();
   newl.invalidate();

   if (s_dir)
     {
      if (low[i] < s_l.price)
        {
         if (high[i] > s_h.price)
           {
            s_h.set(high[i], time[i], i, high[i], low[i]);
           }
         newh.copy(s_h);
         s_dir = false;
         s_h.set(high[i], time[i], i, high[i], low[i]);
         s_l.set(low[i], time[i], i, high[i], low[i]);
        }
      else if (high[i] > s_h.price)
        {
         s_l.set(low[i], time[i], i, high[i], low[i]);
         s_h.set(high[i], time[i], i, high[i], low[i]);
        }
     }
   else // !s_dir
     {
      if (high[i] > s_h.price)
        {
         if (low[i] < s_l.price)
           {
            s_l.set(low[i], time[i], i, high[i], low[i]);
           }
         newl.copy(s_l);
         s_dir = true;
         s_h.set(high[i], time[i], i, high[i], low[i]);
         s_l.set(low[i], time[i], i, high[i], low[i]);
        }
      else if (low[i] < s_l.price)
        {
         s_h.set(high[i], time[i], i, high[i], low[i]);
         s_l.set(low[i], time[i], i, high[i], low[i]);
        }
     }

   // Update global external pivots
   if (newh.valid()) eh.copy(newh);
   if (newl.valid()) el.copy(newl);

   // Draw external pivots
   if (eh.valid())
     {
      DrawPivotLabel(eh, true);
      DrawPivotBox(eh, true);
     }
   if (el.valid())
     {
      DrawPivotLabel(el, false);
      DrawPivotBox(el, false);
     }

   // --- Trend Drawing (External) ---
   // Add valid external pivots to the array for polyline drawing
   if (eh.valid())
     {
      ArrayResize(extTrendTimes, extTrendPointsCount + 1);
      ArrayResize(extTrendPrices, extTrendPointsCount + 1);
      extTrendTimes[extTrendPointsCount] = eh.timestamp;
      extTrendPrices[extTrendPointsCount] = eh.price;
      extTrendPointsCount++;
     }
   if (el.valid())
     {
      ArrayResize(extTrendTimes, extTrendPointsCount + 1);
      ArrayResize(extTrendPrices, extTrendPointsCount + 1);
      extTrendTimes[extTrendPointsCount] = el.timestamp;
      extTrendPrices[extTrendPointsCount] = el.price;
      extTrendPointsCount++;
     }

   // Draw the external trend polyline
   DrawTrendLine(extTrendLineName, InpShowExtTrend, InpExtTrendColor, InpExtTrendStyle, InpExtTrendWidth, extTrendTimes, extTrendPrices, extTrendPointsCount);

   // --- Internal Trend (ih, il) ---
   // Update global internal pivots (ih, il)
   if (newh.valid()) ih.copy(newh);
   if (newl.valid()) il.copy(newl);

   // Add valid internal pivots to the array for polyline drawing
   if (ih.valid())
     {
      ArrayResize(intTrendTimes, intTrendPointsCount + 1);
      ArrayResize(intTrendPrices, intTrendPointsCount + 1);
      intTrendTimes[intTrendPointsCount] = ih.timestamp;
      intTrendPrices[intTrendPointsCount] = ih.price;
      intTrendPointsCount++;
     }
   if (il.valid())
     {
      ArrayResize(intTrendTimes, intTrendPointsCount + 1);
      ArrayResize(intTrendPrices, intTrendPointsCount + 1);
      intTrendTimes[intTrendPointsCount] = il.timestamp;
      intTrendPrices[intTrendPointsCount] = il.price;
      intTrendPointsCount++;
     }

   // Draw the internal trend polyline
   DrawTrendLine(intTrendLineName, InpShowIntTrend, InpIntTrendColor, InpIntTrendStyle, InpIntTrendWidth, intTrendTimes, intTrendPrices, intTrendPointsCount);
  }
//+------------------------------------------------------------------+
//| OnCalculate - Main Loop (Updated to call ProcessPivotsAndTrends) |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const long &spread[])
  {
   if (rates_total < 1) return 0;

   int limit;
   if (prev_calculated == 0) // First call
     {
      limit = rates_total - 1; // Process all bars except the current incomplete one
      // Clear all objects on first run to avoid duplicates on chart refresh
      ObjectsDeleteAll(0, 0, OBJ_TEXT); // Clear labels
      ObjectsDeleteAll(0, 0, OBJ_RECTANGLE); // Clear boxes
      ObjectsDeleteAll(0, 0, OBJ_TREND); // Clear trend lines
      ObjectsDeleteAll(0, 0, OBJ_POLYLINE); // Clear polylines
      // Reset global counters
      pivotLabelsCount = 0;
      pivotBoxesCount = 0;
      bullishPullbackBoxesCount = 0;
      fvgBoxesCount = 0;
      fvgLabelsCount = 0;
      targetZonesCount = 0;
      extTrendPointsCount = 0;
      intTrendPointsCount = 0;

      // Reset static variables in FindPivots
      // This is tricky in MQL5. A common way is to use a flag or re-initialize.
      // For now, assuming they are implicitly reset on indicator re-initialization.
     }
   else
     {
      limit = rates_total - prev_calculated; // Process only new bars
     }

   for (int i = rates_total - limit; i < rates_total; i++)
     {
      // Skip incomplete bar if it's the last one and not the first calculation
      if (i == rates_total - 1 && prev_calculated != 0) continue;

      //--- Get EMA values
      double ema300_val[1], ema100_val[1], ema50_val[1], ema20_val[1];
      CopyBuffer(iEma300, 0, i, 1, ema300_val);
      CopyBuffer(iEma100, 0, i, 1, ema100_val);
      CopyBuffer(iEma50, 0, i, 1, ema50_val);
      CopyBuffer(iEma20, 0, i, 1, ema20_val);

      //--- Bullish Conditions
      int bullishConditions = 0;
      if (InpUseEma300 && close[i] > ema300_val[0]) bullishConditions++;
      if (InpUseEma100 && close[i] > ema100_val[0]) bullishConditions++;
      if (InpUseEma50 && close[i] > ema50_val[0]) bullishConditions++;
      if (InpUseEma20 && close[i] > ema20_val[0]) bullishConditions++;
      if (InpUsePriceAction && close[i] > open[i]) bullishConditions++;

      bool isBullish = (bullishConditions >= InpMinBullishConfirmation);

      //--- Process Pivots and Trends
      ProcessPivotsAndTrends(i, high, low, time, rates_total);

      //--- FVG Logic
      if (InpShowFvg && i >= 3) // Ensure enough bars for FVG calculation
        {
         // Bullish FVG
         if (low[i-1] > high[i-3])
           {
            DrawFVG(i-3, low[i-1], high[i-3], "", InpFvgBullishColor, high[i-3], true, InpFvgBoxLength);
           }
         // Bearish FVG
         if (high[i-1] < low[i-3])
           {
            DrawFVG(i-3, low[i-3], high[i-1], "", InpFvgBearishColor, low[i-3], false, InpFvgBoxLength);
           }
        }

      //--- Bullish Pullback Zones
      if (InpDetectBullishPullback && isBullish && eh.valid() && el.valid() && eh.price > el.price)
        {
         DrawBullishPullbackZone(eh.index, eh.barHigh, el.barLow);
        }
     }

   //--- Cleanup FVG boxes and labels (after processing all bars)
   CleanupFVG(rates_total, close);

   //--- Draw Target Zones and FVG lines (after all FVG and Pullback boxes are processed)
   DrawTargetZones(rates_total);

   return rates_total;
  }

//+------------------------------------------------------------------+





//+------------------------------------------------------------------+
//| Bullish Pullback Zone Drawing Function                           |
//+------------------------------------------------------------------+
void DrawBullishPullbackZone(int barIndex, double top, double bottom)
  {
   if (!InpShowBullishPullback) return;

   string objName = StringFormat("BullishPullbackBox_%d", barIndex);
   color boxColor = InpBullishPullbackColor;

   if (ObjectFind(0, objName) == -1)
     {
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, Time[barIndex], top, Time[barIndex + InpBullishPullbackWidth], bottom);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, ColorToARGB(boxColor, 80)); // 80% transparency
      ObjectSetInteger(0, objName, OBJPROP_BACK, true);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objName, OBJPROP_ZORDER, 0);
      ArrayResize(bullishPullbackBoxesNames, bullishPullbackBoxesCount + 1);
      bullishPullbackBoxesNames[bullishPullbackBoxesCount] = objName;
      bullishPullbackBoxesCount++;
     }
   else
     {
      ObjectSetInteger(0, objName, OBJPROP_TIME1, Time[barIndex]);
      ObjectSetDouble(0, objName, OBJPROP_PRICE1, top);
      ObjectSetInteger(0, objName, OBJPROP_TIME2, Time[barIndex + InpBullishPullbackWidth]);
      ObjectSetDouble(0, objName, OBJPROP_PRICE2, bottom);
     }

   // Manage max zones
   if (bullishPullbackBoxesCount > InpMaxBullishPullbackZones)
     {
      ObjectDelete(0, bullishPullbackBoxesNames[0]);
      ArrayRemove(bullishPullbackBoxesNames, 0);
      bullishPullbackBoxesCount--;
     }
  }


