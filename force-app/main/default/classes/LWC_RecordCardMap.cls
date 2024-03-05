//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_RecordCardMap
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 26/03/2020
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_RecordCardMap {    

    /**
    * @description Récupération de la latitude et longitude selon l'objet
    * @param objectName Nom API de l'objet
    * @param recordId Id de l'enregistrement
    * @param fields Liste des champs à récupérer séparés par une virgule
    * @return Objet contenant les donnes latitude et longitude
    */
    @AuraEnabled
    public static Localisation getRecordLocAndInfos(String objectName, String recordId, String fields){
        System.debug('### DEBUT LWC_RecordCardMap.getRecordLocAndInfos'); 
        System.debug('## objectName: '+objectName); 
        System.debug('## recordId: '+recordId); 
        Localisation result;
        String latitudeField;
        String longitudeField;
        String addressFields;

        if(String.isNotBlank(recordId) && String.isNotBlank(objectName)) {  
            // Récupération des noms des champs localisation
            if(objectName == 'Account' || objectName == 'Contact' || objectName == 'Chantier__c' || objectName == 'Collaborator__c') {
                latitudeField = 'Localisation__Latitude__s';
                longitudeField = 'Localisation__Longitude__s';
            }  
            if(objectName == 'EntityVersion__c') {
                latitudeField = 'geolocalisation__Latitude__s';
                longitudeField = 'geolocalisation__Longitude__s';
            }    
            if(objectName == 'ServiceAppointment') {
                latitudeField = 'FSL__InternalSLRGeolocation__Latitude__s';
                longitudeField = 'FSL__InternalSLRGeolocation__Longitude__s';
            }     
            if(objectName == 'WorkOrder') {
                latitudeField = 'Latitude';
                longitudeField = 'Longitude';
            }         
            if(objectName == 'ServiceTerritory') {
                latitudeField = 'FSL__Internal_SLR_Geolocation__Latitude__s';
                longitudeField = 'FSL__Internal_SLR_Geolocation__Longitude__s';
            }     
            if(objectName == 'ServiceTerritoryMember') {
                latitudeField = 'FSL__Internal_SLR_HomeAddress_Geolocation__Latitude__s';
                longitudeField = 'FSL__Internal_SLR_HomeAddress_Geolocation__Longitude__s';
            }     
            if(objectName == 'ServiceResource') {
                latitudeField = 'LastKnownLatitude';
                longitudeField = 'LastKnownLongitude';
            }     
            if(objectName == 'ResourceAbsence') {
                latitudeField = 'Latitude';
                longitudeField = 'Longitude';
            } 

            // Récupération des informations de l'enregistrement
            if((String.isBlank(latitudeField) && String.isBlank(longitudeField) && String.isBlank(addressFields)) == false) {
                result = processRetrieveRecord(objectName, recordId, latitudeField, longitudeField, addressFields, fields);
            }
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_RecordCardMap.getRecordLocAndInfos'); 
        return result;
    }

    /**
    * @description Récupération de la latitude et longitude de l'enregistrement parent
    * @param objectName Nom API de l'objet
    * @param recordId Id de l'enregistrement
    * @param fields Liste des champs à récupérer séparés par une virgule
    * @return Objet contenant les donnees latitude et longitude
    */
    @AuraEnabled
    public static Localisation getParentRecordLocAndInfos(String objectName, String recordId, String fields){
        System.debug('### DEBUT LWC_RecordCardMap.getParentRecordLocAndInfos'); 
        System.debug('## objectName: '+objectName); 
        System.debug('## recordId: '+recordId); 
        Localisation result;
        String parentId;
        String parentField;

        if(String.isNotBlank(recordId) && String.isNotBlank(objectName)) {  
            // Récupération des nom champs
            if(objectName == 'Account' ) {
                parentField = 'ParentId';
            }        
            // Récupération de l'Id du parent         
            String soqlQuery = 'SELECT Id, ' + parentField + ' FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';
            System.debug('## Query: '+soqlQuery); 
            // Exécution et traitement résultat
            List<sObject> sobjList = Database.query(soqlQuery);
            System.debug('## Result size: '+sobjList.size());
            if(!sobjList.isEmpty()) {
                parentId = (String)sobjList[0].get(parentField);
            } 

            // Récupération des infos du parent
            System.debug('## parentId: '+parentId); 
            if(String.isNotBlank(parentId)) {
                result = getRecordLocAndInfos(objectName, parentId, fields);
            }
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_RecordCardMap.getParentRecordLocAndInfos'); 
        return result;
    }

    /**
    * @description Récupération de la latitude et longitude d'un enregistrement associé
    * @param objectName Nom API de l'objet
    * @param relatedObjectName Nom API de l'objet associé
    * @param relatedRecordField Nom API du champ de liaison
    * @param fields Liste des champs à récupérer séparés par une virgule
    * @return Objet contenant les donnees latitude et longitude
    */
    @AuraEnabled
    public static Localisation getRelatedRecordLocAndInfos(String objectName, String recordId, 
                                                            String relatedObjectName, String relatedRecordField, 
                                                            String fields){
        System.debug('### DEBUT LWC_RecordCardMap.getRelatedRecordLocAndInfos'); 
        System.debug('## objectName: '+objectName); 
        System.debug('## relatedObjectName: '+relatedObjectName); 
        System.debug('## relatedRecordField: '+relatedRecordField); 
        Localisation result;
        String relatedRecordId;

        if(String.isNotBlank(relatedRecordField) && String.isNotBlank(relatedObjectName) && String.isNotBlank(recordId)) {  
            // Récupération de l'Id du parent         
            String soqlQuery = 'SELECT Id, ' + relatedRecordField + ' FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';
            System.debug('## Query: '+soqlQuery); 
            // Exécution et traitement résultat
            List<sObject> sobjList = Database.query(soqlQuery);
            System.debug('## Result size: '+sobjList.size());
            if(!sobjList.isEmpty()) {
                relatedRecordId = (String)sobjList[0].get(relatedRecordField);
            } 

            // Récupération des infos de l'enregistrement associés
            result = getRecordLocAndInfos(relatedObjectName, relatedRecordId, fields);
        }
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_RecordCardMap.getRelatedRecordLocAndInfos'); 
        return result;
    }

    /**
    * @description Récupération de la latitude et longitude des entités commerciales et de service
    * @param objectName Nom API de l'objet
    * @param recordId Id de l'enregistrement
    * @param salesEntityField Nom API du champ stockant l'ID de l'entité commerciale
    * @param serviceEntityField Nom API du champ stockant l'ID de l'entité de service
    * @param fields Liste des champs à récupérer séparés par une virgule
    * @return Objet contenant les donnees latitude et longitude
    */
    @AuraEnabled
    public static List<Localisation> getEntitiesLocAndInfos(String objectName, String recordId, String salesEntityField, String serviceEntityField, String fields){
        System.debug('### DEBUT LWC_RecordCardMap.getEntitiesLocAndInfos'); 
        System.debug('## objectName: '+objectName); 
        System.debug('## recordId: '+recordId); 
        System.debug('## salesEntityField: '+salesEntityField); 
        System.debug('## serviceEntityField: '+serviceEntityField); 
        List<Localisation> result = new List<Localisation>();
        String salesEntityId;
        String serviceEntityId;

        if(String.isNotBlank(recordId) && (String.isNotBlank(salesEntityField) || String.isNotBlank(serviceEntityField))) {  
            // Récupération des Id des entités
            String soqlQuery = 'SELECT Id, ';
            
            // Ajout des champs addresse
            if(String.isNotBlank(salesEntityField) && String.isNotBlank(serviceEntityField)) {
                soqlQuery +=  salesEntityField + ', ' + serviceEntityField;
            }
            else if(String.isNotBlank(salesEntityField) && String.isBlank(serviceEntityField)) {
                soqlQuery += salesEntityField;
            } 
            else if(String.isBlank(salesEntityField) && String.isNotBlank(serviceEntityField)) {
                soqlQuery += serviceEntityField;
            }
            soqlQuery += ' FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';
            System.debug('## Query: '+soqlQuery); 
            // Exécution et traitement résultat
            List<sObject> sobjList = Database.query(soqlQuery);
            System.debug('## Result size: '+sobjList.size());
            if(!sobjList.isEmpty()) {
                if(String.isNotBlank(salesEntityField)) {
                    salesEntityId = (String)sobjList[0].get(salesEntityField);
                }
                if(String.isNotBlank(serviceEntityField)) {
                    serviceEntityId = (String)sobjList[0].get(serviceEntityField);
                }
            } 

            // Récupération des infos de l'entité commerciale
            System.debug('## salesEntityId: '+salesEntityId); 
            if(String.isNotBlank(salesEntityId)) {
                Localisation res = getRecordLocAndInfos('Account', salesEntityId, fields);
                if(res != null) {
                    result.add(res);
                }
            }
            // Récupération des infos de l'entité service
            System.debug('## serviceEntityId: '+serviceEntityId); 
            if(String.isNotBlank(serviceEntityId)) {
                Localisation res = getRecordLocAndInfos('Account', serviceEntityId, fields);
                if(res != null) {
                    result.add(res);
                }
            }
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_RecordCardMap.getEntitiesLocAndInfos'); 
        return result;
    }

    /**
    * @description Récupération de la latitude et longitude des territoires de service
    * @param objectName Nom API de l'objet
    * @param recordId Id de l'enregistrement
    * @param fields Liste des champs à récupérer séparés par une virgule
    * @return List<Localisation> Objet contenant la liste des donnees latitude et longitude des territoires de service
    */
    @AuraEnabled
    public static List<Localisation> getServiceTerritoryRecordLocAndInfos(String objectName, String recordId, String fields){
        System.debug('### DEBUT LWC_RecordCardMap.getServiceTerritoryRecordLocAndInfos'); 
        System.debug('## objectName: '+objectName); 
        System.debug('## recordId: '+recordId); 
        List<Localisation> result = new List<Localisation>();
        String parentId;
        String parentField;
        String soqlQuery;

        if(String.isNotBlank(recordId) && String.isNotBlank(objectName)) {  
            // Récupération des nom champs
            if(objectName == 'WorkOrder' || objectName == 'ServiceAppointment' || objectName == 'ServiceTerritoryMember') {
                parentField = 'ServiceTerritoryId';
                soqlQuery = 'SELECT Id, ' + parentField + ' FROM ' + objectName + ' WHERE Id = :recordId';
            } else if(objectName == 'ServiceResource') {
                parentField = 'Id';
                String recordFilter = '(SELECT ServiceTerritoryId FROM ServiceTerritoryMember WHERE ServiceResourceId = :recordId)';
                System.debug('## recordFilter: '+recordFilter); 
                soqlQuery = 'SELECT ' + parentField + ' FROM ServiceTerritory WHERE Id IN '+recordFilter;
            } 
            System.debug('## Query: '+soqlQuery); 
            // Exécution
            List<sObject> sobjList = Database.query(soqlQuery);
            System.debug('## Result size: '+sobjList.size());
            // Traitement résultat
            if(!sobjList.isEmpty()) {
                for(sObject sobj : sobjList) {
                    parentId = (String)sobj.get(parentField);
                    // Récupération des infos du parent
                    System.debug('## parentId: '+parentId); 
                    if(String.isNotBlank(parentId)) {
                        Localisation loc = getRecordLocAndInfos('ServiceTerritory', parentId, fields);
                        if(loc != null) {
                            result.add(loc);
                        }
                    }
                }
            }
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_RecordCardMap.getServiceTerritoryRecordLocAndInfos'); 
        return result;
    }

    /**
    * @description Récupération des informations des polygones FSL
    * @param objectName Nom API de l'objet
    * @param recordId Id de l'enregistrement
    * @return List<SectorFSL> Objet contenant la liste des donnees latitude et longitude des secteurs FSL
    */
    @AuraEnabled
    public static List<SectorFSL> getFSLMapPolygonInfos(String objectName, String recordId){
        System.debug('### DEBUT LWC_RecordCardMap.getFSLMapPolygonInfos'); 
        System.debug('## recordId: '+recordId); 
        List<SectorFSL> result = new List<SectorFSL>();
        String parentField;

        if(String.isNotBlank(recordId)) {   
            // Construction de la requête en fonction de l'objet    
            if(objectName == 'ServiceTerritory') {
                parentField = 'FSL__Service_Territory__c';
            } else if(objectName == 'ServiceTerritoryMember') {
                ServiceTerritoryMember stm = [SELECT Id, ServiceTerritoryId FROM ServiceTerritoryMember WHERE Id =: recordId];
                recordId = stm.ServiceTerritoryId;
                parentField = 'FSL__Service_Territory__c';
            }else {
                parentField = 'Id';
            }      
            String soqlQuery = 'SELECT Id, Name, FSL__Color__c, FSL__KML__c FROM FSL__Polygon__c WHERE '+ parentField +'= :recordId';
            System.debug('## Query: '+soqlQuery); 
            // Exécution et traitement résultat
            List<FSL__Polygon__c> fslPolygonList = Database.query(soqlQuery);

            // Traitement du champ KML pour récupérer que les coordonnées
            for(FSL__Polygon__c fslPolygon : fslPolygonList) {
                System.debug('## FSL Polygon: '+fslPolygon.Name); 
                String coord = null;
                // Parse de la valeur XML pour récupérer que les coordonnées
                if(String.isNotBlank(fslPolygon.FSL__KML__c)) {
                    Dom.Document doc = new Dom.Document();
                    doc.load(fslPolygon.FSL__KML__c);
                    DOM.XmlNode rootNode=doc.getRootElement();
                    coord = parseXML(rootNode);
                }
                // Création du résultat
                result.add(new SectorFSL(
                    fslPolygon.Name,
                    fslPolygon.FSL__Color__c,
                    coord,
                    fslPolygon
                    )
                );
            }
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_RecordCardMap.getFSLMapPolygonInfos'); 
        return result;
    }

    /**
    * @description Fonction pour forcer la géolocalisation d'un enregistrement
    * @param objectName Nom API de l'objet
    * @param recordId Id de l'enregistrement
    */
    @AuraEnabled
    public static void forceRecordGeolocalisation(String objectName, String recordId){
        System.debug('### DEBUT LWC_RecordCardMap.forceRecordGeolocalisation'); 
        System.debug('## objectName: '+objectName); 
        System.debug('## recordId: '+recordId); 

        if(String.isNotBlank(recordId) && String.isNotBlank(objectName)) {  
            Set<Id> recordIdList = new Set<Id>();
            recordIdList.add(recordId);
            // Execution du processus en fonction du nom de l'objet
            if(objectName == 'Account') {
                GeoUtils.updateAccounts(recordIdList);
            } else if (objectName == 'Chantier__c') {                
                GeoUtils.updateChantiers(recordIdList);
            } else if (objectName == 'EntityVersion__c') {
                GeoUtils.updateEntityVersions(recordIdList);
            } else if (objectName == 'Collaborator__c') {
                GeoUtils.updateCollaborators(recordIdList);
            }        
        }        
        System.debug('### FIN LWC_RecordCardMap.forceRecordGeolocalisation'); 
    }

    /**
    * @description Récupération de la latitude et longitude de l'enregistrement parent
    * @param objectName Nom API de l'objet
    * @param recordId Id de l'enregistrement
    * @param fields Liste des champs à récupérer séparés par une virgule
    * @return Objet contenant les donnees latitude et longitude
    */
    private static Localisation processRetrieveRecord(String objectName, String recordId, String latitudeField, 
                                                        String longitudeField, String addressFields, String fields){
        System.debug('### DEBUT LWC_RecordCardMap.processRetrieveRecord'); 
        Localisation result;

        if(String.isNotBlank(recordId) && String.isNotBlank(objectName)) {  
            // Construction requête SOQL          
            String soqlQuery = 'SELECT Id, ';
            // Ajout des champs addresse
            if(String.isNotBlank(latitudeField) && String.isNotBlank(longitudeField)) {
                soqlQuery += latitudeField + ', ' + longitudeField;
            }
            if(String.isNotBlank(addressFields)) {
                soqlQuery += addressFields;
            }
            // Ajout des champs supplémentaires
            if(String.isNotBlank(fields)) {
                soqlQuery += ', ' + fields;
            }
            soqlQuery += ' FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';
            System.debug('## Query: '+soqlQuery); 
            // Exécution et traitement résultat
            List<sObject> sobjList = Database.query(soqlQuery);
            System.debug('## Result size: '+sobjList.size());
            if(!sobjList.isEmpty()) {
                Double latitude = (String.isNotBlank(latitudeField)) ? Double.valueOf(sobjList[0].get(latitudeField)) : null;
                Double longitude = (String.isNotBlank(longitudeField)) ? Double.valueOf(sobjList[0].get(longitudeField)) : null;
                result = new Localisation(latitude, longitude, sobjList[0] );
            } 
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_RecordCardMap.getParentRecordLocAndInfos'); 
        return result;
    }

    /**
    * @description Fonction récursive pour parser le XML KML de FSL afin de récupérer les coordonnées
    * @param node Node XML
    * @return Valeur des coordonnées
    */
    private static String parseXML(DOM.XMLNode node) {
        String result;
        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
            System.debug(node.getName());
            if(node.getName()=='coordinates') {
                result=node.getText().trim();
                return result;
            }
        }
        for (Dom.XMLNode child: node.getChildElements()) {
            result = parseXML(child);
        }
        return result;
    }

    public class Localisation {
        private Decimal latitude;
        private Decimal longitude;
        private sObject record;

        public Localisation(
            Decimal latitude,
            Decimal longitude,
            sObject record
        ) {
            this.latitude = latitude;
            this.longitude = longitude;
            this.record = record;
        }

        @AuraEnabled
        public Decimal getLatitude() {
            return latitude;
        }

        @AuraEnabled
        public Decimal getLongitude() {
            return longitude;
        }

        @AuraEnabled
        public sObject getRecord() {
            return record;
        }
    }

    public class SectorFSL {
        private String name;
        private String color;
        private String latLongCoordinates;
        private sObject record;

        public SectorFSL(
            String name,
            String color,
            String latLongCoordinates,
            sObject record
        ) {
            this.name = name;
            this.color = color;
            this.latLongCoordinates = latLongCoordinates;
            this.record = record;
        }

        @AuraEnabled
        public String getName() {
            return name;
        }

        @AuraEnabled
        public String getColor() {
            return color;
        }

        @AuraEnabled
        public String getLatLongCoordinates() {
            return latLongCoordinates;
        }

        @AuraEnabled
        public sObject getRecord() {
            return record;
        }
    }
}