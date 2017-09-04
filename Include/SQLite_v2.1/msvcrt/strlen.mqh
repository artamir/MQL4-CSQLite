//+------------------------------------------------------------------+
//|                                                             User |
//|                    Copyright © 2006-2014, FINEXWARE Technologies |
//|                                                www.FINEXWARE.com |
//|      programming & development - Alexey Sergeev, Boris Gershanov |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006-2014, FINEXWARE Technologies"
#property link      "www.FINEXWARE.com"
#property version   "1.00"

#import "msvcrt.dll"
int strlen(int src);
int strlen(long src);
#import
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int strlen(long src)
  {
   if(_IsX64)
      return(msvcrt::strlen(src));
   else
      return(msvcrt::strlen((int)src)); 
  }
//+------------------------------------------------------------------+
