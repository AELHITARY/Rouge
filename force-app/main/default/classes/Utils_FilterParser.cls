/*
+-----------------------+-----------------------------------------------------------------------------+
| Author                | BALINK (dev@balink.net)                                                   |
+-----------------------+-----------------------------------------------------------------------------+
| Description
  - Component : FilterParser - for the Filter Contriller
  - Structure :
*/
global class Utils_FilterParser {

/*****************Private Members***************/
private boolean HasKeyWord = false;
private string sObjectName = '';
private string keyWord = '';
public virtual class eException extends Exception{}

/********************Constructor*************************/

private static boolean requireQuote(String fieldType)
{
    if(fieldType == 'INTEGER')
        return false;
    if(fieldType == 'PERCENT')
        return false;
    if(fieldType == 'CURRENCY')
        return false;
    if(fieldType == 'DOUBLE')
        return false;
    if(fieldType == 'BOOLEAN')
        return false;
    if(fieldType == 'DATE')
        return false;
    if(fieldType == 'DATETIME')
        return false;

    return true;
}

public static boolean isMultipickList(String fieldType)
{
    return (fieldType == 'MULTIPICKLIST');
}

public static boolean isDate(String fieldType)
{
    return ((fieldType == 'DATE') ) ;
}
public static boolean isDateTime(String fieldType)
{
    return ((fieldType == 'DATETIME')) ;
}
public static boolean isBoolean(String fieldType)
{
    return ((fieldType == 'BOOLEAN')) ;
}
public static DateTime formatDate(string str)
{
    Integer day=Integer.valueOf(str.split('/')[0]);
    Integer month=Integer.valueOf(str.split('/')[1]);
    Integer year=Integer.valueOf(str.split('/')[2]);
    datetime myDate = datetime.newInstance(year,month,day,0,0,0);
    return myDate;
}
public static string parse(string op, string searchword, string field, string fieldType)
{
    string filter=' ';
    if(field == null || field == '')
        return '';
    try {
      boolean req =   requireQuote(fieldType);
      searchword = searchword.trim();
      searchword = String.escapeSingleQuotes(searchword);
      string searchword2='';

       if(isDateTime(fieldType))
       {
          DateTime newDate = formatDate(searchword);
          searchword= formatDate(searchword).format('yyyy-MM-dd\'T\'hh:mm:ss\'.000Z\'');
          newDate=newDate.addDays(1);
          searchword2 = newDate.format('yyyy-MM-dd\'T\'hh:mm:ss\'.000Z\'');
       }
       if(isDate(fieldType))
       {
          DateTime newDate = formatDate(searchword);
          searchword= formatDate(searchword).format('yyyy-MM-dd');
          searchword2 = newDate.format('yyyy-MM-dd');
       }
       searchword2 = String.escapeSingleQuotes(searchword2);
       //System.debug('++++++++++++++++++++'+op+'----- '+fieldType+' ---- ' + field +'----'+  searchword+'++++++++++++++++++++++++');
    if(isBoolean(fieldType))
       {

        if(searchword.toLowerCase()!='true' && searchword.toLowerCase()!='false')
          boolean b =boolean.valueOf(searchword);
       }
      if(op == 'e') //equals
      {
          if(isDateTime(fieldType))
              return ' ' + field  + ' > ' + searchWord +' and ' + field  + ' < ' + searchword2+' '  ;

          else if(req)
              return ' '  + field  + ' = \'' + searchWord +'\''+' ';
          else
              return ' ' + field  + ' = ' + searchWord+' ';
      }

       if(op == 'n')//not equal to
       {
          if(isDateTime(fieldType))
              return ' (' + field  + ' < ' + searchWord +' or ' + field  + ' > ' + searchword2 + ')'+' '  ;
          else if(req)
                return  ' ' + field  +' != \'' + searchWord +'\''+' ';
            else
               return  ' '  + field  +' != '+ searchWord+' ' ;

       }
       if(op == 'l') //less than
       {
          if(req)
            return  ' ' +  field  +' < \'' + searchWord +'\''+' ';
          else
            return ' ' +  field  +' < '+ searchWord+' ' ;
       }
       if(op == 'g') //greater than
        {
           if(req)
            return ' ' + field  +' > \'' + searchWord +'\''+' ';
          else
            return ' ' + field  +' > '+ searchWord+' ' ;

        }

       if(op == 'm')//less or equal than
             {
           if(req)
            return ' ' + field  +' <=\'' + searchWord +'\''+' ';
          else
            return ' '  + field  +' <= '+ searchWord+' ' ;
          }


       if(op == 'h') //greater or equals than
            {
          if(req)
            return ' ' + field  +' >= \'' + searchWord +'\''+' ';
          else
            return ' '  + field  +' >= '+ searchWord+' ' ;
           }


       if(op == 'c') //contains
            return ' '  + field  +' LIKE \'%' + searchWord + '%\''+' ';

       if(op == 'k') //does not contains
            return ' (NOT ' + field + ' LIKE \'%' + searchWord + '%\')'+' ';

       if(op == 's') //start with
            return ' ' +  field  +' LIKE \'' + searchWord + '%\''+' ';

       if(op == 'u' || op == 'x')//u = includes, x=excludes
       {
           string [] str = searchWord.split(',',0);
           string res ='';
           if(op == 'u')
               res = ' '  + field  +' includes (';
           else
               res = ' '  + field  +' excludes (';
           for(string s:str)
           {
             res +='\'' + s + '\',';
           }
           res  = res.substring(0,res.length()-1);
           res +=')';
           return res+' ';
       }
    }catch(Exception e){
      throw new eException('An error has occurred, some values are not valid');
    }
    return '';
}


}