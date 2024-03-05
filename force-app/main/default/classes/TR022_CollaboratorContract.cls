//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_CollaboratorContract
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 20/08/2021
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_CollaboratorContract {

    /**
    * @description Méthode pour mettre à jour l'enregistrement collaborateur par rapport au contrat le plus récent
    * @param userContext Information de l'utilisateur courant
    */
    public static void updateCollaboratorsRecords(UserContext userContext) {
        System.debug('### DEBUT TR022_CollaboratorContract.updateCollaboratorsRecords');

        List<CollaboratorContract__c> newCollabContracts = new  List<CollaboratorContract__c>();
        //Map<Id, CollaboratorContract__c> oldCollabContracts = (Map<Id, CollaboratorContract__c>)Trigger.oldMap;
        List<String> collabIds = new List<String>();
        Map<String, CollaboratorContract__c> futurcollaboratorContractsMap = new Map<String, CollaboratorContract__c>();
        Map<String, CollaboratorContract__c> pastcollaboratorContractsMap = new Map<String, CollaboratorContract__c>();
        Map<String, CollaboratorContract__c> activeCollaboratorContractsMap = new Map<String, CollaboratorContract__c>();
        Map<String, Collaborator__c> collabToUp = new Map<String, Collaborator__c>();

        // Construction de la liste en fonction du contexte d'exécution
        if(Trigger.isAfter && Trigger.isDelete) {
            newCollabContracts = (List<CollaboratorContract__c>)Trigger.old;  
        } else {
            newCollabContracts = (List<CollaboratorContract__c>)Trigger.new;  
        }
        
        // Récupération des Ids des collaborateurs
        for(CollaboratorContract__c colCont : newCollabContracts) {
            if(!AlreadyUsed.isUsed('TR022_CollaboratorContract', colCont.id) && String.isNotBlank(colCont.collaborator__c)) {
                collabIds.add(colCont.collaborator__c);
            }
        }

        // SOQL - Récupération des contrats pour chaque collaborateurs
        if(!collabIds.isEmpty()) {
            String contractRTId = DAL.getRecordTypeIdByDevName('CollaboratorContract__c', Constants.COLLABORATORCONTRACT_RT_CONTRACT);
            for(CollaboratorContract__c contract : [SELECT Id, job__c, employedBy__c, assignedTo__c, startDate__c, endDate__c, collaborator__c, 
                                                        isActive__c, stageName__c, signatureDate__c FROM CollaboratorContract__c
                                                    WHERE collaborator__c IN :collabIds AND RecordTypeId = :contractRTId ORDER BY signatureDate__c ASC]) 
            {
                String collabId = contract.collaborator__c;
                // Actif
                if(contract.isActive__c) {
                    activeCollaboratorContractsMap.put(collabId, contract);
                }
                // Passé - Si aucun contrat actif, alors recherché le dernier contrat passé (celui dont la date de fin est plus petit que la date du jour 
                // trié par ordre décroissant de date de fin puis par ordre décroissant de date de signature)
                if(pastcollaboratorContractsMap.get(collabId) == null && contract.endDate__c < Date.Today() && contract.isActive__c == false) {
                    pastcollaboratorContractsMap.put(collabId, contract);
                } else if(pastcollaboratorContractsMap.get(collabId) != null 
                        && contract.endDate__c < Date.Today() && contract.isActive__c == false
                        && pastcollaboratorContractsMap.get(collabId).endDate__c <= contract.endDate__c) 
                {
                    pastcollaboratorContractsMap.put(collabId, contract);
                } 
                // Futur - si aucun contrat trouvé en phases 1 et 2, alors prendre le 1er contrat dans le futur (ceux dont la date de début est supérieur  à la date du jour 
                // trié par ordre croissant de date de début puis par ordre croissant de date de signature)
                if(futurcollaboratorContractsMap.get(collabId) == null && contract.startDate__c > Date.Today() && contract.isActive__c == false) {
                    futurcollaboratorContractsMap.put(collabId, contract);
                } else if(futurcollaboratorContractsMap.get(collabId) != null 
                        && contract.startDate__c > Date.Today() && contract.isActive__c == false
                        && futurcollaboratorContractsMap.get(collabId).startDate__c > contract.startDate__c) 
                {
                    futurcollaboratorContractsMap.put(collabId, contract);
                } 
            }
        }
        System.debug('## activeCollaboratorContractsMap: ' + activeCollaboratorContractsMap);
        System.debug('## pastcollaboratorContractsMap: ' + pastcollaboratorContractsMap);
        System.debug('## futurcollaboratorContractsMap: ' + futurcollaboratorContractsMap);
        
        // Pour chaque contrat, on modifie le collaborateur
        for(CollaboratorContract__c colCont : newCollabContracts) {
            System.debug('## Contrat: ' + colCont.Id);
            System.debug('## Collaborateur: ' + colCont.collaborator__c);
            
            // Récupération des contrats
            CollaboratorContract__c lastContract = pastcollaboratorContractsMap.get(colCont.collaborator__c);
            CollaboratorContract__c lastActiveContract = activeCollaboratorContractsMap.get(colCont.collaborator__c);
            CollaboratorContract__c futurContract = futurcollaboratorContractsMap.get(colCont.collaborator__c);
            // Modification par rapport au dernier contrat actif
            if(lastActiveContract != null) {
                System.debug('## Dernier contrat actif: ' + lastActiveContract.Id);
				collabToUp.put(colCont.collaborator__c, updateCollabObject(colCont.collaborator__c, lastActiveContract));
            } else {
                // Modification du collab - passé
                if(lastContract != null) {
                    System.debug('## Dernier contrat passé: ' + lastContract.Id);
                    collabToUp.put(colCont.collaborator__c, updateCollabObject(colCont.collaborator__c, lastContract));
                // Modification du collab - futur
                } else if(futurContract != null) {
                    System.debug('## Dernier contrat futur: ' + futurContract.Id);
                    collabToUp.put(colCont.collaborator__c, updateCollabObject(colCont.collaborator__c, futurContract));
                }
            }
        }
        System.debug('## collabToUp: ' + collabToUp);
        
        // Mise à jour des enregistrements
        if(!collabToUp.isEmpty()) {
            Database.update(collabToUp.values(), true);
        }        
        System.debug('### FIN TR022_CollaboratorContract.updateCollaboratorsRecords');
    }

    /**
    * @description Méthode pour mettre à jour l'objet Collaborator selon le contrat
    * @param collabId Id du collaborateur
    * @param contract Objet contenant les informations du contrat
    * @return Collaborator__c Objet collaborateur mis à jour
    */
    private static Collaborator__c updateCollabObject(String collabId, CollaboratorContract__c contract) {
		System.debug('## Début: ' + contract.startDate__c);
		System.debug('## Fin: ' + contract.endDate__c);
        return new Collaborator__c(Id=collabId, 
                                    job__c = contract.job__c, 
                                    employedBy__c = contract.employedBy__c,
                                    assignedTo__c = contract.assignedTo__c,
                                    startDate__c = contract.startDate__c,
                                    endDate__c = contract.endDate__c,
                                    stageName__c = contract.stageName__c
								);
    }
}