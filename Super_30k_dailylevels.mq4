//+------------------------------------------------------------------+
//|                                                    Super_30k.mq4 |
//|                                     Copyright 2018, Barziy Illya |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Barziy Illya"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


//--- Inputs
input bool   lotFixed         =true;
input bool   reverse = false;
input double fixedLotSize     =0.1;
input int    unfixedLotPerc   =50;
input int    swapSize         =3;
input double    slSize           =50;
input int    tpInitSize       =150;
input int    knowLevelAfter   =0;
input int    reviseOrder      =4;   
input int    ordersTaken      =3;

//--- Just variables\
static double sl = 50;
double vh[200], vl[200]; // Stores values of stractals ove the last 200 candles
double uniup[5], unidown[5]; //Stores the unique valuse of 5 previous fractals
double levup[10], levdown[10]; //Considerable levels in the high/low part
double curlevup[10], curlevdown[10]; //Current considerable levels in the high/low part
double exclevup[10], exclevdown[10]; //Counting the last broken levels

int Bar = 0; // May be should be long instead
int Magic = 1; //It is uded to revise orders
datetime LastActiontime; //To execue not evety tick

void OnTick()
{
   trStop(slSize);
   if (LastActiontime!=Time[0])
   {  
     LastActiontime=Time[0];
     Bar++;
     TrailingAlls(slSize);
     //To avoid overflow. Yeah, a bit crappy 
     if (Bar > 10000)
         Bar = 0;
         
     //if ( Bar % reviseOrder ==0)
     if (true)
     {
         //forming vh and vl
         countFractals();
         //forming uniup and unidown
         //getUniqueFractals(knowLevelAfter);
         /*
         Alert("Outputting the uniqe fractals up");
         alertArray(uniup);
         Alert("Outputting the uniqe fractals down");
         alertArray(unidown);
         */
         //forming LevelsUp and LevelsDown
         //getLevelsUp();
         //getLevelsDown();
         /*
         Alert("Outputting the levels up");
         alertArray(levup);
         Alert("Outputting the levels down");
         alertArray(levdown);
         */
         //forming CurLevelsUp and CurLevelsDown
         //getCurLevelsUp(ordersTaken);
         //getCurLevelsDown(ordersTaken);
         /*
         Alert("Outputting the Current levels up");
         alertArray(curlevup);
         Alert("Outputting the Current levels down");
         alertArray(curlevdown);
         */
         //Execution part
         closeAllStop(Magic);
         placeOrders(reverse);
         
         
   
      }
   }
  
}

/*
Note: the main logic part is in the CutLevUp
So cahnge that function for the optimization o logic
Other stuff is written properly
*/



//Takes previous fractals over the range of 200 candles
//May be optimized later, by calculating only the last 4-5 values, shiftiong the other. 
void countFractals()
{   
   for(int i = 0; i < ordersTaken; i++)
      {
         curlevup[i] = High[i]; 
         curlevdown[i] = Low[i];         
      } 
   /*
   double val_high, val_low;
   for(int i=198; i>=0; i--)
   {   
      
      val_high = iFractals(NULL, 0, MODE_UPPER,i);
      if (val_high > 0)  vh[i] = High[i];
      else               vh[i] = vh[i+1];

      val_low = iFractals(NULL, 0, MODE_LOWER,i);
      if (val_low > 0)  vl[i] = Low[i];
      else              vl[i] = vl[i+1];
      
      vh[i] = High[i];
      vl[i] = Low[i];
      for(int i = 0; i < ordersToTake; i++)
      {
         curlevup[i] = levup[i]; 
         curlevdown[i] = levdown[i];         
      }
   } 
   */
}

