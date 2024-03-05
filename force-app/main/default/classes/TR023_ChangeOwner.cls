//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR023_ChangeOwner
//-- Modifié par : KPK - Franck GOURDEAUX
//-- Modifié le  : 13/10/2017
//-- Version     : 1.13
//-- * CRM-769 : Réaffectation owner
//-- * Espace client / Exception lors de la génération du mot de passe
//-- --------------------------------------------------------------------------------- --
/* ************************************************************************* *
 * Compte/Chantier/Projet : Règles d'attribution et de mise à jour *
 * ************************************************************************* */
public without sharing class TR023_ChangeOwner {
    private static Boolean enabledchangeOwner = PropertiesUtils.getBooleanValue('function.enabled.changeOwner', false);
    private static UserContext context = UserContext.getContext();
    private static final String ENTITY_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    private static final String PROVIDER_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PROVIDER_RT);

    public static void changerOwnerOpportunity(List<Opportunity> opportunities) {
        system.debug('#### START TR023_ChangeOwner.changerOwnerOpportunity');

        List<Opportunity> oppList = new List<Opportunity>();
        Set<ID> accountIds = new Set<ID>();
        Set<Account> accountProjetIds = new Set<Account>();
        Set<ID> chantierIds = new Set<ID>();

        Map<Id, Opportunity> oldOpportunities = (Map<Id, Opportunity>)Trigger.oldMap;
        Map<ID, Chantier__c> eventChantier = new Map<ID, Chantier__c>();
        Map<ID, Set<Account>> eventCompte = new Map<ID, Set<Account>>();
        Map<ID, Account> accountToUpdate = new Map<ID, Account>();
        Set<Chantier__c> chantierToUpdate = new Set<Chantier__c>();        

        // Si l'autorisation de modifier le propriétaire est activé
        if (enabledchangeOwner) {
            for(Opportunity opp : opportunities) {
                if (!AlreadyUsed.isUsed('TR023_ChangeOwner.changerOwnerOpportunity', opp.id)) {
                    oppList.add(opp);
                }
            }
            if (oppList.isEmpty())
                return;
            /***********************************************************/
            /***** Récupération des enregistrement à mettre à jour *****/
            /***********************************************************/
            List<Opportunity> projects = [select id, ownerId, chantier__c, AccountId, autreCompte__c from Opportunity where id in :oppList];
            for (Opportunity project : projects) {
                chantierIds.add(project.chantier__c);
                accountIds.add(project.AccountId);
                accountIds.add(project.autreCompte__c);
            }

            List<Chantier__c> chantiers = [select id, ownerId, proprietaire__c, locataire__c, occupant__c, proprietairePrecedent__c,
                                             locatairePrecedent__c, occupantPrecedent__c, autreLocataire__c, autreOccupant__c, autreProprietaire__c from Chantier__c where id in :chantierIds];
            for (Opportunity project : oppList) {
                for (Chantier__c chantier : chantiers) {
                    if (project.chantier__c == chantier.id) {
                        eventChantier.put(project.Id, chantier);
                        accountIds.add(chantier.proprietaire__c);
                        accountIds.add(chantier.locataire__c);
                        accountIds.add(chantier.occupant__c);
                        accountIds.add(chantier.proprietairePrecedent__c);
                        accountIds.add(chantier.locatairePrecedent__c);
                        accountIds.add(chantier.occupantPrecedent__c);
                        accountIds.add(chantier.autreLocataire__c);
                        accountIds.add(chantier.autreOccupant__c);
                        accountIds.add(chantier.autreProprietaire__c);
                    }
                }
            }

            /************************************************/
            /****************** Modification ****************/
            /************************************************/
            for(Opportunity opp : oppList) {
                Opportunity oldOpportunity = oldOpportunities == null ? null : oldOpportunities.get(opp.id);
                String newOwnerId;                

                // Modification du propriétaire du Projet, Chantiers, Comptes
                /** >>> F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface
                if(!context.isCallUser() && oldOpportunity.ownerid == opp.ownerid){
                /** >>> F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface **/
                if(Trigger.isUpdate){
                    if(context.isSaleUser() && oldOpportunity.ownerid == opp.ownerid){
                        /** >>> F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface **/
                        newOwnerId = context.getUser().Id;
                    }
                    if (context.isCallUser())
                    {
                        newOwnerId = opp.OwnerId;
                    }
                    /** >>> F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface
                    if (!context.isCallUser() && oldOpportunity.ownerid != opp.ownerid)
                        --- F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface **/
                    if (context.isSaleUser() && oldOpportunity.ownerid != opp.ownerid)
                    /** <<< F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface **/
                    {
                        newOwnerId = opp.OwnerId;
                    }
                } else {
                    if (context.isCallUser())
                    {
                        newOwnerId = opp.OwnerId;
                    } else  newOwnerId = context.getUser().Id;
                }

                UserContext user = UserContext.getContext(opp.ownerid);

                //Mise en commentaire car non applicable en After update
                //opp.OwnerId = newOwnerId;
                Chantier__c chantier = eventChantier.get(opp.Id);
                if (chantier != null && (!user.isSaleUser() || (user.isSaleUser() && oldOpportunity.ownerid == opp.ownerid))) {
                    chantier.ownerId = newOwnerId;
                    chantierToUpdate.add(chantier);
                }
            }
        }

        List<Chantier__c> chToUpdateList = new List<Chantier__c>();
        chToUpdateList.addAll(chantierToUpdate);
        if(!chToUpdateList.isEmpty())
            update chToUpdateList;
        system.debug('#### END TR023_ChangeOwner.changerOwnerOpportunity');
    }

    public static void changerOwnerChantier(List<Chantier__c> chantiers) {
        system.debug('#### START TR023_ChangeOwner.changerOwnerChantier');

        List<Chantier__c> chantierList = new List<Chantier__c>();
        Set<ID> accountIds = new Set<ID>();
        Set<Account> accountChantierIds = new Set<Account>();
        Map<ID, Set<Account>> chantierCompteMap = new Map<ID, Set<Account>>();
        Map<Id, Chantier__c> oldChantiers = (Map<Id, Chantier__c>)Trigger.oldMap;

        // Si l'autorisation de modifier le propriétaire est activé
        if (enabledchangeOwner) {
            for(Chantier__c chantier : chantiers) {
                if (!AlreadyUsed.isUsed('TR023_ChangeOwner.changerOwnerChantier', chantier.id)) {
                    chantierList.add(chantier);
                }
            }
            if (chantierList.isEmpty())
                return;
            /***********************************************************/
            /***** Récupération des enregistrement à mettre à jour *****/
            /***********************************************************/
            for (Chantier__c chantier : chantierList) {
                accountIds.add(chantier.proprietaire__c);
                accountIds.add(chantier.locataire__c);
                accountIds.add(chantier.occupant__c);
                accountIds.add(chantier.proprietairePrecedent__c);
                accountIds.add(chantier.locatairePrecedent__c);
                accountIds.add(chantier.occupantPrecedent__c);
                accountIds.add(chantier.autreLocataire__c);
                accountIds.add(chantier.autreOccupant__c);
                accountIds.add(chantier.autreProprietaire__c);
            }

            List<Account> comptes = [select id, ownerId, conjoint__c from Account where id in :accountIds];
            for (Chantier__c chantier : chantierList) {
                accountChantierIds.clear();
                for (Account compte : comptes) {
                    if (chantier.autreLocataire__c == compte.id || chantier.locataire__c == compte.id || chantier.locatairePrecedent__c == compte.id
                        || chantier.proprietaire__c == compte.id || chantier.proprietairePrecedent__c == compte.id || chantier.autreProprietaire__c == compte.id
                        || chantier.occupant__c == compte.id || chantier.occupantPrecedent__c == compte.id || chantier.autreOccupant__c == compte.id) {
                        accountChantierIds.add(compte);
                    }
                }
                chantierCompteMap.put(chantier.Id, accountChantierIds);
            }

            /************************************************/
            /****************** Modification ****************/
            /************************************************/
            Map<ID, Account> accountToUpdate = new Map<ID, Account>();            

            for(Chantier__c chantier : chantierList) {
                Chantier__c oldChantier = oldChantiers == null ? null : oldChantiers.get(chantier.id);
                String newOwnerId;                

                // Modification du proprietaire Chantier
                /** >>> F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface
                if(!context.isCallUser() && oldChantier.ownerid == chantier.ownerid){
                /** >>> F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface **/
                if(Trigger.isUpdate){
                    if(context.isSaleUser() && oldChantier.ownerid == chantier.ownerid){
                    /** >>> F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface **/
                        newOwnerId = context.getUser().Id;
                    }
                    if (context.isCallUser())
                    {
                        newOwnerId = chantier.OwnerId;
                    }
                    /** >>> F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface
                    if (!context.isCallUser() && oldChantier.ownerid != chantier.ownerid)
                        --- F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface **/
                    if (context.isSaleUser() && oldChantier.ownerid != chantier.ownerid)
                    /** <<< F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface **/
                    {
                        newOwnerId = chantier.OwnerId;
                    }
                } else {
                    if (context.isCallUser())
                    {
                        newOwnerId = chantier.OwnerId;
                    } else  newOwnerId = context.getUser().Id;
                }

                if(Trigger.isbefore && chantier.OwnerId != newOwnerId) {
                    chantier.OwnerId = newOwnerId;
                }

                for (Account compte : chantierCompteMap.get(chantier.Id)) {
                    if (newOwnerId != compte.ownerId){
                        compte.ownerId = newOwnerId;                        
                        accountToUpdate.put(compte.id, compte);
                    }
                }
            }

            if(!accountToUpdate.isEmpty())
                update accountToUpdate.values();
        }
        system.debug('#### END TR023_ChangeOwner.changerOwnerChantier');
    }

    public static void changerOwnerAccount(List<Account> accounts) {
        system.debug('#### START TR023_ChangeOwner.changerOwnerAccount');
        List<Account> accountList = new List<Account>();
        Map<Id, Account> oldAccounts = (Map<Id, Account>)Trigger.oldMap;

        // Si l'autorisation de modifier le propriétaire est activé
        if (enabledchangeOwner) {
            for(Account acc : accounts) {                
                if(acc.RecordTypeId != ENTITY_RTID && acc.RecordTypeId != PROVIDER_RTID && !AlreadyUsed.isUsed('TR023_ChangeOwner.changerOwnerAccount', acc.id)) {
                    accountList.add(acc);
                }
            }
            if (accountList.isEmpty())
                return;
            /***********************************************************/
            /***** Récupération des enregistrement à mettre à jour *****/
            /***********************************************************/

            /************************************************/
            /****************** Modification ****************/
            /************************************************/
            List<Account> accountToUpdate = new List<Account>();
            /* >>> F.G., le 13/10/2017 - Pb génération password espace client
            Map<ID, ID> compteConjointMap = new Map<ID, Id>();
               <<< F.G., le 13/10/2017 - Pb génération password espace client */

            for(Account acc : accountList) {
                Account oldaccount = oldAccounts == null ? null : oldAccounts.get(acc.id);
                String newOwnerId;
                /* >>> F.G., le 13/10/2017 - Pb génération password espace client
                // compteConjointMap = new Map<ID, ID>();
                compteConjointMap.clear();
                <<< F.G., le 13/10/2017 - Pb génération password espace client */

                // Modification du proprietaire Comptes
                /** >>> F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface
                if(!context.isCallUser() && oldaccount.ownerid == acc.ownerid){
                /** >>> F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface **/
                if(Trigger.isUpdate){
                    if(context.isSaleUser() && oldaccount.ownerid == acc.ownerid){
                    /** >>> F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface **/
                        newOwnerId = context.getUser().Id;
                    }
                    if (context.isCallUser())
                    {
                        newOwnerId = acc.ownerId;
                    }
                    /** >>> F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface
                    if (!context.isCallUser() && oldaccount.ownerid != acc.ownerid)
                        --- F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface **/
                    if (context.isSaleUser() && oldaccount.ownerid != acc.ownerid)
                    /** <<< F.G., le 03/09/2013 - Problème lors de modification en masse de données par administrateur ou interface **/
                        {
                            newOwnerId = acc.OwnerId;
                        }
                } else {
                    if (context.isCallUser())
                    {
                        newOwnerId = acc.ownerId;
                    } else  newOwnerId = context.getUser().Id;
                }

                if(Trigger.isbefore && acc.OwnerId != newOwnerId) {
                    acc.OwnerId = newOwnerId;
                    /* >>> F.G., le 13/10/2017 - Pb génération password espace client
                    compteConjointMap.put(acc.conjoint__c, newOwnerId);
                    <<< F.G., le 13/10/2017 - Pb génération password espace client */
                }else{
                /* >>> F.G., le 13/10/2017 - Pb génération password espace client
                compteConjointMap.put(acc.conjoint__c, newOwnerId);
                <<< F.G., le 13/10/2017 - Pb génération password espace client */
                }
            }

            // Modification des comptes conjoints
            /* >>> F.G., le 13/10/2017 - Pb génération password espace client
            List<Account> compteConjoint = [select id, ownerId, conjoint__c from Account where id in :compteConjointMap.keySet()];
            for (Account compte : compteConjoint) {
                //if (compteConjointMap.get(compte.Id) != compte.ownerId){
                compte.ownerId = compteConjointMap.get(compte.Id);
                accountToUpdate.add(compte);
                //}
            }
               <<< F.G., le 13/10/2017 - Pb génération password espace client */

            // Mise à jour des objets
            if(!accountToUpdate.isEmpty())
                update accountToUpdate;
        }
        system.debug('#### END TR023_ChangeOwner.changerOwnerAccount');
    }
}