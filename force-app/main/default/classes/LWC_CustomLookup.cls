//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_CustomLookup
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 21/11/2019
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_CustomLookup {

    /**
    * @description Function to get records search for the lookup
    * @param objectName API Name of the object
    * @param objectTypeRecordName API Name of the record type (optionnel)
    * @param fld_API_Val Nom d'API du champ qui est retourné par la recherche
    * @param fld_API_Search Nom d'API du champ recherché
    * @param fld_API_Search2 Nom d'API du second champ recherché (optionnel)
    * @param subtitleField Champ pour le sous titre
    * @param searchText Texte recherché
    * @param customFilter Filtre personnalisé
    * @param orderBy Tri personnalisé
    * @return Records list
    */
    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> getResults(String objectName, String objectTypeRecordName, String fld_API_Val, 
                                                String fld_API_Search,String fld_API_Search2, String subtitleField, 
                                                String searchText, String customFilter, String orderBy) {
        system.debug('### DEBUT LWC_CustomLookup : getResults');
        List<LookupSearchResult> sObjectResultList = new List<LookupSearchResult>();
        String recordTypeId = null;
        system.debug('## objectName: '+objectName);
        system.debug('## objectTypeRecordName: '+objectTypeRecordName);

        try {
            // Trim
            objectName = objectName.trim();
            fld_API_Val = fld_API_Val.trim();
            
            if(searchText.length() >= 3) {
                searchText='\'%' + String.escapeSingleQuotes(searchText.trim()) + '%\'';
                system.debug('## SearchText: '+searchText);
                
                // Get record type ID 
                if(String.isNotBlank(objectTypeRecordName)) {
                    recordTypeId = DAL.getRecordTypeIdByDevName(objectName, objectTypeRecordName.trim());
                }
                // Construction requête SOQL
                String query = 'SELECT Id, '+fld_API_Val;
                if(String.isNotBlank(subtitleField) && fld_API_Val != subtitleField) {
                    query += ' , '+subtitleField;
                }

                query +=' FROM '+objectName;

                if(String.isNotBlank(fld_API_Search2)) {
                    query += ' WHERE ('+fld_API_Search+' LIKE '+searchText+' OR '+ fld_API_Search2+' LIKE '+searchText+')';
                } else {
                    query += ' WHERE '+fld_API_Search+' LIKE '+searchText;
                }
                if(String.isNotBlank(recordTypeId)) {
                    query += ' AND RecordTypeId =\''+ recordTypeId +'\'';
                }
                if(String.isNotBlank(customFilter)) {
                    query += ' AND '+ customFilter;
                }
                if(String.isNotBlank(orderBy)) {
                    query += ' ORDER BY '+ orderBy;
                }
                query += ' LIMIT 10 ';
                system.debug('## Query: '+query);
                
                // Exécution et traitement résultat
                List<sObject> sobjList = Database.query(query);
                System.debug(Limits.getCPUTime());
                system.debug('## Result size: '+sobjList.size());
                for(SObject so : sobjList){
                    String sublabelTemp = (so.get(subtitleField) == null) ? '' : String.valueOf(so.get(subtitleField));
                    sObjectResultList.add(
                        new LookupSearchResult(
                            so.Id,
                            Schema.getGlobalDescribe().get(objectName).getDescribe().getLabel(),
                            String.valueOf(so.get(fld_API_Val)), 
                            sublabelTemp
                        )
                    );
                } 
                system.debug('## sObjectResultList: '+sObjectResultList);
                system.debug('### FIN LWC_CustomLookup : getResults');
                return sObjectResultList;
            } else {
                return sObjectResultList;
            }
        } catch(Exception e){
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        } 
    }
    
    public class LookupSearchResult {
        public String id;
        public String sObjectType;
        public String title;
        public String subtitle;

        public LookupSearchResult(
            String id,
            String sObjectType,
            String title,
            String subtitle
        ) {
            this.id = id;
            this.sObjectType = sObjectType;
            this.title = title;
            this.subtitle = subtitle;
        }
        public LookupSearchResult() {
        }

        @AuraEnabled
        public Id getId() {
            return id;
        }

        @AuraEnabled
        public String getSObjectType() {
            return sObjectType;
        }

        @AuraEnabled
        public String getTitle() {
            return title;
        }

        @AuraEnabled
        public String getSubtitle() {
            return subtitle;
        }
    }
}