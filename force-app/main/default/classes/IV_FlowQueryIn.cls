//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_FlowQueryIn
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 07/09/2020
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
global without sharing class IV_FlowQueryIn {

    public IV_FlowQueryIn() {

    }

    @InvocableMethod
    public static List<Results> queryFilter(List<Request> request) {        
        System.debug('### DEBUT IV_FlowQueryIn.queryFilter');
        String query = '';
        Results curResult = new Results();        
        List<Results> resultsList = new List<Results>();
        
        try {
            if(!request.isEmpty()) {
                // Récupération des paramètres d'entrée
                Request param = request[0];
                // Gestion des erreurs
                if(String.isBlank(param.objectName)) {
                    throw new FlowActionException('Le paramètre objectName est vide');
                }
                if(String.isBlank(param.fieldsToSelect)) {
                    throw new FlowActionException('Le paramètre fieldsToSelect est vide');
                }
                if(String.isBlank(param.fieldToFilter)) {
                    throw new FlowActionException('Le paramètre fieldToFilter est vide');
                }
                if(String.isBlank(param.filterValuesString) && param.filterValuesList.isEmpty()) {
                    throw new FlowActionException('Les paramètres filterValuesString et filterValuesList sont vide');
                }

                System.debug('## objectName: ' + param.objectName);
                System.debug('## fieldsToSelect: ' + param.fieldsToSelect);
                System.debug('## fieldToFilter: ' + param.fieldToFilter);
                System.debug('## filterValuesString: ' + param.filterValuesString);
                System.debug('## filterValuesList: ' + param.filterValuesList);
                System.debug('## field2ToFilter: ' + param.fieldToFilter);
                System.debug('## filter2ValuesString: ' + param.filter2ValuesString);
                System.debug('## filter2ValuesList: ' + param.filter2ValuesList);
                // Construction de la requête
                List<String> filterValues = new List<String>();
                if(String.isNotBlank(param.filterValuesString)) {
                    filterValues.addAll(param.filterValuesString.split(','));
                }
                if(!param.filterValuesList.isEmpty()) {
                    filterValues.addAll(param.filterValuesList);
                }
                query = 'SELECT ' + param.fieldsToSelect + ' FROM ' + param.objectName + ' WHERE ' + param.fieldToFilter + ' IN :filterValues';
                // Ajout d'un second critère de filtrage
                if(String.isNotBlank(param.field2ToFilter)) {
                    List<String> filter2Values = new List<String>();
                    if(String.isNotBlank(param.filter2ValuesString)) {
                        filter2Values.addAll(param.filter2ValuesString.split(','));
                    }
                    if(!param.filter2ValuesList.isEmpty()) {
                        filter2Values.addAll(param.filter2ValuesList);
                    }
                    query += ' AND ' + param.field2ToFilter + ' IN :filter2Values';
                }
                System.debug('## query: ' + query);
            
                // Exécution de la requête et stockage de sortie
                String objectType = param.objectName;
                switch on objectType {
                    when 'Account' {
                        curResult.filteredAccountCollection = database.query(query);
                    }
                    when 'Case' {
                        curResult.filteredCaseCollection = database.query(query);
                    }
                    when 'Opportunity' {
                        curResult.filteredOpportunityCollection = database.query(query);
                    }
                    when 'Contact' {
                        curResult.filteredContactCollection = database.query(query);
                    }
                    when 'Referencial__c' {
                        curResult.filteredReferencialCollection = database.query(query);
                    }
                    when 'ExpectedDocument__c' {
                        curResult.filteredExpectedDocumentCollection = database.query(query);
                    }
                    when 'Product2' {
                        curResult.filteredProductCollection = database.query(query);
                    }
                    when 'Option__c' {
                        curResult.filteredOptionCollection = database.query(query);
                    }
                    when 'RecordType' {
                        curResult.filteredRecordTypeCollection = database.query(query);
                    }
                    when 'PricebookEntry' {
                        curResult.filteredPricebookEntryCollection = database.query(query);
                    }
                    when 'WorkOrderLineItem' {
                        curResult.filteredWorkOrderLineItemCollection = database.query(query);
                    }
                    when 'Asset' {
                        curResult.filteredAssetCollection = database.query(query);
                    }
                    when 'OrderItem' {
                        curResult.filteredOrderItemCollection = database.query(query);
                    }
                    when 'InvoiceLine__c' {
                        curResult.filteredInvoiceLineCollection = database.query(query);
                    }
                    when 'SBQQ__ProductOption__c' {
                        curResult.filteredProductOptionCollection = database.query(query);
                    }
                }
                resultsList.add(curResult);
                System.debug('## curResult: '+curResult);
            }
            
            if(resultsList.size() == 0){
                Results resultItem = new Results();
                resultItem.filteredAccountCollection.add(new Account(Name = 'Test'));
                resultsList.add(resultItem);
            }

            System.debug('### FIN IV_FlowQueryIn.queryFilter');
        } catch(Exception e){
            throw e;
        }
        return resultsList;
    }
    
    global class Request 
    {       
        @InvocableVariable(label='Nom API des champs à récupérer' required=true)
        global String fieldsToSelect;
        
        @InvocableVariable(label='Nom API de l\'objet' required=true)
        global String objectName;

        @InvocableVariable(label='Nom API du champ à filtrer' required=true)
        global String fieldToFilter;

        @InvocableVariable(label='Valeur pour le filtre (séparée par des virgules)' required=false)
        global String filterValuesString;

        @InvocableVariable(label='Collection de valeurs pour le filtre' required=false)
        global List<String> filterValuesList = new List<String>();

        @InvocableVariable(label='Nom API du champ à filtrer supplémentaire (Filtre AND)' required=false)
        global String field2ToFilter;

        @InvocableVariable(label='Collection de valeurs pour le second filtre' required=false)
        global List<String> filter2ValuesList = new List<String>();

        @InvocableVariable(label='Valeur pour le second filtre (séparée par des virgules)' required=false)
        global String filter2ValuesString;
    }
    
    global class Results 
    {        
        @InvocableVariable
        global List<Account> filteredAccountCollection;

        @InvocableVariable
        global List<Contact> filteredContactCollection;

        @InvocableVariable
        global List<Opportunity> filteredOpportunityCollection;

        @InvocableVariable
        global List<Case> filteredCaseCollection;

        @InvocableVariable
        global List<Referencial__c> filteredReferencialCollection;

        @InvocableVariable
        global List<ExpectedDocument__c> filteredExpectedDocumentCollection;

        @InvocableVariable
        global List<Product2> filteredProductCollection;

        @InvocableVariable
        global List<Option__c> filteredOptionCollection;

        @InvocableVariable
        global List<RecordType> filteredRecordTypeCollection;

        @InvocableVariable
        global List<PricebookEntry> filteredPricebookEntryCollection;

        @InvocableVariable
        global List<WorkOrderLineItem> filteredWorkOrderLineItemCollection;
        
        @InvocableVariable
        global List<Asset> filteredAssetCollection;
        
        @InvocableVariable
        global List<OrderItem> filteredOrderItemCollection;
        
        @InvocableVariable
        global List<invoiceLine__c> filteredInvoiceLineCollection;
        
        @InvocableVariable
        global List<SBQQ__ProductOption__c> filteredProductOptionCollection;
    }
    
    public class FlowActionException extends Exception {}
}