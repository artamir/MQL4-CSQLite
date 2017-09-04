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
int strcpy(uchar &dst[],int src);
long strcpy(uchar &dst[],long src);
#import
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long strcpy(uchar &dst[],long src)
  {
   if(_IsX64)
      return(msvcrt::strcpy(dst,src));
   else
      return(msvcrt::strcpy(dst,(int)src)); 
  }
//+------------------------------------------------------------------+