//Getting unique values
//Bug to be fixed - I think that all the spaces in the array will be filed. 
//Otherwise it can work inadequate.
//Uning delay right here. It's easier.
void getUniqueFractals(int delay)
{
   ArrayFill(uniup,0,ArraySize(uniup),0);
   ArrayFill(unidown,0,ArraySize(unidown),0); //Nullifying the array
   
   for(int i=1+delay; i<=198; i++)
   { 
      if (!contains(uniup, vh[i])) 
         placeLast(uniup, vh[i]);
      if (!contains(unidown, vl[i])) 
         placeLast(unidown, vl[i]);   
   }  

}

//Checks if an array contains an element
bool contains(double& theArray[], double elem)
{
   for(int i = 0; i < ArraySize(theArray); i++){
      if (theArray[i] == elem)   return(true);
   }
   return(false);
}

//Function to place element in the first zero place
//Note: Will do nothing if array is full - good!
void placeLast(double& theArray[], double elem)
{
   for(int i = 0; i < ArraySize(theArray); i++){
      if (theArray[i] == 0)
      {
         theArray[i] = elem;
         break;
      }
   }
}

//Function places the new element at the first place and shifts the other elements
void placeFirst(double& theArray[], double elem)
{
   for(int i =  ArraySize(theArray) - 1; i >=0; i--)
   {
      if (i==0)  theArray[i] = elem;
      else theArray[i] = theArray[i-1];
   }
}

//Computing the levUp
void getLevelsUp()
{  
   //Excluding unwanted levels
   getExcludedLevelsUp();
   for(int i = 0; i < ArraySize(uniup); i++)
   {
      if ( !(contains(exclevup, uniup[i])) || !(contains(levup, uniup[i])) )
         placeFirst(levup, uniup[i]);        
   }
}

//computing the levDown
void getLevelsDown()
{  
   //Excluding unwanted levels
   getExcludedLevelsDown();
   for(int i = 0; i < ArraySize(unidown); i++)
   {
      if ( !(contains(exclevdown, unidown[i])) || !(contains(levdown, unidown[i])) )
         placeFirst(levdown, unidown[i]);        
   }
}

//Counting the excluded levels Up
//Should place only unique values.
void getExcludedLevelsUp()
{  
   for(int i = ArraySize(uniup) - 1; i >= 0 ; i--)
   {
      for(int j = i - 1; j >= 0 ; j--)
      {
         if ( (uniup[j] > uniup[i]) || (uniup[i] < Ask) )
            if (!contains(uniup, uniup[i]) )
               placeFirst(uniup,uniup[i] );     
      }
   }
}

//Counting the excluded levels Down
//Should place only unique values.
void getExcludedLevelsDown()
{  
   for(int i = ArraySize(unidown) - 1; i >= 0 ; i--)
   {
      for(int j = i - 1; j >= 0 ; j--)
      {
         if ( (unidown[j] < unidown[i]) || (unidown[i] > Ask) )
            if ( !contains(unidown, unidown[i]) )
               placeFirst(unidown,unidown[i] );     
      }
   }
}


//Computing the CurLevUp
//Simply copying first prices yet
void getCurLevelsUp(int ordersToTake)
{  
   //Erasing the previous values
   ArrayFill(curlevup,0,ArraySize(curlevup), 0);
   for(int i = 0; i < ordersToTake; i++)
   {
      curlevup[i] = levup[i];        
   }
}

//computing the CurlevDown
//Simply copying first prices yet
void getCurLevelsDown(int ordersToTake)
{  
   //Erasing the previous values
   ArrayFill(curlevdown,0,ArraySize(curlevdown), 0);
   for(int i = 0; i < ordersToTake; i++)
   {
      curlevdown[i] = levdown[i];        
   }
}


//claring the LevUp from unwanted levels
//Note! I already sort the stuff here, so it looks easier
void clearLevelsUp()
{  
   for(int i = 0; i < ArraySize(levup); i++)
   {
      if (levup[i] <= Ask ) 
        levup[i] = 0;        
   }
   sortUp(levup);
}

//claring the LevDown from unwanted levels
//Note! I already sort the stuff here, so it looks easie
void clearLevelsDown()
{  
   for(int i = 0; i < ArraySize(levdown); i++)
   {
      if (levup[i] >= Ask ) 
        levup[i] = 0;        
   }
   sortDown(levdown);
}

