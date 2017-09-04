//+------------------------------------------------------------------+
//|                                                CSQLiteCursor.mqh |
//|                                          Copyright 2016, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, artamir"
#property link      "https://www.mql5.com"
#property strict

#ifndef BASE
#include <SQLite_v2.1\csqlite_array_string.mqh>
#include <SQLite_v2.1\csqlite_array_obj.mqh>
#include <SQLite_v2.1\csqlite_ckeyval.mqh>
#include <SQLite_v2.1\csqlite.mqh>
#endif 

int CSQLiteCursorCounter=0;

//class CSQLiteCursor : public CObject{
class CSQLiteCursor{
   private: 
      CSQLite        *m_pConnector;
      int             m_stmt;//query handle
      uint            m_ColumnCount;
      CArrayString    m_ColumnNameArray;
      CArrayString    m_ColumnTypeArray;
      bool            m_Initialized;
      
      int             m_ThisRowNumber;
   public:
               CSQLiteCursor(CSQLite *pConnector){
                  m_pConnector=pConnector;
                  m_Initialized=false;
                  DPrint("Created cursor stmt = "+(string)m_pConnector.Stmt());
                  Init();
                  CSQLiteCursorCounter++;
               };
               ~CSQLiteCursor(){
                  DPrint("Deleted cursor stmt = "+(string)m_stmt);
                  Drop();
                  CSQLiteCursorCounter--;
               };
               
      void     Init(){
                  if(!m_pConnector.is_prepared()){
                     DPrint("query handle = "+(string)m_pConnector.Stmt());
                     Drop();
                     return;
                  }
                  
                  m_stmt = m_pConnector.Stmt();
                  m_ColumnCount=GetColumnCount();
                  SetColumnArrays();
                  
                  m_Initialized=true;
                  m_ThisRowNumber = -1;
                  
               };           
      void     Reset(){
                  m_pConnector.reset(m_stmt);
                  Init();
               }               
      void     Drop(){
                  m_ColumnNameArray.Shutdown();
                  m_ColumnTypeArray.Shutdown();
                  m_ColumnCount=0;
                  m_Initialized=false;
                  
                  m_ThisRowNumber = -1;
                  
                  if(m_stmt){
                     m_pConnector.finalize(m_stmt);
                  }
                  
               };
               
      uint     GetColumnCount(){
                  uint r=m_ColumnCount;
                  if(!m_Initialized){
                     r=m_pConnector.column_count(m_stmt);
                  }
                  return(r);
               };
               
      string   GetColumnName(int column_index){
                  string s="";
                  if(!m_Initialized){
                     s=m_pConnector.column_name(m_stmt, column_index);
                  }else{
                     s=m_ColumnNameArray[column_index];
                  }
                  return(s);
               };
      
      string   GetColumnType(int column_index){
                  string s="";
                  if(!m_Initialized){
                     s=m_pConnector.column_type(m_stmt, column_index);
                  }else{
                     s=m_ColumnTypeArray[column_index];
                  }
                  return(s);
               };
                    
      int      GetColumnIndex(string const column_name){
                  if(!m_Initialized){
                     return(-1);
                  }
                  return(m_ColumnNameArray.SearchLinear(column_name));
               };                                                             
      
      int      SetColumnArrays(){
                  m_ColumnNameArray.Resize(m_ColumnCount);
                  m_ColumnTypeArray.Resize(m_ColumnCount);
                  for(uint i=0; i<m_ColumnCount; i++){
                     m_ColumnNameArray.Add(GetColumnName(i));
                     m_ColumnTypeArray.Add(GetColumnType(i));
                  }
                  
                  return(m_ColumnNameArray.Total());
               };
      void     GetColumnNames(CArrayKeyVal &columns){
                  for(int i=0; i<m_ColumnNameArray.Total(); i++){
                     columns.Add(m_ColumnNameArray[i], m_ColumnTypeArray[i]);
                  }
               };
                        
      string   GetColumnNameString(const string separator=" | "){
                  string s = "";
                  for(int i=0; i<m_ColumnNameArray.Total(); i++){
                     s += m_ColumnNameArray[i];
                     if(i<m_ColumnNameArray.Total()-1){
                        s+=separator;
                     }
                  }
                  return(s);
               };                 
               
      string   GetColumnNamesWhithTypeString(const string separator=" | "){
                  string s="";
                  for(int i=0; i<m_ColumnNameArray.Total(); i++){
                     s+="("+m_ColumnTypeArray[i]+")"+m_ColumnNameArray[i];
                     if(i<m_ColumnNameArray.Total()-1){
                        s+=separator;
                     }
                  }
                  return(s);
               }               
               
      bool     Next(){
                  bool r=m_pConnector.next(m_stmt);
                  
                  if(r){
                     m_ThisRowNumber++;
                  }
                  return(r);
               }                     
               
      string   GetValue(int const column_index=0){
                  if(m_ThisRowNumber<=-1){
                     
                     if(!Next()){
                        return("");
                     }
                  }
                  
                  return(m_pConnector.value(m_stmt, column_index));
               };
               
      string   GetValue(string const column_name){
                  if(m_ThisRowNumber <= -1){
                     
                     if(!Next()){
                        
                        return("");
                     }   
                  }
                  
                  int column_index = m_ColumnNameArray.SearchLinear(column_name);
                  if(column_index<0){
                     DPrint("No column whith name <"+column_name+">");
                     return("");
                  }
                  
                  return(GetValue(column_index));
               };
      string   GetRowString(const string separator=" | "){
                  string s="";
                  for(uint i=0; i<m_ColumnCount; i++){
                     s+=GetValue(i)+separator;
                  }
                  return(s);
               };                                       
};