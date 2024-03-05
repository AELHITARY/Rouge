//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_QuoteCPQCalculateManagers
//-- Modifie par : SOPRA STERIA
//-- Modifié le  : 22/07/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_QuoteCPQCalculateManagers {

    /**
    * @description Méthode pour calculer les managers (DV et DO) sur les devis CPQ pour approbation
    * @param quotesList Liste des devis CPQ
    */
    @InvocableMethod(label='CPQ - Calculer managers' description='Calcule les managers (DV et DO) sur les devis CPQ pour approbation')
    public static void calculateManagers(List<String> quotesList) {     
        System.debug('### DEBUT IV_QuoteCPQCalculateManagers : calculateManagers');      
        List<String> ownersListId = new List<String>();
        List<Collaborator__c> calManagerCollaborator = new List<Collaborator__c>();
        Map<String, Collaborator__c> managerMap = new Map<String, Collaborator__c>(); 
        List<SBQQ__Quote__c> quotesToUp = new List<SBQQ__Quote__c>();

        try {
            List<SBQQ__Quote__c> quotes = [SELECT Id, OwnerId, ManagerNiveau2__c, ManagerNiveau3__c FROM SBQQ__Quote__c WHERE Id IN :quotesList];

            if(!quotes.isEmpty()) {
                String dvJobId;
                String doJobId;
                Boolean isDVUser = false;
                Collaborator__c managerDO;
                Collaborator__c managerDV;
                String dvJobRef = PropertiesUtils.getStringValue('ref.job.dv.code', 'HJOB-DV');
                String doJobRef = PropertiesUtils.getStringValue('ref.job.do.code', 'HJOB-DO');
                List<String> jobsRefList = new List<String>{dvJobRef, doJobRef};

                // Recupération des IDs des métiers DV et DO
                String rtHiearchyJobId = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_JOBHIERARCHY_RT);
                for(Referencial__c ref : [SELECT Id, KparKReference__c FROM Referencial__c WHERE RecordTypeId = :rtHiearchyJobId AND KparKReference__c IN :jobsRefList]) {
                    if(ref.KparKReference__c == dvJobRef) {
                        dvJobId = ref.Id;
                    } else {
                        doJobId = ref.Id;
                    }
                }                
                System.debug('## Id Hierarchy Job DV: '+dvJobId);
                System.debug('## Id Hierarchy Job DO: '+doJobId);
                // Récupération infos des propriétaire grâce au référentiel Collaborateur
                for(SBQQ__Quote__c devis : quotes) {
                    ownersListId.add(devis.OwnerId);
                }
                for(Collaborator__c newCollaborator : [SELECT Id, Name, user__c, manager__c, job__r.jobHierarchy__c 
                                                        FROM Collaborator__c WHERE user__c IN :ownersListId]) {
                    calManagerCollaborator.add(newCollaborator);
                    if(newCollaborator.job__r.jobHierarchy__c == dvJobId) {
                        isDVUser = true;
                    }
                }
                System.debug('## Est DV: '+isDVUser);
                System.debug('## Collaborators: '+calManagerCollaborator);

                // Récupération des managers
                if(!calManagerCollaborator.isEmpty()) {
                    // Calcul du manager DV
                    managerMap = Utils_Collaborator.getManagerByJob(calManagerCollaborator, Date.today(), dvJobId);
                    if(managerMap != null) {
                        for(Collaborator__c collab : calManagerCollaborator) {
                            managerDV = (managerMap.get(collab.Id) != null) ? managerMap.get(collab.Id) : null;
                            System.debug('## DV: '+managerDV);
                        }
                    }
                    // Calcul du manager DO
                    managerMap = null;
                    managerMap = Utils_Collaborator.getManagerByJob(calManagerCollaborator, Date.today(), doJobId);
                    if(managerMap != null) {
                        for(Collaborator__c collab : calManagerCollaborator) {
                            managerDO = (managerMap.get(collab.Id) != null) ? managerMap.get(collab.Id) : null;
                            System.debug('## DO: '+managerDO);
                        }
                    }
                }

                // Mise à jour du devis
                for(SBQQ__Quote__c quotesToProcess : quotes) {
                    /*if(isDVUser) {
                        quotesToProcess.ManagerNiveau2__c = (managerDO != null) ? managerDO.user__c : null;
                    } else {
                        quotesToProcess.ManagerNiveau2__c = (managerDV != null) ? managerDV.user__c : null;
                        quotesToProcess.ManagerNiveau3__c = (managerDO != null) ? managerDO.user__c : null;
                    }*/
                    quotesToProcess.ManagerNiveau2__c = (managerDV != null) ? managerDV.user__c : null;
                    quotesToProcess.ManagerNiveau3__c = (managerDO != null) ? managerDO.user__c : null;
                    System.debug('## Devis ManagerNiveau2: '+quotesToProcess.ManagerNiveau2__c);
                    System.debug('## Devis ManagerNiveau3: '+quotesToProcess.ManagerNiveau3__c);
                    if(quotesToProcess.ManagerNiveau2__c != null && quotesToProcess.ManagerNiveau3__c != null) {
                        quotesToUp.add(quotesToProcess);
                    }
                }
                if(!quotesToUp.isEmpty()) {
                    update quotesToUp;
                }
            }
            System.debug('### FIN IV_QuoteCPQCalculateManagers : calculateManagers');
        } catch(Exception e){
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
}