//Function to shuffle the array so that it is in ascdending order, and then go the zeroes
void sortUp(double& theArray[])
{
   ArraySort(theArray,WHOLE_ARRAY,0,MODE_ASCEND);
   int j = 0;
   for(int i = 0; i < ArraySize(theArray); i++){
      if (theArray[i] != 0)
      {
         theArray[j] = theArray[i];
         theArray[i] = 0;
         j++;
      }
   }
}

//Function to shuffle the array so that it is in ascdending order, and then go the zeroes
void sortDown(double& theArray[])
{
   ArraySort(theArray,WHOLE_ARRAY,0,MODE_DESCEND);
}

//Function to execute orders form CurLevUp and CurLevDown
void placeOrders(bool rev)
{
   for (int i = 0; i < ArraySize(curlevup) ; i++)
   {
      if (curlevup[i] > 0)
      {
         if (rev == false)
            OrderSend(Symbol(),OP_BUYSTOP,orderSize(),orderPriceUp(curlevup[i]),3,lossSizeUp(curlevup[i]),profitSizeUp(curlevup[i]),"Buy",Magic,0,clrBlue);
         if (rev == true)
            OrderSend(Symbol(),OP_SELLSTOP,orderSize(),orderPriceDown(curlevup[i]),3,lossSizeDown(curlevup[i]),profitSizeDown(curlevdown[i]),"Sell",Magic,0,clrRed);
         
      }
   }
      for (int i = 0; i < ArraySize(curlevdown) ; i++)
   {
      if (curlevdown[i] > 0)
         {
         if (rev == false)
            OrderSend(Symbol(),OP_SELLSTOP,orderSize(),orderPriceDown(curlevdown[i]),3,lossSizeDown(curlevdown[i]),profitSizeDown(curlevdown[i]),"Sell",Magic,0,clrRed);
         if (rev == true)
            OrderSend(Symbol(),OP_BUYSTOP,orderSize(),orderPriceUp(curlevdown[i]),3,lossSizeUp(curlevdown[i]),profitSizeUp(curlevdown[i]),"Buy",Magic,0,clrBlue);
         }
   }
   
}

void alertArray(double& theArray[])
{
   for (int i=0; i < ArraySize(theArray) ; i++ )
      if (theArray[i] > 0)
         Alert("Value ", i, " = ",theArray[i]);
}

//Function to calculated needed ordersize
//Not tested. May be bugged yet
double orderSize()
{
   if (lotFixed == True)
      return (fixedLotSize);
   else
   {
      Print(NormalizeDouble(AccountBalance() * unfixedLotPerc / 100000, 2 ));
      return (NormalizeDouble(AccountBalance() * unfixedLotPerc/ 100000, 2 ));
   }
}


//Functios to calculate stop loss size
//Not tested. May be bugged yet
double lossSizeUp(double price)
{
   //Alert("SENT STOP LOSS", price - slSize * Point ," FOR ", price);
   return (price - slSize * Point);
}

double lossSizeDown(double price)
{
   return (price + slSize * Point);
}

//Functios to calculate take profit size
//Not tested. May be bugged yet
double profitSizeUp(double price)
{
   return (price + tpInitSize * Point);
}

double profitSizeDown(double price)
{
   return (price - tpInitSize * Point);
}

//Functios to calculate the price of stop order
//Not tested. May be bugged yet
double orderPriceUp(double price)
{
   return (price + swapSize * Point);
}

double orderPriceDown(double price)
{
   return (price - swapSize * Point);
}

//Used to close all the orders, that are stop
void  closeAllStopOld(int magic)
{
     for (int i = OrdersTotal()-1; i>=0; i--)
     {
      if( OrderSelect(i, SELECT_BY_POS, MODE_TRADES)== true)
         {
           if(OrderSymbol() == Symbol()&& OrderMagicNumber() == magic)
              {
               if( (OrderType() == OP_BUYSTOP) || (OrderType() == OP_SELLSTOP) )
                 {
                     if (!OrderClose( OrderTicket(),OrderLots(), Bid,3))
                     Print ("Failed to close order");
                 }

               }
          }
                 
      }
}

