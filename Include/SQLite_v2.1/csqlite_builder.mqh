//+------------------------------------------------------------------+
//|                                              csqlite_builder.mqh |
//|                                          Copyright 2016, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, artamir"
#property link      "https://www.mql5.com"
#property strict

class CSQLiteBuilder{
   private:
      
   public:
      CSQLiteBuilder();
      ~CSQLiteBuilder();
      
   string buildQuery(string &columns);
   
};
