//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_CustomCustomerOrderLegacyWizard
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 07/11/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class LWC_CustomCustomerOrderLegacyWizard {

    /**
    * @description Récupération de la liste des actifs d'une commande client
    * @param recordId Id de la commande
    * @return Liste des actifs de la commande
    */
    @AuraEnabled(Cacheable = true)
    public static List<OrderItemQLI> getOrderItems(String recordId){
        System.debug('### DEBUT LWC_CustomCustomerOrderLegacyWizard.getOrderItems'); 
        List<OrderItemQLI> result = new List<OrderItemQLI>();
        System.debug('## customerOrderId: '+recordId); 

        // Récupération des OrderItems
        if(String.isNotBlank(recordId)) {            
            for(OrderItem oli : [SELECT Id, productCode__c, Quantity, dimensions__c, location__c, 
                                locationPrecision__c, parentOrderItem__c, productType__c FROM OrderItem 
                                WHERE OrderId = :recordId 
                                    AND parentOrderItem__c = null 
                                    AND QuoteLineItemId = null
                                    AND Quantity != 0]) {
                System.debug('## Récupération des OrderItem: '+oli); 
                result.add(new OrderItemQLI(oli, oli.Id, oli.productCode__c, String.valueOf(oli.Quantity), oli.dimensions__c, oli.location__c+'/'+oli.locationPrecision__c));
            }
        }        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomCustomerOrderLegacyWizard.getOrderItems'); 
        return result;
    }
    
    /**
    * @description Récupération de la liste des lignes de devis
    * @param recordId Id de la commande
    * @return Liste des fournisseurs
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getAllQuoteLines(String recordId){
        System.debug('### DEBUT LWC_CustomCustomerOrderLegacyWizard.getAllQuoteLines'); 
        System.debug('## recordId: '+recordId); 
        List<OptionWrapper> result = new List<OptionWrapper>();

        if(String.isNotBlank(recordId)) {    
            // Récupération des infos de la commande
            Order custOrder = [SELECT Id, QuoteId FROM Order WHERE Id = :recordId LIMIT 1];

            // Affichage unique des fournisseurs
            for(QuoteLineItem qli : [SELECT Id, productCode__c, Emplacement__c, dimensions__c, 
                                        NumLigneText__c, Quantity FROM QuoteLineItem WHERE QuoteId = :custOrder.QuoteId]) {
                String label = qli.NumLigneText__c+' - '+qli.productCode__c+' - '+qli.dimensions__c+' - '+qli.Quantity+' - '+qli.Emplacement__c;
                result.add(new OptionWrapper(label, qli.Id));
            }
        }
        
        System.debug('## result: '+result); 
        System.debug('### FIN LWC_CustomCustomerOrderLegacyWizard.getAllQuoteLines'); 
        return result;
    }
    
    /**
    * @description Mise à jour des lignes de commandes avec les lignes de devis
    * @param orderItemsRec Objet contenant le lien OrderItem/QuoteLineItem
    * @return Liste des lignes de commandes
    */
    @AuraEnabled
    public static List<OrderItem> updateOrderItems(String recordId, Map<String,String> orderItemsRec){
        System.debug('### DEBUT LWC_CustomCustomerOrderLegacyWizard.updateOrderItems'); 
        System.debug('## orderItemsRec: '+orderItemsRec); 
        List<OrderItem> ordItemToUp = new List<OrderItem>();
        Map<String,OrderItem> ordItemMap = new Map<String,OrderItem>();
        Set<OrderItem> ordItemOptToUp = new Set<OrderItem>();
        List<String> ordItemIds = new List<String>();

        // Sauvegarde transaction
        Savepoint sp = Database.setSavepoint();        
        
        try {       
            if(String.isNotBlank(recordId)) {    
                // Récupération des infos de la commande
                Order custOrder = [SELECT Id, QuoteId FROM Order WHERE Id = :recordId LIMIT 1];

                // Construction liste des OrderItems à modifier
                for(String oliId : orderItemsRec.keySet()) {
                    String qliId = orderItemsRec.get(oliId);
                    System.debug('## OrderItem PARENT: '+oliId+' - '+qliId); 
                    ordItemToUp.add(new OrderItem(Id = oliId, QuoteLineItemId = qliId));
                    ordItemIds.add(oliId);
                }

                // MAJ des OrderItem Parent
                System.debug('## ordItemToUp: '+ordItemToUp.size()); 
                if(!ordItemToUp.isEmpty()) {   
                    update ordItemToUp;
                }

                //* Association des lignes de commande enfants avec les lignes de devis et avec les options de la ligne
                // Récupération des options                
                List<Option__c> optQuote = DAL.getOptionList(custOrder.QuoteId);
                // Récupération OrderItems enfant
                List<OrderItem> ordItemOpt = [SELECT Id, name__c, QuoteLineItemId, parentOrderItem__r.QuoteLineItemId, quoteOption__c, productCode__c
                                                FROM OrderItem WHERE parentOrderItem__c IN :ordItemIds];
                System.debug('## ordItemOpt: '+ordItemOpt.size()); 
                
                // Calcul
                for(OrderItem oliOpt : ordItemOpt) {
                    System.debug('## OrderItem OPT: '+oliOpt.Id+' - '+oliOpt.productCode__c+' - '+oliOpt.name__c);
                    oliOpt.QuoteLineItemId = oliOpt.parentOrderItem__r.QuoteLineItemId;
                    for(Option__c opt : optQuote) {
                        if(opt.ligneDevis__c == oliOpt.QuoteLineItemId
                            && (opt.Codeoption__c == oliOpt.productCode__c /*|| opt.Libelleoption__c == oliOpt.name__c*/) ) // BACKLOG #711 Nom abandonné à cause de doublon, en attente de retour de Douglas
                        {
                            System.debug('## Option: '+opt.Id+' - '+opt.Codeoption__c+' - '+opt.Libelleoption__c);
                            oliOpt.quoteOption__c = opt.Id;
                            ordItemOptToUp.add(oliOpt);
                            ordItemMap.put(oliOpt.Id,oliOpt);
                        }
                    }
                }
                System.debug('## ordItemOptToUp: '+ordItemOptToUp.size());

                if(!ordItemOptToUp.isEmpty()) {
                    List<OrderItem> oiList = new List<OrderItem>();
                    for(OrderItem oi : ordItemOptToUp){
                        oiList.add(oi);
                    }
                    /*for(String oiId : ordItemMap.keySet()){
                        oiList.add(ordItemMap.get(oiId));
                    }*/
                    update oiList;
                }
            }

            System.debug('### FIN LWC_CustomCustomerOrderLegacyWizard.updateOrderItems'); 
            return ordItemToUp;
        } catch(Exception e) {
            Database.rollback( sp ); // Rollback des modifications
            throw generateAuraException(e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
    }

    public class OrderItemQLI {
        private OrderItem oli;
        private String id;
        private String productCode;
        private String qty;
        private String dimensions;
        private String location;
        private String qliId;
        private String qliName;

        public OrderItemQLI(
            OrderItem oli,
            String id,
            String productCode,
            String qty,
            String dimensions,
            String location
        ) {
            this.oli = oli;
            this.id = id;
            this.productCode = productCode;
            this.qty = qty;
            this.dimensions = dimensions;
            this.location = location;
        }

        @AuraEnabled
        public String getId() {
            return id;
        }

        @AuraEnabled
        public String getProductCode() {
            return productCode;
        }
        
        @AuraEnabled
        public String getQty() {
            return qty;
        }
        
        @AuraEnabled
        public String getDimensions() {
            return dimensions;
        }

        @AuraEnabled
        public String getLocation() {
            return location;
        }
        
        @AuraEnabled
        public String getQLIId() {
            return qliId;
        }
        
        @AuraEnabled
        public String getQLIName() {
            return qliName;
        }
    }
    
    public class OptionWrapper {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    
    /**
    * @description Fonction pour construire le message d'exeption correctement (sinon pas de message)
    * https://salesforce.stackexchange.com/questions/122657/testing-aurahandledexceptions
    * @param msg Message d'erreur
    * @return AuraHandledException Exception avec le message d'erreur
    */
    public static AuraHandledException generateAuraException(String msg){
        System.debug('ERREUR : ' + msg);
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }
}