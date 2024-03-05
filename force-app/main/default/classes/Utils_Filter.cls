/*
+-----------------------+-----------------------------------------------------------------------------+
| Author                | BALINK (dev@balink.net)                                |
+-----------------------+-----------------------------------------------------------------------------+
| Description
  - Component : Filter Component Controller
  - Methods :
  		  + query
          + ClearFilters
          + FilterRow
          + loadQueryParameter
  - include :
  		  Custom Setting - Disable Filter Fields
       	  Custom Label - PREFIX Filter_
       	  Class - FilterParser
      	  Page - SelectPickListValue
  - Structure :
  - version : 3
*/

public with sharing class Utils_Filter {

  public integer NOF{set;get;}  //number of filtersRow
  public List<FilterRow> FilterRowList {set;get;}
  public String queryAdvancedOpt {set;get;}
  public Boolean advanced {set;get;}
  public String ObjectName {set;get;}
  public string sqlParam {set;get;}
  public Boolean isValidQuery{set;get;}
  public string query {set;get;}
  public string queryAdvancedOp {set;get;}
  public string queryParameter {set;get;}
  public boolean withObjectPrefix{get;set;}
  public boolean includeReferences{get;set;}

  public boolean showAdancedFilter{get;set;}

  public set<string> referenceFields; // list of reference fields postfix syntax __r and on low case
  public set<string> Includedfields; // list of  Included fields syntax: API_FieldName or referenceObjectName.API_FieldName (in case of reference field)

  public Utils_Filter(){}

  public Utils_Filter(string onObject ,integer numberOfFilters ,string queryParameters,set<string> referenceFieldsToShow,set<string> fieldsToShow , Boolean showObjectPrefix, Boolean showReferences){
  	advanced=false;
    defaultSetup(onObject,numberOfFilters,queryParameters,referenceFieldsToShow ,fieldsToShow, showObjectPrefix,  showReferences);
  }

  public Utils_Filter(string onObject,integer numberOfFilters,string queryParameters,set<string> referenceFieldsToShow ,set<string> fieldsToShow, Boolean showObjectPrefix, Boolean showReferences,Boolean advancedOption,string queryAdvancedOption){


  	advanced=advancedOption;
  	if(advanced==true)
		queryAdvancedOpt = queryAdvancedOption;
	else
		queryAdvancedOpt='';
  	defaultSetup(onObject,numberOfFilters,queryParameters,referenceFieldsToShow ,fieldsToShow, showObjectPrefix,  showReferences);
  }


  public void defaultSetup(string onObject,integer numberOfFilters,string queryParameters,set<string> referenceFieldsToShow ,set<string> fieldsToShow, Boolean showObjectPrefix, Boolean showReferences){
  	showAdancedFilter = true;
  	ObjectName=onObject;
    NOF=numberOfFilters;
    referenceFields=referenceFieldsToShow;
    Includedfields=fieldsToShow;
  	queryParameter=queryParameters;
  	includeReferences=showReferences;
  	withObjectPrefix=showObjectPrefix;

    FilterRowList = new List<FilterRow>();
    isValidQuery=true;
    if(referenceFields==null)referenceFields=new set<string>();
    if(Includedfields==null)Includedfields=new set<string>();
    ClearFilters();
    loadQueryParameter();
  }

  public void loadQueryParameter(){
	if(queryParameter!=null){
		list<string> params = queryParameter.split('[$]');
		for(integer i = 0 ; i < params.size() ; i++){
			if(i<FilterRowList.size())//-1)
				FilterRowList[i].fieldpath=params[i];
				else{
					FilterRowList.add( new FilterRow(i,params[i]));
					NOF++;
				}
		}
	}
  }

  public boolean getIsAdvanced(){
  	return advanced;
  }

  public string getAdvancedOption(){
  	return queryAdvancedOpt;
  }

  public string getSqlWhereConditions(){
  	return sqlParam;
  }
  public string getSql(){
  	runQuery();
  	return query;
  }

  public string getFilterParameters(){
  	return queryParameter;
  }

  public List<SelectOption> getObjFields() {
  	//return getObjectFieldsListAndAPI(ObjectName,referenceFields);
  	List<SelectOption> op = getObjectFieldsListAndAPI(ObjectName,referenceFields);
  	if(Includedfields.size()==0) return op;
  	List<SelectOption> op2=new List<SelectOption>();
  	System.debug('\n\n\n\n'+' referenceFields '+referenceFields+'\n\n\n\n');
    for(string s : Includedfields){
    	for (SelectOption so : op){
    		System.debug('\n\n\n\n'+s+' -- '+so.getValue().split(',')[1]+'\n\n\n\n');
    		if(s==so.getValue().split(',')[1]){
    			op2.add(so);
    			break;
    		}
    	}
    }
    return op2;
  }

  public List<SelectOption> getObjectFieldsListAndAPI(string ObjectName,set<string> referenceFields) {

     Map<String, Schema.SObjectField> ObjectFieldMap = Schema.getGlobalDescribe().get( ObjectName ).getDescribe().fields.getMap();
     List<SelectOption>  options = new List<SelectOption> ();
     Schema.DescribeFieldResult F;
     for (Schema.SObjectField SObjectF : ObjectFieldMap.values()){
        F = SObjectF.getDescribe();
        if (F.getType().name()!='ID' && F.getType().name()!='REFERENCE' && F.isFilterable() && F.isAccessible()){
	          if(withObjectPrefix)
	            options.add(new SelectOption(F.getType().name()+','+F.getName(),ObjectName+' : '+F.getLabel()));
	          else
	            options.add(new SelectOption(F.getType().name()+','+F.getName(),F.getLabel()));
		}
		if (F.getType().name()=='REFERENCE' && includeReferences){
			System.debug('\n\n\nREFERENCE : ' + withObjectPrefix + '\n\n\n');
			System.debug('\n\n\nreferenceFields : ' + referenceFields + ' -- ' + F.getRelationshipName().toLowerCase() + '\n\n\n');
			System.debug('\n\n\nREFERENCE' + F.getType().name()+','+F.getName() + '\n\n\n');

	          if(withObjectPrefix)
	            options.add(new SelectOption(F.getType().name()+','+F.getName(),ObjectName+' : '+F.getLabel()));
	          else
	            options.add(new SelectOption(F.getType().name()+','+F.getName(),F.getLabel()));
		   /* isNamePointing to validate there is only one reference to Object*/
		    if( referenceFields.contains(F.getRelationshipName().toLowerCase())){
		    	options.addAll(getObjectFieldsListAndApiOfLookup(F.getReferenceTo().get(0).getDescribe().getName(),F.getRelationshipName()));
		    }
        }

    }
    return options;
  }

  public  List<SelectOption> getObjectFieldsListAndApiOfLookup(string ObjectName , string lookupReference){
     Map<String, Schema.SObjectField> ObjectFieldMap = Schema.getGlobalDescribe().get( ObjectName ).getDescribe().fields.getMap();
     List<SelectOption>  options = new List<SelectOption> ();
     Schema.DescribeFieldResult F;
     for (Schema.SObjectField SObjectF : ObjectFieldMap.values()){
         F = SObjectF.getDescribe();
        if (F.isFilterable() && F.isAccessible()){
        	System.debug('\n\n\n\n'+' RefFields  '+(ObjectName+'.'+F.getName()).tolowercase()+'\n\n\n\n');
	        //if(Includedfields.contains( (ObjectName+'.'+F.getName()).tolowercase())){
	            options.add(new SelectOption(F.getType().name()+','+lookupReference+'.'+F.getName(),ObjectName+' : '+F.getLabel()));
	            System.debug('\n\n\n\n'+' RefFields  '+lookupReference+'.'+F.getName()+'\n\n\n\n');
	        //}
        }

    }
    return options;
  }

  public boolean runQuery(){

    //FilterRowList.clear();
    Integer i = 1 ;

    for (FilterRow r :  FilterRowList){
    	 r.setParameters();
    }
    sqlParam ='';
      if (FilterRowList.size()>0){
        if (!advanced){ // for standard search
          for (FilterRow f : FilterRowList){
            if (f.fieldpath!='null') sqlParam +=' and '+f.getSql();
          }
          if (sqlParam.length()>4)  sqlParam = +sqlParam.substring(4);//remove first 'and'
          queryAdvancedOpt='';

        }else{ // for advanced search
          sqlParam=queryAdvancedOpt;
          System.debug('\n\n\n\n\n FFFFFFIIIII'+queryAdvancedOpt+'\n\n\n\n\n');
			sqlParam = string.format('({0})',new string[]{sqlParam});
          for (i = 0; i <= NOF ;i++)
          if(sqlParam.contains(String.valueOf(i)))
          	sqlParam=sqlParam.replace(String.valueOf(i),'--'+String.valueOf(i)+'--');

          string key;
          for (FilterRow f : FilterRowList){

           	 	key='--'+(f.rowNumber+1).format()+'--';
           	 System.debug('****KEY************\n\n'+key+'\n\n*****************************');
            	sqlParam=sqlParam.replace(key,f.getSql());

          }
          System.debug('****+++++****************\n\n'+sqlParam+'\n\n*****************************');
        }
      }


    if (sqlParam==''||sqlParam==null)
       query = 'select id from '+ObjectName;
      else
       query = 'select id from '+ObjectName+' where '+sqlParam;

    if(!QueryAcceptable(query))
    {
      isValidQuery=false;
      return false;//check if the query acceptable
    }
    isValidQuery=true;
    queryParameter='';
  	for (FilterRow r :  FilterRowList)
   	 	queryParameter += r.fieldpath+'$';
    queryParameter=queryParameter.substring(0,queryParameter.length()-1);

    return true;
  }

  public void ClearFilters(){
  	FilterRowList.clear();
  	 for(integer i =0 ; i < nof ; i++)
    	 FilterRowList.add(new FilterRow(i));
  }

  public Boolean QueryAcceptable(string sql){
    try{
      Database.query(sql + ' limit 1');
    }catch (Exception e){
      Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR,'Query not valid'));
      return false;
    }
    return true;
  }

  public Pagereference addRow(){

	FilterRowList.add(new FilterRow(NOF));
	NOF = NOF+1;
  	return null;
  }

  public Pagereference removeRow(){
  	NOF = NOF-1;
  	FilterRowList.remove(NOF);

  	return null;
  }

  public class FilterRow{

    protected String field;
    protected String filter;
    protected String value;
    protected String fieldType;
    public Integer rowNumber;

    public String fieldpath {get;set;}

    public FilterRow(integer num){
      rowNumber = num;
      fieldpath='null';
    }
    public FilterRow(integer num,string fp){
      rowNumber = num;
      fieldpath=fp;
    }

    public void setParameters(){
    list<string> f = fieldpath.split('[~]');
      if (f.size()==4){
        fieldType=f[0];
        field = f[1];
        filter = f[2];
        value=f[3];
      }
    }

    public string getSql(){
      try{
        if(fieldType=='PICKLIST')
        {
          string str ='';
          if(value.contains(',')){
            list <string> values = value.split('[,]');
            for(string v : values){
              str+=' or ('+Utils_FilterParser.parse(filter,v,field,fieldType)+')';
            }
            str= str.replaceFirst('or','');
            return str;
          }

        }
        return Utils_FilterParser.parse(filter,value,field,fieldType);
      }catch(Exception e){
        return null;
      }
      return null;
    }
  }
}