void  closeAllStop(int magic)
{
int total = OrdersTotal();
  for(int i=total-1;i>=0;i--)
  {
    OrderSelect(i, SELECT_BY_POS);
    int type   = OrderType();
    bool result = false;
    Alert("TRYING TOCLOSE ORSDER");
    switch(type)
    {
    /*
      //Close opened long positions
      case OP_BUYSTOP       : result = OrderDelete( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5, Red );
                          break;      
      //Close opened short positions
      case OP_SELLSTOP      : result = OrderDelete( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 5, Red );
     */
     //Close opened long positions
      case OP_BUYSTOP       : result = OrderDelete( OrderTicket(), Red );
                          break;      
      //Close opened short positions
      case OP_SELLSTOP      : result = OrderDelete( OrderTicket(), Red );
                          
    }
    if(result == false)
    {
      Alert("Order " , OrderTicket() , " failed to close. Error:" , GetLastError() );
      Sleep(3000);
    }  
  }
}


//Trailing stop function. Should be optimised!!!
void trStop(int stop) 
{  
   for (int i=0; i < OrdersTotal(); i++)
   {
      if( OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol())
         {
            if( (OrderType() == OP_BUY) && (Bid- OrderOpenPrice() > stop * Point) )
            {
               if(OrderStopLoss()< Bid - stop * Point)
               {
                  OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid - stop * Point,4),OrderTakeProfit(),0,Blue);
                  Print("Bid - ",Bid," TrailingStop - ",stop," OrderStopLoss - ",OrderStopLoss()," Bid-Trailingstop*Point - ",DoubleToStr(Bid-stop*Point,6)); 
               }
            } 
            if( (OrderType() == OP_SELL) && (OrderOpenPrice()- Ask > stop * Point) )
            {
               if(OrderStopLoss() > Ask + stop * Point )
               {
                  OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble( Ask + stop * Point,4),OrderTakeProfit(),0,Red);
                  Print("Bid - ",Bid," TrailingStop - ",stop," OrderStopLoss - ",OrderStopLoss()," Bid-Trailingstop*Point - ",DoubleToStr(Ask + stop*Point,6)); 
               }
            } 
          }
      }
   }         
}


void TrailingAlls(int trail)
  {
   if(trail==0)
      return;
//----
   double stopcrnt;
   double stopcal;
   int trade;
   int trades=OrdersTotal();
   double profitcalc;
   for(trade=0;trade<trades;trade++)
     {
      OrderSelect(trade,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol())
         {
         //continue;
         //LONG
         if(OrderType()==OP_BUY)
           {
            stopcrnt=OrderStopLoss();
            stopcal=Bid-(trail*Point);
            profitcalc=OrderTakeProfit();
            if (stopcrnt==0)
              {
               OrderModify(OrderTicket(),OrderOpenPrice(),stopcal,profitcalc,0,Blue);
              }
            else
               if(stopcal>stopcrnt)
                 {
                  OrderModify(OrderTicket(),OrderOpenPrice(),stopcal,profitcalc,0,Blue);
                 }
            }
         }//LONG
         //Shrt
         if(OrderType()==OP_SELL)
           {
            stopcrnt=OrderStopLoss();
            stopcal=Ask+(trail*Point);
            profitcalc=OrderTakeProfit();
            if (stopcrnt==0)
              {
               OrderModify(OrderTicket(),OrderOpenPrice(),stopcal,profitcalc,0,Red);
              }
            else
               if(stopcal<stopcrnt)
                 {
                  OrderModify(OrderTicket(),OrderOpenPrice(),stopcal,profitcalc,0,Red);
                 }
           }
      }
  }//Shrt