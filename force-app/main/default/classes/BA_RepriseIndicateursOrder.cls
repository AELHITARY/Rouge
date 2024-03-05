//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseIndicateursOrder 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 07/09/2023
//-- Version     : 1.0
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseIndicateursOrder implements Database.Batchable<sObject>, Database.Stateful {

    global Date dateDebut {get;set;}
    global Date dateFin {get;set;}

    /***** Constructor *****/
    global BA_RepriseIndicateursOrder(Date dateDebut, Date dateFin) {
        this.dateDebut = dateDebut;
        this.dateFin = dateFin; 
        System.debug('## dateDebut : '+dateDebut);
            System.debug('## dateFin : '+dateFin);
    }
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
    System.debug('## dateDebut : '+dateDebut);
            System.debug('## dateFin : '+dateFin);
        try {
            String CUSTOMER_ORDER_RTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
            return Database.getQueryLocator([SELECT Id, transmissionDate__c, firstTransmissionDate__c, RecordTypeId
                    FROM Order 
                    WHERE RecordTypeId = :CUSTOMER_ORDER_RTID AND EffectiveDate >= :dateDebut AND EffectiveDate <= :dateFin]);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch Reprise du calcul des indicateurs de Order : Erreur lors de l\'initialisation du batch', e);
            return null;
        } 
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext BC, List<Order> scope) {
        system.debug('## Scope size: '+scope.size()); 
        try {
            system.debug('scope : '+scope);
            Map<Id,List<Order>> cOrderIdtoProviderOrderMap = new Map<Id,List<Order>>();
            List<Order> allProviderOrderList = new List<Order>();

            String CUSTOMER_ORDER_RTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_CUSTOMER);
            String PROVIDER_ORDER_RTID = DAL.getRecordTypeIdByDevName('Order', Constants.ORDER_RT_PROVIDER);


            // Récupération des commandes fournisseur
            if(!scope.isEmpty()) {
                allProviderOrderList = [SELECT Id, parentOrder__c, transmissionDate__c, Status, Type FROM Order WHERE Status != 'Cancelled' AND RecordTypeId = :PROVIDER_ORDER_RTID AND parentOrder__c IN :scope];

                for(Order ord : allProviderOrderList){
                    List<Order> ordList = new List<Order>();
                    if(cOrderIdtoProviderOrderMap.get(ord.parentOrder__c) != null){
                        ordList = cOrderIdtoProviderOrderMap.get(ord.parentOrder__c);
                    }
                    ordList.add(ord);
                    cOrderIdtoProviderOrderMap.put(ord.parentOrder__c,ordList);
                }
            
                for (Order newOrder : scope) {    
                    if(newOrder.RecordTypeId == CUSTOMER_ORDER_RTID && cOrderIdtoProviderOrderMap.get(newOrder.Id) != null  && !cOrderIdtoProviderOrderMap.get(newOrder.Id).isEmpty()){
                        newOrder.firstTransmissionDate__c = null;
                        newOrder.transmissionDate__c = null;
                        for(Order ord : cOrderIdtoProviderOrderMap.get(newOrder.Id)){
                            if(ord.Type == 'Commande marchandise' && ord.transmissionDate__c != null){
                                if(newOrder.firstTransmissionDate__c == null || ord.transmissionDate__c < newOrder.firstTransmissionDate__c){
                                    newOrder.firstTransmissionDate__c = ord.transmissionDate__c;
                                }
                                if(newOrder.transmissionDate__c == null || ord.transmissionDate__c > newOrder.transmissionDate__c){
                                    newOrder.transmissionDate__c = ord.transmissionDate__c;
                                }
                            }
                        }
                    }
                }
            }
            
            //update scope;
            Database.SaveResult[] results = Database.update(scope, false);
        } catch (Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Batch Reprise du calcul des indicateurs de Order : Erreur lors de la génération du mot de passe', e);
        }
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish(Database.BatchableContext BC) {      
    }   
}