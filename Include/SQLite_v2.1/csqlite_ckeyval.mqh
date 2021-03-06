//+------------------------------------------------------------------+
//|                                              csqlite_ckeyval.mqh |
//|                                          Copyright 2016, artamir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, artamir"
#property link      "https://www.mql5.com"
#property strict

#ifndef BASE
#include <Object.mqh>
#include <SQLite_v2.1\csqlite_string.mqh>
#include <SQLite_v2.1\csqlite_array_obj.mqh>
#endif 


class CKeyValuePair : public CObject{
   private:
      string m_key;
      string m_value;
   public:
      template <typename T>
      CKeyValuePair(const string key, T value);
      ~CKeyValuePair(){}
      
   public:
      string   Key(void){return(m_key);}
      void     Key(const string k){m_key=k;}
      
      template <typename T>
      void     Value(T value){m_value=(string)value;}
      void     Value(const datetime value){m_value=(string)(int)value;}
      string   Value(void){return(m_value);}       
      
      string   toString(const string separator="=");
};

template <typename T>
CKeyValuePair::CKeyValuePair(const string key,T value){
   //DPrint(typename(T));
   Key(key);
   Value(value);
}

string CKeyValuePair::toString(const string separator="="){
   string result="";
   result+=Key()+separator;
   result+=Value();
   return(result);
}

class CArrayKeyVal :public CArrayObj{
   private:
      int   m_index;
      bool  m_next_used;
      CKeyValuePair *m_pkv;
   public:
      CArrayKeyVal(){
         FreeMode(true);
         m_next_used=false;
      }
      ~CArrayKeyVal(){}
   template <typename T>   
   bool     Add(const string key, const T value);
   bool     Add(CArrayKeyVal& kv);
   
   template <typename T>
   bool     Replace(const string key, const T value) ;
   void     Index(const int i){m_index=i;}
   int      Index(void){return(m_index);}
   int      KeyIndex(const string key);
   bool     ExistsKey(const string key);
   void     DeleteKey(const string key);
   string   Key(void);
   string   Val(void);
   template <typename T>
   void     Val(const T value);
   
   void     Assign(string keys, string values);//конвертирует переданные ключи через запятую и значения через запятую в элементы массива
   
   string   Get(const string key);//возвращает значение соотв. заданному ключу, либо NULL
   
   bool     Next(void);
   string   JoinKeys(const string separator=","); //Соединяет все ключи в строку через разделитель
   string   JoinKeyVal(const string separator="="); //Соединяет текущий ключ и значение в строку через разделитель
   void     DeleteNotExistsKeys(CArrayKeyVal &keys);
   string   toString(void);//Возвращает строку, созданную из всех элементов ключ:значение
};

template <typename T>
bool CArrayKeyVal::Add(const string key,T value){
   CKeyValuePair *kv=new CKeyValuePair(key, value);
   bool result=CArrayObj::Add(kv);
   m_index=Total()-1;
   return(result);
}

bool CArrayKeyVal::Add(CArrayKeyVal& kv){
   bool result = true;
   
   while(kv.Next()){
      Add(kv.Key(), kv.Val());
   }
   
   return(result);
}

template <typename T>
bool CArrayKeyVal::Replace(const string key,const T value){
   bool result = false;
   if(!ExistsKey(key)){
      result = Add(key, value);
      return(result);
   }
   
   Index(KeyIndex(key));
   Val(value);
   return(result);
}

string CArrayKeyVal::Key(void){
   CKeyValuePair *kv = At(m_index);
   string result=NULL;
   if(kv!=NULL){
      result=kv.Key();
   }
   return(result);
}

/**
 * !!!сбрасывает признак m_next_used, что метод Next был вызван
 */
int CArrayKeyVal::KeyIndex(const string key){
   int   index=-1;
   m_next_used=false;
   
   bool isFound=false;
   while(Next()&&!isFound){
      if(Key()==key){
         isFound=true;
         index=Index();
      }
   }
   
   m_next_used=false;
   return(index);
}

bool CArrayKeyVal::ExistsKey(const string key){
   bool result=false;
   if(KeyIndex(key)>=0){
      result=true;
   }
   return(result);
}

void CArrayKeyVal::DeleteKey(const string key){
   if(ExistsKey(key)){
      Delete(KeyIndex(key));
   }
}

string CArrayKeyVal::Val(void){
   if(m_index<0){
      return(NULL);
   }
   CKeyValuePair *kv = At(m_index);
   return(kv.Value());
}

template <typename T>
void CArrayKeyVal::Val(const T value){
   m_pkv = At(m_index);
   if(m_pkv != NULL){
      m_pkv.Value(value);
   }
}

string CArrayKeyVal::Get(const string key){
   
   int idx = KeyIndex(key);
   
   Index(idx);
   return(Val());
}

void CArrayKeyVal::Assign(string keys,string values){
   CString sKeys, sVals;
   sKeys.Assign(keys);
   sVals.Assign(values);
}

bool CArrayKeyVal::Next(void){
   bool result=false;
   if(!m_next_used){
      m_index=0;
      m_next_used=true;
   }else{
      m_index++;
   }
   
   m_pkv=At(m_index);
   if(m_pkv==NULL){
      m_next_used=false;
   }else{
      result=true;
   }
   
   return(result);
}

string CArrayKeyVal::JoinKeys(const string separator=","){
   string result="";
   while(Next()){
      result+=Key();
      if(Index()<Total()-1){
         result+=separator;
      }
   }
   return(result);
}

string CArrayKeyVal::JoinKeyVal(const string separator="="){
   string result="";
   CKeyValuePair *kv=At(m_index);
   if(kv!=NULL){
      result=kv.toString(separator);
   }
   return(result);
}

string CArrayKeyVal::toString(void){
   string result="";
   while(Next()){
      result+="["+JoinKeyVal(":")+"]";
   }
   return(result);
}

void CArrayKeyVal::DeleteNotExistsKeys(CArrayKeyVal &keys){
   int _total = Total();
   for(int i=_total-1; i>=0; i--){
      Index(i);
      if(keys.KeyIndex(Key())<0){
         Delete(i);
      }
   }
}