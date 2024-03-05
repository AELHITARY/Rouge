//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Milestone
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/07/2017
//-- Version     : 1.1
//-- * 1.0 : CRM-956 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_Milestone {
    
    /**
    * @description Arrêt des jalons et mise à jour de la date de première réponse si premier email envoyé au client
    * @param userContext Information de l'utilisateur courant
    */
    public static void jalonPremierEmail(UserContext userContext) {
        // Récupération des requêtes pour lesquelles le premier email viens d'être envoyé au client.
        Map<Id, String> emIds = new Map<Id, String>();
        for(EmailMessage em : (List<EmailMessage>)Trigger.new){
            if(em.Incoming == false)
                emIds.put(em.ParentId, em.ToAddress);
        }
        if (!emIds.isEmpty()){
            // Boucle sur les requêtes pour MAJ champ
            List<Case> casesToUpdate = new List<Case>();
            for (Case caseObj : [SELECT Id, datePremiereReponse__c, Contact.Email
                                    FROM Case WHERE Id IN :emIds.keySet() AND Status != :Constants.REQUETE_STATUS_CLOSED]) {
                if((emIds.get(caseObj.Id)==caseObj.Contact.Email) && caseObj.datePremiereReponse__c == null){
                    casesToUpdate.add(caseObj);
                }
            }
            if (!casesToUpdate.isEmpty())
                updateFirstRespAndCloseMiles(casesToUpdate);
        }
    }  
    
    /**
    * @description Arrêt des jalons et mise à jour de la date de première réponse si premier commentaire publique provenant du réseau KparK
    * @param userContext Information de l'utilisateur courant
    */
    public static void jalonPremierCommentaire(UserContext userContext) {
        // Récupération des requêtes pour lesquelles le premier commentaire viens d'être créé.
        Set<Id> caseIds = new Set<Id>();
        Set<Id> owwnerId = new Set<Id>();
        // Récupération du propriétaire des commentaires pour vérifier leur type (provenant du site ou du réseau KPK)
        for (CaseComment cc : (List<CaseComment>)Trigger.new){
            if(cc.IsPublished == true) 
                owwnerId.add(cc.CreatedById);
        }
        if (!owwnerId.isEmpty()){
            // Vérification du type d'utilisateur et exécution du processus seulement si c'est un utilisateur non invité
            Map<Id,User> usersMap = new Map<Id,User>([SELECT Id, UserType FROM User WHERE Id IN :owwnerId]);
            for (CaseComment cc : (List<CaseComment>)Trigger.new){
                if(cc.IsPublished == true && usersMap.get(cc.CreatedById).UserType != 'Guest') {
                    caseIds.add(cc.ParentId);
                }
            }
            // Boucle sur les requêtes pour MAJ champ
            if (!caseIds.isEmpty()){
                List<Case> casesToUpdate = new List<Case>();
                for (Case caseObj : [SELECT Id, datePremiereReponse__c
                                        FROM Case WHERE Id IN :caseIds AND Status != :Constants.REQUETE_STATUS_CLOSED]) {
                    if(caseObj.datePremiereReponse__c == null){
                        casesToUpdate.add(caseObj);
                    }
                }
                if (!casesToUpdate.isEmpty())
                    updateFirstRespAndCloseMiles(casesToUpdate);
            }
        }
    }   
    
    /**
    * @description Fonction permettant de mettre à jour le champ "Date de première réponse" et de cloturer les jalons
    * @param casesToUpdate Liste des requêtes à mettre à jour
    */
    private static void updateFirstRespAndCloseMiles(List<Case> casesToUpdate) {
        // Mise à jour de la date de première réponse sur les requêtes concernées.
        for(Case c : casesToUpdate){
            c.datePremiereReponse__c = System.now();
        }
        update casesToUpdate;
        // Mise à jour de la date de fermeture du jalon de requête pour le stopper.
        List<CaseMilestone> cmsToUpdate = [SELECT Id, CompletionDate FROM CaseMilestone WHERE CaseId IN :casesToUpdate];
        if (!cmsToUpdate.isEmpty()){
            for (CaseMilestone cm : cmsToUpdate){
                cm.CompletionDate = System.now();
            }
            update cmsToUpdate;
        }
    }
}