//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_ContentDocumentLink
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 15/06/2022
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_ContentDocumentLink {

    /**
    * @description Fonction pour créer des liens publique pour les fichiers
    * @param userContext Information de l'utilisateur courant
    */
    public static void createPublicLinkForFile(UserContext userContext) {
        System.debug('### DEBUT TR022_ContentDocumentLink.createPublicLinkForFile');        
        List<ContentDistribution> distributionsToInsert = new List<ContentDistribution>();
        Set<String> ctDocIdToCheck = new Set<String>();
        List<ContentVersion> ctVersionIdToCheck = new List<ContentVersion>();

        for(ContentDocumentLink newCtLink : (List<ContentDocumentLink>)Trigger.new){
            // Vérification si lié a un Case
            if( (Trigger.isInsert) && newCtLink.LinkedEntityId.getSobjectType() == Schema.getGlobalDescribe().get('Case')){
                System.debug('## Case: '+newCtLink.LinkedEntityId);
                ctDocIdToCheck.add(newCtLink.ContentDocumentId);
            }
        }

        System.debug('## ctDocIdToCheck: '+ctDocIdToCheck);
        if(!ctDocIdToCheck.isEmpty()) {
            // Récupération des ContentVersion
            for(ContentVersion ctVers : [SELECT Id, Title FROM ContentVersion WHERE ContentDocumentId IN :ctDocIdToCheck]) {
                ctVersionIdToCheck.add(ctVers);
            }
            System.debug('## ctVersionIdToCheck: '+ctVersionIdToCheck);
            // Récupération des ContentDistribution
            List<ContentDistribution> ctDisList = [SELECT Id, ContentVersionId FROM ContentDistribution WHERE ContentVersionId IN :ctVersionIdToCheck];
            System.debug('## ctDisList: '+ctDisList);
            for(ContentVersion ctVers : ctVersionIdToCheck) {
                System.debug('## ctVers: '+ctVers.Id);
                Boolean linkToCreate=true;
                for(ContentDistribution ctDis : ctDisList) {
                    if(ctDis.ContentVersionId == ctVers.Id) {
                        linkToCreate=false;
                    }
                }
                if(linkToCreate) {
                    // Création de l'objet
                    distributionsToInsert.add(createContentDistribution(ctVers));
                }
            }
        }

        // Insert des lignes
        System.debug('## distributionsToInsert: '+distributionsToInsert);
        if(!distributionsToInsert.isEmpty()) {
            insert distributionsToInsert;
        }
        System.debug('### FIN TR022_ContentDocumentLink.createPublicLinkForFile');   
    }

    /**
    * @description Fonction pour les différents objets
    * @param userContext Information de l'utilisateur courant
    */
    public static void processLinkToObject(UserContext userContext) {
        System.debug('### DEBUT TR022_ContentDocumentLink.processLinkToObject');        
        List<ContentDocumentLink> cdLinkCase = new List<ContentDocumentLink>();

        // Récupération des liens pour vérifier l'objet
        for(ContentDocumentLink newCtLink : (List<ContentDocumentLink>)Trigger.new){
            // Vérification si lié a un Case
            if( (Trigger.isInsert) && newCtLink.LinkedEntityId.getSobjectType() == Schema.getGlobalDescribe().get('Case')){
                System.debug('## Case: '+newCtLink.LinkedEntityId);
                cdLinkCase.add(newCtLink);
            }
        }

        // Processus par objet
        if(!cdLinkCase.isEmpty()) {
            TR022_ContentVersion.casePNCProviderNotification(cdLinkCase);
        }
        System.debug('### FIN TR022_ContentDocumentLink.processLinkToObject');   
    }
    
    /**
    * @description Fonction pour créer l'objet pour le lien public
    * @param contentVersion Objet ContentVersion
    */
    @TestVisible
    private static ContentDistribution createContentDistribution(ContentVersion contentVersion){
        ContentDistribution newDist = new ContentDistribution();
        newDist.ContentVersionId = contentVersion.Id;
        newDist.Name = contentVersion.Title;
        newDist.PreferencesNotifyOnVisit = false;
        newDist.PreferencesAllowViewInBrowser = true;
        newDist.PreferencesAllowOriginalDownload=true;
        newDist.PreferencesLinkLatestVersion=true;
        System.debug('## newDist: '+newDist);
        return newDist;
    }
}