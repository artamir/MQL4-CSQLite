//+------------------------------------------------------------------+
//|                                                       levels.mqh |
//|                                          Copyright 2016, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, artamir"
#property link      "https://www.mql5.com"
#property strict

#ifndef SUBSYSTEM
   #include <SQLite_v2.1\Subsystems\Subsystem.mqh>
#endif 
   
class CLevels :public CSubsystem{
   protected:
      virtual void StdColumns( CArrayKeyVal &columns );
   
   public:
      CLevels();
      ~CLevels(){};
      
   public:
      virtual  bool     Init( CSQLiteBase* pDb );
               int      Add( int nr, double pr, ENUM_DTY dty, int ty, double lot, int net_id, int tp_net_id=0, int is_add_level=0 );
               int      Add(LevelsStructure& level);
};

void CLevels::CLevels(void){
   m_tbl = "table_levels";
}

bool CLevels::Init( CSQLiteBase* pDb ){
   bool result=true;
   CSubsystem::Init( pDb );
   
   CArrayKeyVal columns;
   StdColumns( columns );
   m_pDb.CreateOrUpdateTable( m_tbl, columns );
   
   return( result );
}

int CLevels::Add( int nr, double pr, ENUM_DTY dty, int ty, double lot, int net_id, int tp_net_id=0, int is_add_level=0 ){
   int result=-1;
   CArrayKeyVal insert;
                insert.Add( "NR",            nr );
                insert.Add( "PR",            pr );
                insert.Add( "DTY",           dty );
                insert.Add( "TY",            ty );
                insert.Add( "LOT",           lot );
                insert.Add( "NET_ID",        net_id );
                insert.Add( "TP_NET_ID",     tp_net_id );
                insert.Add( "IS_ADD_LEVEL",  is_add_level );
   
   result=m_pDb.Insert( m_tbl, insert);
   return( result );      
}

int CLevels::Add(LevelsStructure &level){
   int result=-1;
   CArrayKeyVal insert;
                insert.Add( "NR",            level.nr );
                insert.Add( "PR",            level.pr );
                insert.Add( "DTY",           level.dty );
                insert.Add( "TY",            level.ty );
                insert.Add( "LOT",           level.lot );
                insert.Add( "NET_ID",        level.net_id );
                insert.Add( "IS_PARENT",     level.is_parent);
                insert.Add( "DONT_SEND",     level.dont_send);
                insert.Add( "TP_NET_ID",     level.tp_net_id );
                insert.Add( "IS_ADD_LEVEL",  level.is_add_level );
                insert.Add( "ThisPrice",     level.this_price );
                insert.Add( "ThisStep",      level.this_step );
                insert.Add( "Ask",           level.ask );
                insert.Add( "Bid",           level.bid );
   result=m_pDb.Insert( m_tbl, insert);
   return( result );
}

void CLevels::StdColumns( CArrayKeyVal &columns ){
   m_qb.buildColumn( columns,"_ID",       SQLITE_TYPE_INTEGER,true, true );
   m_qb.buildColumn( columns,"NR",        SQLITE_TYPE_INTEGER,false,false,false,true );
   m_qb.buildColumn( columns,"PR",        SQLITE_TYPE_FLOAT);
   //m_qb.buildColumnDefaultValue( columns, (string)0.0 );
   m_qb.buildColumn( columns,"IS_PARENT", SQLITE_TYPE_INTEGER);
   m_qb.buildColumn( columns,"TY",        SQLITE_TYPE_INTEGER);
   m_qb.buildColumn( columns,"DTY",       SQLITE_TYPE_INTEGER);
   m_qb.buildColumn( columns,"LOT",       SQLITE_TYPE_FLOAT );
   m_qb.buildColumn( columns,"NET_ID",    SQLITE_TYPE_INTEGER,false,false,false,true );
   m_qb.buildColumn( columns, "DONT_SEND",     SQLITE_TYPE_INTEGER);
   m_qb.buildColumn( columns,"TP_NET_ID", SQLITE_TYPE_INTEGER);
   //m_qb.buildColumnDefaultValue( columns, (string)0 );
   m_qb.buildColumn( columns,"IS_ADD_LEVEL", SQLITE_TYPE_INTEGER );
   m_qb.buildColumn( columns,"ThisPrice", SQLITE_TYPE_FLOAT);
   m_qb.buildColumn( columns,"ThisStep",SQLITE_TYPE_INTEGER);
   m_qb.buildColumn( columns,"Ask", SQLITE_TYPE_FLOAT);
   m_qb.buildColumn( columns,"Bid",SQLITE_TYPE_FLOAT);
}