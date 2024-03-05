//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_UserQRCodeDisplay
//-- Modifie par : SOPRA STERIA 
//-- Modifie le  : 05/05/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --

public without sharing class LWC_UserQRCodeDisplay {
    /**
    * @description Récupération des données liées à l'utilisateur
    * @param userId Id de l'utilisateur
    * @return Utilisateur avec les champs nécessaires
    */
    @AuraEnabled(Cacheable = false)
    public static User getUserData(String userId){  
        System.debug('### DEBUT LWC_UserQRCodeDisplay.getUserData');
        // VARIABLES
        User user=[SELECT Id, autoQuoteRequestURL__c, autoQuoteRequestQRCodeURL__c FROM User WHERE Id=:userId][0];
        System.debug(user);
        System.debug('### FIN LWC_UserQRCodeDisplay.getUserData');
        return user;
    }

    /**
    * @description Récupération de la liste des numeros associés aux noms de magasins
    * @param userId 
    * @return Map Numéro magasin -> Nom magasin
    */
    /*
    @AuraEnabled(Cacheable = false)
    public static String getMagasinsName(String userId){  
        System.debug('### DEBUT LWC_UserQRCodeDisplay.getMagasinsName');
        // VARIABLES
        Map<String, String> mapMagasins = new Map<String, String>();
        String magasinList = '';
        Boolean firstMagasin=true;
        UserContext context = UserContext.getContext(userId);
        if(context==null){
            System.debug('### FIN LWC_UserQRCodeDisplay.getMagasinsName');
            return null;
        }
        mapMagasins = context.getMagasins();
        if(!mapMagasins.isEmpty()){
            for(String numMagasin : mapMagasins.keySet()){
                magasinList+=numMagasin+'|'+mapMagasins.get(numMagasin)+';';        
            }
            magasinList=magasinList.substring(0, magasinList.length()-1);
        }
        System.debug('### LWC_UserQRCodeDisplay.getMagasinsName magasinList : '+ magasinList);
        System.debug('### FIN LWC_UserQRCodeDisplay.getMagasinsName');
        return magasinList;
        
    }
    */
    @AuraEnabled(Cacheable = false)
    public static List<String> getMagasinsName(String userId){  
        System.debug('### DEBUT LWC_UserQRCodeDisplay.getMagasinsName');
        System.debug('## userId: '+userId);

        // VARIABLES
        Map<String, String> mapMagasins = new Map<String, String>();
        List<String> magasinList = new List<String>();
        UserContext context = UserContext.getContext(userId);
        if(context==null){
            System.debug('### FIN LWC_UserQRCodeDisplay.getMagasinsName');
            return null;
        }
        mapMagasins = context.getMagasins();
        if(!mapMagasins.isEmpty()){
            for(String numMagasin : mapMagasins.keySet()) {
                magasinList.add(numMagasin+'|'+mapMagasins.get(numMagasin));        
            }
        }
        System.debug('## magasinList : '+ magasinList);
        System.debug('### FIN LWC_UserQRCodeDisplay.getMagasinsName');
        return magasinList;  
    }

    /**
    * @description Récupère les informations du magasin (QR Code)
    * @param codeMagasin 
    * @return Magasin avec les champs
    */
    @AuraEnabled(Cacheable = false)
    public static Account getMagasinData(String codeMagasin){  
        System.debug('### DEBUT LWC_UserQRCodeDisplay.getMagasinData');
        System.debug('## codeMagasin: '+codeMagasin);
        Account magasin = null;

        // Ajouter les nouveaux champs dans la requête si nouveaux QR codes associés au magasin
        if(String.isNotBlank(codeMagasin)) {
            List<Account> magList = [SELECT Id, KparKReference__c, CustplaceSatisfactionQRCodeURL__c, CustplaceSatisfactionURL__c FROM Account WHERE KparKReference__c=:codeMagasin LIMIT 1];
            if(!magList.isEmpty()) {
                magasin = magList[0];
            } else {
                throw generateAuraException('Aucun magasin trouvé! Veuillez vérifier le référentiel des entités');
            }
        }
        System.debug('### FIN LWC_UserQRCodeDisplay.getMagasinData');
        return magasin;     
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