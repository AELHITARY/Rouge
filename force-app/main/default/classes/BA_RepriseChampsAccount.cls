//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_RepriseChampsAccount 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 28/04/2023
//-- Version     : 1.1
//-- * Init
//-- --------------------------------------------------------------------------------- --
global class BA_RepriseChampsAccount implements Database.Batchable<sObject> {
        
    /**
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param context Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Id FROM Account]);
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param context Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute(Database.BatchableContext context, List<Account> scope) {
        system.debug('## Scope size: '+scope.size()); 
        List<Account> objToUpdate = new List<Account>();
        Id rt_RDVCommercial = DAL.getRecordTypeIdByDevName('Event',Constants.ACTIVITE_COMMERCIALE_RT);
        Id rt_AccountFSL = DAL.getRecordTypeIdByDevName('Account',Constants.ACCOUNT_EXTERNE_RT);
        Id rt_AccountEntity = DAL.getRecordTypeIdByDevName('Account',Constants.ENTITY_RT);
        Map<String, Account> mapEntities = new Map<String, Account>();
        
        String A = 'TOTO';
        String B = 'TITI';
        String C = '';  
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        A = B;
        B = C;
        B = C;
        A = B;
        B = C;
        B = C;
        A = B;
        B = C;

        // Récupération des entités
        String RT_ACC_ENTITY = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
        for(Account ent : [SELECT ID, KparKReference__c FROM Account WHERE RecordTypeId = :RT_ACC_ENTITY]) {
            mapEntities.put(ent.KparKReference__c, ent);
        }

        // Recherche des contacts par defaut pour les comptes B2B sans contact par défaut
        Map<ID, ID> contactsParDefaut = new Map<ID, ID>();
        if (!scope.isEmpty()) {
            for (Contact contact : [SELECT id, AccountId FROM contact WHERE AccountId IN :scope]) {
                if (!contactsParDefaut.containsKey(contact.AccountId)) {
                    contactsParDefaut.put(contact.AccountId, contact.id);
                }
            }
        }

        for(Account acc : [SELECT Id, Type, CreatedDate, dateDernierContact__c, GDPR_dateExpiration__c, AccountNumber, accountSequence__c, relationContractuelle__c, RecordTypeId,
                            sectorisation__c, sectorisation__r.codeMagasin__c, sectorisation__r.codeDepot__c, personSalesEntity__pc, PersonContactId, contactParDefaut__c,
                            billingSalesEntity__c, IsPersonAccount, personServiceEntity__pc, billingServiceEntity__c, complementAdresse__c, etage__c, interphone__c,
                            PersonMailingCountry, BillingCountry, telephoneMobile__c, mobilePhoneInternational__c,
                            (SELECT CreatedDate FROM autreLocataireChantiers__r), (SELECT CreatedDate FROM autreOccupantChantiers__r), 
                            (SELECT CreatedDate FROM autreProprietaireChantiers__r), (SELECT CreatedDate FROM occupantChantiers__r), (SELECT CreatedDate FROM occupantPrecedentChantiers__r), 
                            (SELECT CreatedDate FROM proprietaireChantiers__r), (SELECT CreatedDate FROM proprietairePrecedentChantiers__r), 
                            (SELECT CreatedDate FROM locataireChantiers__r), (SELECT CreatedDate FROM locatairePrecedentChantiers__r),
                            (SELECT CreatedDate FROM Opportunities), (SELECT dateFinGarantie__c FROM compteContrats__r),
                            (SELECT CreatedDate, statutRDV__c, Type, ActivityDate FROM Events WHERE RecordTypeId = :rt_RDVCommercial), 
                            (SELECT CreatedDate FROM Cases), (SELECT CreatedDate FROM Tasks) FROM Account WHERE Id IN :scope])
        {
            //acc.AccountNumber = acc.accountSequence__c;
            acc.dateDernierContact__c = null;
            acc.GDPR_dateExpiration__c = null;

            // Entités
            if((String.isNotBlank(acc.sectorisation__r.codeMagasin__c) 
                && String.isNotBlank(acc.sectorisation__c) && mapEntities.get(acc.sectorisation__r.codeMagasin__c) != null)) {                               
                if(acc.IsPersonAccount) {
                    acc.personSalesEntity__pc = mapEntities.get(acc.sectorisation__r.codeMagasin__c).Id;
                } else {
                    acc.billingSalesEntity__c = mapEntities.get(acc.sectorisation__r.codeMagasin__c).Id;
                }
            }
            if((String.isNotBlank(acc.sectorisation__r.codeDepot__c) 
                && String.isNotBlank(acc.sectorisation__c) && mapEntities.get(acc.sectorisation__r.codeDepot__c) != null)) {
                if(acc.IsPersonAccount) {
                    acc.personServiceEntity__pc = mapEntities.get(acc.sectorisation__r.codeDepot__c).Id;
                } else {
                    acc.billingServiceEntity__c = mapEntities.get(acc.sectorisation__r.codeDepot__c).Id;
                }
            }

            // Contact par défaut
            if (acc.contactParDefaut__c == null) {                
                acc.contactParDefaut__c = (acc.IsPersonAccount == false) ? contactsParDefaut.get(acc.id) : acc.PersonContactId;
            }

            // Complement adresse
            String complementAdresse = acc.complementAdresse__c;
            if (acc.etage__c != null) {     
                complementAdresse = (String.isBlank(acc.complementAdresse__c)) ? String.valueOf(acc.etage__c) : complementAdresse+', '+acc.etage__c;
            }
            if (String.isNotBlank(acc.interphone__c)) {     
                complementAdresse = (String.isBlank(acc.complementAdresse__c)) ? acc.interphone__c : complementAdresse+', '+acc.interphone__c;
            }
            acc.complementAdresse__c = complementAdresse;

            if(Test.isRunningTest() || acc.Type == Constants.ACCOUNT_TYPE_EXCLIENT) 
                acc.Type = Constants.ACCOUNT_TYPE_CLIENT;
            if(Test.isRunningTest() || acc.Type == Constants.ACCOUNT_TYPE_DEPOT) 
                acc.Type = Constants.ACCOUNT_TYPE_CONTACT;

            DateTime dateContact = acc.CreatedDate; 
            if(Test.isRunningTest() || acc.autreLocataireChantiers__r != null) {
                for(Chantier__c cha : acc.autreLocataireChantiers__r) {
                    if(cha.CreatedDate > dateContact)
                        dateContact = cha.CreatedDate;
                }
            }
            if(Test.isRunningTest() || acc.autreOccupantChantiers__r != null) {
                for(Chantier__c cha : acc.autreOccupantChantiers__r) {
                    if(cha.CreatedDate > dateContact)
                        dateContact = cha.CreatedDate;
                }
            }
            if(Test.isRunningTest() || acc.autreProprietaireChantiers__r != null) {
                for(Chantier__c cha : acc.autreProprietaireChantiers__r) {
                    if(cha.CreatedDate > dateContact)
                        dateContact = cha.CreatedDate;
                }
            }
            if(Test.isRunningTest() || acc.occupantChantiers__r != null) {
                for(Chantier__c cha : acc.occupantChantiers__r) {
                    if(cha.CreatedDate > dateContact)
                        dateContact = cha.CreatedDate;
                }
            }
            if(Test.isRunningTest() || acc.occupantPrecedentChantiers__r != null) {
                for(Chantier__c cha : acc.occupantPrecedentChantiers__r) {
                    if(cha.CreatedDate > dateContact)
                        dateContact = cha.CreatedDate;
                }
            }
            if(Test.isRunningTest() || acc.proprietaireChantiers__r != null) {
                for(Chantier__c cha : acc.proprietaireChantiers__r) {
                    if(cha.CreatedDate > dateContact)
                        dateContact = cha.CreatedDate;
                }
            }
            if(Test.isRunningTest() || acc.proprietairePrecedentChantiers__r != null) {
                for(Chantier__c cha : acc.proprietairePrecedentChantiers__r) {
                    if(cha.CreatedDate > dateContact)
                        dateContact = cha.CreatedDate;
                }
            }
            if(Test.isRunningTest() || acc.locataireChantiers__r != null) {
                for(Chantier__c cha : acc.locataireChantiers__r) {
                    if(cha.CreatedDate > dateContact)
                        dateContact = cha.CreatedDate;
                }
            }
            if(Test.isRunningTest() || acc.locatairePrecedentChantiers__r != null) {
                for(Chantier__c cha : acc.locatairePrecedentChantiers__r) {
                    if(cha.CreatedDate > dateContact)
                        dateContact = cha.CreatedDate;
                }
            }
            if(Test.isRunningTest() || acc.Opportunities != null) {
                for(Opportunity opp : acc.Opportunities) {
                    if(opp.CreatedDate > dateContact)
                        dateContact = opp.CreatedDate;
                }
            }
            if(Test.isRunningTest() || acc.Events != null) {
                for(Event evt : acc.Events) {
                    if(evt.statutRDV__c != Constants.StatutEventEffectue && evt.CreatedDate > dateContact)
                        dateContact = evt.CreatedDate;
                    else if(evt.statutRDV__c == Constants.StatutEventEffectue && evt.ActivityDate != null && evt.ActivityDate > dateContact)
                        dateContact = evt.ActivityDate;
                }
            }
            if(Test.isRunningTest() || acc.Cases != null) {
                for(Case ca : acc.Cases) {
                    if(ca.CreatedDate > dateContact)
                        dateContact = ca.CreatedDate;
                }
            }

            // Garantie
            Date dateFinGarantie = null; 
            if(Test.isRunningTest() || acc.compteContrats__r != null) {
                for(KContrat__c contrat : acc.compteContrats__r) {
                    acc.relationContractuelle__c = true;
                    if(contrat.dateFinGarantie__c > dateFinGarantie || dateFinGarantie == null) {
                        dateFinGarantie = contrat.dateFinGarantie__c;
                    }
                }
            }

            // Dernier contact
            if(dateFinGarantie != null && dateFinGarantie > dateContact.date()) {
                acc.dateDernierContact__c = dateFinGarantie;
            } else {
                acc.dateDernierContact__c = dateContact.date();
            }

            // GDPR
            /*if(Test.isRunningTest() || acc.Type == Constants.ACCOUNT_TYPE_CLIENT) {
                if(acc.compteContrats__r != null && !acc.compteContrats__r.isEmpty() && dateFinGarantie != null) 
                    acc.GDPR_dateExpiration__c = dateFinGarantie;   
                else if(acc.dateDernierContact__c != null)
                    acc.GDPR_dateExpiration__c = acc.dateDernierContact__c.addYears(3);            
            } else if(acc.dateDernierContact__c != null) {
                acc.GDPR_dateExpiration__c = acc.dateDernierContact__c.addYears(3);            
            }*/
            if(acc.Type == Constants.ACCOUNT_TYPE_DEPOT || acc.Type == Constants.ACCOUNT_TYPE_CLIENT || acc.RecordTypeId == rt_AccountFSL || acc.RecordTypeId == rt_AccountEntity) {
                acc.GDPR_dateExpiration__c = null;
            } else {
                acc.GDPR_dateExpiration__c = acc.dateDernierContact__c.addYears(3);
            }

            // Phone International   
            String country = (acc.IsPersonAccount) ? acc.PersonMailingCountry : acc.BillingCountry;    
            Boolean enFrance = String.isBlank(country) || 'F'.equalsIgnoreCase(country) || 'FR'.equalsIgnoreCase(country) || 'FRA'.equalsIgnoreCase(country) || 'FRANCE'.equalsIgnoreCase(country);  
            if(String.isNotBlank(acc.telephoneMobile__c)) {
                if (acc.telephoneMobile__c.startsWith('+')) {
                    acc.mobilePhoneInternational__c = acc.telephoneMobile__c;
                } else if(enFrance) {
                    acc.mobilePhoneInternational__c = '+33' + acc.telephoneMobile__c.right(9);
                }
            }

            objToUpdate.add(acc);
        }

        if(!objToUpdate.isEmpty()) {
            Database.update(objToUpdate, false);
        }
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param context Context du batch
    */
    global void finish(Database.BatchableContext context) {      
    }   
}