//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Test_LWC_CustomRelatedList
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 14/12/2020
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
@isTest
public with sharing class Test_LWC_CustomRelatedList {

    @isTest 
    public static void testInit(){
        Account acc = new Account(Name = 'test');
        insert acc;
        Contact cnt = new Contact(LastName = 'test', AccountId = acc.Id);
        insert cnt;
                
        Map<String, Object> requestMap = new Map<String, Object>(); 
        requestMap.put(LWC_CustomRelatedList.FIELDS_PARAM, 'Name, Title, Email, Phone');
        requestMap.put(LWC_CustomRelatedList.RELATED_FIELD_API_NAME_PARAM, 'AccountId');
        requestMap.put(LWC_CustomRelatedList.RECORD_ID_PARAM, acc.Id);
        requestMap.put(LWC_CustomRelatedList.NUMBER_OF_RECORDS_PARAM, 1);
        requestMap.put(LWC_CustomRelatedList.SOBJECT_API_NAME_PARAM, 'Contact');
        requestMap.put(LWC_CustomRelatedList.SORTED_BY_PARAM, 'Name');
        requestMap.put(LWC_CustomRelatedList.SORTED_DIRECTION_PARAM, 'ASC');
                
        String jsonData = LWC_CustomRelatedList.initData(JSON.serialize(requestMap));
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);
        List<Object> records = (List<Object>)responseMap.get(LWC_CustomRelatedList.RECORDS_PARAM);
        System.assert(!records.isEmpty());
        String iconName = (String)responseMap.get(LWC_CustomRelatedList.ICON_NAME_PARAM);
        System.assert(String.isNotBlank(iconName));
    }
}