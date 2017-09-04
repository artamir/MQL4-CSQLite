//+------------------------------------------------------------------+
//|                                                    Subsystem.mqh |
//|                                          Copyright 2016, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, artamir"
#property link      "https://www.mql5.com"
#property strict

#define SUBSYSTEM
#ifndef BASE
   #include <SQLite_v2.1\csqlite_base.mqh>
#endif    

class CSubsystem{
   protected:
   CSQLiteBase *m_pDb;
   CSQLiteQueryBuilder  m_qb;
   string               m_tbl;
   
   virtual void StdColumns(CArrayKeyVal &columns)     {              }
   virtual void CustomColumns(CArrayKeyVal &columns)  {              }
   
   public:
   virtual bool   Init(CSQLiteBase *pDb)              {m_pDb=pDb; return(true);}
   virtual string GetTableName(void)                  {return(m_tbl);          }
};