@isTest
private class Test_Utils_Filter {

	static testMethod void FilterTest() {
	  	set<string> IncludedRef= new set<string>();
	  	set<string> fieldIncluded= new set<string>();

		IncludedRef.add('account');
		fieldIncluded.add('isdeleted');
	    fieldIncluded.add('account.name');

	    Utils_Filter f= new Utils_Filter('Contact',5,'PHONE~Fax~e~025412545',IncludedRef,fieldIncluded,true,true);
	    try{
			f.QueryAcceptable('select id from contact');
			f.QueryAcceptable('select id from condewtact');
	    }
	    catch(Exception e) {}

	    f.addRow();
	    f.removeRow();
	    f.ClearFilters();

	    f.getFilterParameters();
	    f.getSql();
	    f.getSqlWhereConditions();
	    f.loadQueryParameter();
	    List<SelectOption> ObjFields = f.getObjFields();
	    f.FilterRowList.add(new Utils_Filter.FilterRow(1));
	    f.FilterRowList[0].fieldpath='PHONE~Fax~e~025412545';
	    f.FilterRowList[0].setParameters();
	    f.getIsAdvanced();f.getAdvancedOption();
	    boolean p = f.runQuery();
	    f.advanced=true;
	    f.queryAdvancedOpt='1';
	    f.runQuery();

	    Utils_FilterParser.isBoolean('NONE');
	    Utils_FilterParser.formatDate('10/01/2000');
	    Utils_FilterParser.isDate('DATE');
	    Utils_FilterParser.isDateTime('DATETIME');
	    Utils_FilterParser.isMultipickList('NONE');
	    Utils_FilterParser.parse('e','1', 'FAX', 'PHONE');
	    Utils_FilterParser.parse('e','1', 'FAX', 'BOOLEAN');
	    Utils_FilterParser.parse('e','1', 'FAX', 'STRING');
	    Utils_FilterParser.parse('n','1', 'FAX', 'STRING');
	    Utils_FilterParser.parse('l','1', 'FAX', 'STRING');
	    Utils_FilterParser.parse('g','1', 'FAX', 'STRING');
	    Utils_FilterParser.parse('m','1', 'FAX', 'STRING');
	    Utils_FilterParser.parse('h','1', 'FAX', 'STRING');
	    Utils_FilterParser.parse('c','1', 'FAX', 'STRING');
	    Utils_FilterParser.parse('k','1', 'FAX', 'STRING');
	    Utils_FilterParser.parse('s','1', 'FAX', 'STRING');
	    Utils_FilterParser.parse('u','1', 'FAX', 'STRING');
	    Utils_FilterParser.parse('x','1', 'FAX', 'STRING');

	    string d = date.today().format();
	    Utils_FilterParser.parse('e',d, 'DATE', 'DATE');
	    Utils_FilterParser.parse('n',d, 'DATE', 'DATE');

	    Utils_FilterParser.parse('e','10/01/2000', 'DATETIME', 'DATETIME');
	    Utils_FilterParser.parse('n','10/01/2000', 'DATETIME', 'DATETIME');

		f= new Utils_Filter('Contact',5,'PHONE~Fax~e~025412545',IncludedRef,fieldIncluded,false,false,false,'1');
	}
}