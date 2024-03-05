//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_CustomRelatedList
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 08/02/2021
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_CustomRelatedList {
	public static final String FIELDS_PARAM = 'fields';
	public static final String NUMBER_OF_RECORDS_PARAM = 'numberOfRecords';
	public static final String SHOW_ALL_RECORDS_PARAM = 'showAllRecords';
	public static final String RECORD_ID_PARAM = 'recordId';
	public static final String SOBJECT_API_NAME_PARAM = 'sobjectApiName';
	public static final String SOBJECT_LABEL_PARAM = 'sobjectLabel';
	public static final String SOBJECT_LABEL_PLURAL_PARAM = 'sobjectLabelPlural';
	public static final String PARENT_RELATIONSHIP_API_NAME_PARAM = 'parentRelationshipApiName';
	public static final String RELATED_FIELD_API_NAME_PARAM = 'relatedFieldApiName';
	public static final String SORTED_DIRECTION_PARAM = 'sortedDirection';
	public static final String SORTED_BY_PARAM = 'sortedBy';
	public static final String RECORDS_PARAM = 'records';
	public static final String ICON_NAME_PARAM = 'iconName';
	public static final String FILTER_PARAM = 'filter';

	@AuraEnabled
	public static String initData(String jsonData){
        System.debug('### DEBUT LWC_CustomRelatedList.initData'); 
		System.debug('## jsonData: '+jsonData); 

		// Get Records
		Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);  
		Map<String, Object> responseMap = new Map<String, Object>();
		responseMap.put(RECORDS_PARAM, getRecords(jsonData));
		
		// Get icone
		String sobjectApiName = (String)requestMap.get(SOBJECT_API_NAME_PARAM);
		String iconName = (String)requestMap.get(ICON_NAME_PARAM);
		responseMap.put(ICON_NAME_PARAM, getIconName(sobjectApiName, iconName));

		// Get parent relations
		String recordId = (String)requestMap.get(RECORD_ID_PARAM);
		String relatedFieldApiName = (String)requestMap.get(RELATED_FIELD_API_NAME_PARAM);
		responseMap.put(PARENT_RELATIONSHIP_API_NAME_PARAM, getParentRelationshipName(recordId, sobjectApiName, relatedFieldApiName));

		Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(sobjectApiName);
		Schema.DescribeSObjectResult sobjectDescribe = sobjectType.getDescribe();
		responseMap.put(SOBJECT_LABEL_PARAM, sobjectDescribe.getLabel());
		responseMap.put(SOBJECT_LABEL_PLURAL_PARAM, sobjectDescribe.getLabelPlural());
		
		System.debug('## responseMap: '+responseMap); 
        System.debug('### FIN LWC_CustomRelatedList.initData'); 
		return JSON.serialize(responseMap);
	}
	
	@AuraEnabled
	public static List<Sobject> getRecords(String jsonData){
        System.debug('### DEBUT LWC_CustomRelatedList.getRecords'); 
		System.debug('## jsonData: '+jsonData); 
		
		Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(jsonData);  
		String fields = (String)root.get(FIELDS_PARAM);
		Integer numberOfRecords = (Integer)root.get(NUMBER_OF_RECORDS_PARAM);
		String recordId = (String)root.get(RECORD_ID_PARAM);
		String relatedFieldApiName = (String)root.get(RELATED_FIELD_API_NAME_PARAM);
		String sobjectApiName = (String)root.get(SOBJECT_API_NAME_PARAM);        
		String orderBy = (String)root.get(SORTED_BY_PARAM) + ' ' + (String)root.get(SORTED_DIRECTION_PARAM);      
		Boolean showAllRecords = (Boolean)root.get(SHOW_ALL_RECORDS_PARAM);      
		String filter = (String)root.get(FILTER_PARAM);        
		
		String query = 'SELECT Id, '+fields+' FROM '+sobjectApiName+' WHERE ';
		// If multiple field filter
		List<String> filtersList = relatedFieldApiName.split(',');
		Integer index = 0;
		query += '( ';
		for(String filterFieldApiName : filtersList) {
			query += filterFieldApiName+ '= :recordId ';
			index++;
			if(filtersList.size() != index) {
				query += ' OR ';
			}
		}
		query += ' ) ';
		if(String.isNotBlank(filter)) {
			query += ' AND ' + filter;
		}
		query += ' ORDER BY ' +orderBy;
		// Limit
		if(showAllRecords == false) {
			query += ' LIMIT :numberOfRecords';
		}
		System.debug('## query: '+query); 

        System.debug('### FIN LWC_CustomRelatedList.getProducts'); 
		return Database.query(query);
	}
		
	private static String getParentRelationshipName(Id recordId, String childSobjectApiName, String relatedFieldApiName){
		Schema.DescribeSObjectResult descrRes = recordId.getSObjectType().getDescribe();
		String name;
		for (Schema.ChildRelationship cr: descrRes.getChildRelationships()){ 
			if(cr.getChildSObject().getDescribe().getName() == childSobjectApiName
			&& cr.getField().getDescribe().getName() == relatedFieldApiName){
					name = cr.getRelationshipName();
				break;
			}
		}     
		return name;
	}      
	
	@AuraEnabled
	public static String getIconName(String sobjectApiName, String iconName){
        System.debug('### DEBUT LWC_CustomRelatedList.getIconName'); 
		System.debug('## sobjectApiName: '+sobjectApiName); 
		System.debug('## iconName: '+iconName); 
		List<Schema.DescribeTabSetResult> tabSetDesc = Schema.DescribeTabs();
		List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
		List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

		// Get only icone by metadata only if no custom icon defined
		if(String.isBlank(iconName)) {
			for(Schema.DescribeTabSetResult tsr : tabSetDesc) { 
				tabDesc.addAll(tsr.getTabs()); 
			}

			for(Schema.DescribeTabResult tr : tabDesc) {
				if( sobjectApiName == tr.getSobjectName() ) {
					if( tr.isCustom() ) {
						iconDesc.addAll(tr.getIcons());
					} else {
						iconName = 'standard:' + sobjectApiName.toLowerCase();
					}
				}
			}
			for (Schema.DescribeIconResult ir : iconDesc) {
				if (ir.getContentType() == 'image/svg+xml'){
					iconName = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
					break;
				}
			}
		}
		System.debug('## iconName: '+iconName); 
        System.debug('### FIN LWC_CustomRelatedList.getIconName'); 
		return iconName;
	}    
}