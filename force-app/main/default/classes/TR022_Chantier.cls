//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_Chantier
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 23/03/2021
//-- Version     : 1.2
//-- * 1.2 - Ajout alimentation ReminderDateTime et IsReminderSet si le créateur est TA
//-- * 1.1 - Mise à jour des localisations
//-- --------------------------------------------------------------------------------- --
public with sharing class TR022_Chantier {

    /**
    * @description Mise à jour de la localisation des contrat si le chantier est modifié
    * @param userContext Information de l'utilisateur courant
    */
    public static void updateLocalisations(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        if (Trigger.isUpdate) {
            List<Chantier__c> newChantiers = (List<Chantier__c>)Trigger.new;
            Map<Id, Chantier__c> oldChantiers = (Map<Id, Chantier__c>)Trigger.oldMap;
            Map<Id, Chantier__c> updatedChantiers = new Map<Id, Chantier__c>();

            for (Chantier__c newChantier : newChantiers) {
                Chantier__c oldChantier = oldChantiers.get(newChantier.id);

                if ((newChantier.localisation__longitude__s != oldChantier.localisation__longitude__s || newChantier.localisation__latitude__s != oldChantier.localisation__latitude__s) &&
                        ((newChantier.nbTotalContrats__c != null && newChantier.nbTotalContrats__c > 0) || (newChantier.nbTotalDevis__c != null && newChantier.nbTotalDevis__c > 0)) &&
                        (!AlreadyUsed.isUsed('TR022_Chantier', newChantier.id)))
                    updatedChantiers.put(newChantier.id, newChantier);
            }

            List<KContrat__c> updatedContrats = new List<KContrat__c>();
            List<Quote>       updatedQuotes   = new List<Quote>();
            if (!updatedChantiers.isEmpty()) {
                for (KContrat__c contrat : [SELECT id, chantier__c, localisation__longitude__s, localisation__latitude__s FROM KContrat__c WHERE chantier__c IN :updatedChantiers.keySet()]) {
                    Chantier__c chantier = updatedChantiers.get(contrat.chantier__c);
                    if (chantier != null) {
                        contrat.localisation__longitude__s = chantier.localisation__longitude__s;
                        contrat.localisation__latitude__s  = chantier.localisation__latitude__s;
                        updatedContrats.add(contrat);
                    }
                }

                if (!updatedContrats.isEmpty())
                    update updatedContrats;
            }
        }
    }
    
    /**
    * @description Mise à jour des indicateurs sur le compte
    * @param userContext Information de l'utilisateur courant
    */
    public static void updateAccountStatus(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
        try{
            Utils_CalculateStatus.refreshAccountStatusFromChantier(Trigger.new);        
        } catch(exception e) {
            system.debug('ERREUR : '+e.getMessage()+' '+e.getTypeName()+' '+e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @description Vérification de l'adresse des comptes et alimentation par rapport au chantier s'ils sont vide
    * @param userContext Information de l'utilisateur courant
    */
    public static void updateAccountAddress(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
        System.debug('### DEBUT TR022_Chantier : updateAccountAddress');

        List<Chantier__c> newChantiers = new List<Chantier__c>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Account> accountsMap = new Map<Id, Account>();
        List<Account> accountsToUpdate = new List<Account>();

        for (Chantier__c newChantier : (List<Chantier__c>)Trigger.new) {
            if (!AlreadyUsed.isUsed('TR022_Chantier.updateAccountAddress', newChantier.id)) {
                // Récupération des Ids des comptes si chantier à une adresse
                if (String.isNotBlank(newChantier.rue__c) && String.isNotBlank(newChantier.codePostal__c) && String.isNotBlank(newChantier.ville__c)
                    && (String.isNotBlank(newChantier.proprietaire__c) || String.isNotBlank(newChantier.autreProprietaire__c)
                    || String.isNotBlank(newChantier.locataire__c) || String.isNotBlank(newChantier.autrelocataire__c)
                    || String.isNotBlank(newChantier.occupant__c) || String.isNotBlank(newChantier.autreOccupant__c))
                ) {
                    if(String.isNotBlank(newChantier.proprietaire__c)) 
                        accountIds.add(newChantier.proprietaire__c);
                    if(String.isNotBlank(newChantier.autreProprietaire__c)) 
                        accountIds.add(newChantier.autreProprietaire__c);
                    if(String.isNotBlank(newChantier.locataire__c)) 
                        accountIds.add(newChantier.locataire__c);
                    if(String.isNotBlank(newChantier.autrelocataire__c)) 
                        accountIds.add(newChantier.autrelocataire__c);
                    if(String.isNotBlank(newChantier.occupant__c)) 
                        accountIds.add(newChantier.occupant__c);
                    if(String.isNotBlank(newChantier.autreOccupant__c)) 
                        accountIds.add(newChantier.autreOccupant__c);
                    newChantiers.add(newChantier);
                }
            }
        }

        // Recherche des comptes
        if (!accountIds.isEmpty()) {
            accountsMap = new Map<Id, Account>([SELECT Id, rue__c, codePostal__c, ville__c, IsPersonAccount FROM Account WHERE Id IN : accountIds]);
        }
        
        // Pour chaque compte, on vérifie l'adresse et met à jour sinon 
        for (Chantier__c newChantier : newChantiers) {
            System.debug('## Vérification adresse - chantier: '+newChantier.Id);
            // Check adresse des comptes
            if(String.isNotBlank(newChantier.proprietaire__c) && checkAddressIsNotSet(accountsMap.get(newChantier.proprietaire__c))) {
                accountsToUpdate.add(updateAddress(accountsMap.get(newChantier.proprietaire__c), newChantier));
                System.debug('## MAJ adresse - compte: '+newChantier.proprietaire__c);
            }
            if(String.isNotBlank(newChantier.autreProprietaire__c) && checkAddressIsNotSet(accountsMap.get(newChantier.autreProprietaire__c))) {
                accountsToUpdate.add(updateAddress(accountsMap.get(newChantier.autreProprietaire__c), newChantier));
                System.debug('## MAJ adresse - compte: '+newChantier.autreProprietaire__c);
            }
            if(String.isNotBlank(newChantier.locataire__c) && checkAddressIsNotSet(accountsMap.get(newChantier.locataire__c))) {
                accountsToUpdate.add(updateAddress(accountsMap.get(newChantier.locataire__c), newChantier));
                System.debug('## MAJ adresse - compte: '+newChantier.locataire__c);
            }
            if(String.isNotBlank(newChantier.autrelocataire__c) && checkAddressIsNotSet(accountsMap.get(newChantier.autrelocataire__c))) {
                accountsToUpdate.add(updateAddress(accountsMap.get(newChantier.autrelocataire__c), newChantier));
                System.debug('## MAJ adresse - compte: '+newChantier.autrelocataire__c);
            }
            if(String.isNotBlank(newChantier.occupant__c) && checkAddressIsNotSet(accountsMap.get(newChantier.occupant__c))) {
                accountsToUpdate.add(updateAddress(accountsMap.get(newChantier.occupant__c), newChantier));
                System.debug('## MAJ adresse - compte: '+newChantier.occupant__c);
            }
            if(String.isNotBlank(newChantier.autreOccupant__c) && checkAddressIsNotSet(accountsMap.get(newChantier.autreOccupant__c))) {
                accountsToUpdate.add(updateAddress(accountsMap.get(newChantier.autreOccupant__c), newChantier));
                System.debug('## MAJ adresse - compte: '+newChantier.autreOccupant__c);
            }
        }

        // MAJ des comptes        
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
        System.debug('### FIN TR022_Chantier : updateAccountAddress');
    }

    /**
    * @description Vérification de l'adresse du compte et retourne true si vide
    * @param acc Compte à vérifier
    * @return True si adresse vide sinon false
    */
    private static Boolean checkAddressIsNotSet(Account acc) {
        Boolean result = false;
        if(acc != null && String.isBlank(acc.rue__c) && String.isBlank(acc.codePostal__c) && String.isBlank(acc.ville__c)) {
            result = true;
        }
        return result;
    }

    /**
    * @description Mise à jour de l'adresse du compte
    * @param acc Compte à mettre à jour
    * @param chantier Chantier disposant de l'adresse
    * @return Objet Account avec adresse mise à jour
    */
    private static Account updateAddress(Account acc, Chantier__c chantier) {
        if(acc.IsPersonAccount) {
            acc.personMailingStreet = chantier.rue__c;
            acc.personMailingPostalCode = chantier.codePostal__c;
            acc.personMailingState = chantier.departement__c;
            acc.personMailingCity = chantier.ville__c;
            acc.personMailingCountry = chantier.pays__c;
            acc.personSalesEntity__pc = chantier.salesEntity__c;
            acc.personServiceEntity__pc = chantier.serviceEntity__c;
        } else {
            acc.billingStreet = chantier.rue__c;
            acc.billingPostalCode = chantier.codePostal__c;
            acc.billingState = chantier.departement__c;
            acc.billingCity = chantier.ville__c;
            acc.billingCountry = chantier.pays__c;
            acc.billingSalesEntity__c = chantier.salesEntity__c;
            acc.billingServiceEntity__c = chantier.serviceEntity__c;
        }
        acc.etage__c = chantier.etage__c;
        acc.complementAdresse__c = chantier.complementAdresse__c;
        acc.localisation__latitude__s = chantier.localisation__latitude__s;
        acc.localisation__longitude__s = chantier.localisation__longitude__s;
        acc.iris__c = chantier.iris__c;
        acc.sectorisation__c = chantier.sectorisation__c;
        return acc;
    }
    
    /**
    * @description Mise à jour de l'actif
    */
    public static void updateAsset(){
        if (Trigger.isUpdate) {
            List<Chantier__c> newChantiers = (List<Chantier__c>)Trigger.new;
            Map<Id, Chantier__c> oldChantiers = (Map<Id, Chantier__c>)Trigger.oldMap;
            List<Asset> updatedAssets = new List<Asset>();
            List<String> idChantiers = new List<String>();
            
            for(Chantier__c newChantier : newChantiers){
                if(newChantier.proprietaire__c != oldChantiers.get(newChantier.id).proprietaire__c){
                    idChantiers.add(newChantier.id);
                }
            }
            
            if(!idChantiers.isEmpty()){
                List<Asset> assetList = [SELECT AccountId, Account.PersonContactId, ContactId ,chantier__r.proprietaire__r.contactParDefaut__c , chantier__r.proprietaire__c 
                                        FROM Asset WHERE chantier__c IN :idChantiers];
            
                for(Asset asset : assetList){
                    asset.AccountID = asset.chantier__r.proprietaire__c;
                    if((asset.Account.PersonContactId == null) && (asset.chantier__r.proprietaire__r.contactParDefaut__c == null)){
                        asset.ContactId=null;
                    }
                    else if((asset.Account.PersonContactId == null) && (asset.chantier__r.proprietaire__r.contactParDefaut__c!=null)){
                        asset.ContactId = asset.chantier__r.proprietaire__r.contactParDefaut__c;
                    }
                    else{
                        asset.ContactId = asset.Account.PersonContactId;
                    }
                    updatedAssets.add(asset);
                }
                
                if(!updatedAssets.isEmpty())
                    update updatedAssets;
            }
            
        }
        
    }
}