//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Phones
//-- Modifié par : SOPRA STERIA - Julien MORINEAU
//-- Modifié le  : 16/03/2017
//-- Version     : 1.0
//-- * 1.0 : CRM-893 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_Phones {
    private static final RecordType RT_ACTIVITE_COMMERCIALE = [SELECT id FROM RecordType WHERE name = 'FRA- Activité commerciale' LIMIT 1];
    private static final Integer    MAX_NAME_LENGTH         = 80;
    private static final Date       TODAY                   = System.today();
    private static final Integer    DEFAULT_PREVISIONSIGNATURE  = PropertiesUtils.getIntegerValue('ldp.delaiPrevisionSignature',0);

    /**
    * @description Mise à jour d'un phone et de son RDV si le RDV est changé.
    * @param userContext Contexte de l'utilisateur courant
    */
    public static void phoneAvecRDVConfirme(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
            
        List<PhoningVendeur__c> newPhones = (List<PhoningVendeur__c>)Trigger.new;
        Map<Id, PhoningVendeur__c> oldPhones = (Map<Id, PhoningVendeur__c>)Trigger.oldMap;
        List<PhoningVendeur__c> phonesAvecRdvExistant = new List<PhoningVendeur__c>();
        List<PhoningVendeur__c> phonesSansProjet = new List<PhoningVendeur__c>();
        List<PhoningVendeur__c> phonesSansRdv = new List<PhoningVendeur__c>();
        
        List<Chantier__c> chantierListACreer = new List<Chantier__c>();
        List<Opportunity> projetListACreer = new List<Opportunity>();
        List<Event> rdvListACreer = new List<Event>();
        List<PhoningVendeur__c> phonesToUpdate = new List<PhoningVendeur__c>();
        
        Map<Id, Chantier__c> chantierAssociePhone = new Map<Id, Chantier__c>();
        Map<Id, Opportunity> projetAssociePhone = new Map<Id, Opportunity>();
        Map<Id, Event> eventAssociePhone = new Map<Id, Event>();
        
        // Séparation des Phones selon leurs informations
        // 1er  cas : RDV existant, il est mis à jour
        // 2eme cas : Projet existant mais RDV manquant. Création du RDV et mise à jour du phone.
        // 3eme cas : Ni projet, ni RDV. Vérification d'un chantier conforme (sinon il est créé), création du projet/RDV et mise à jour du phone.
        for(PhoningVendeur__c phone : newPhones){
            PhoningVendeur__c oldPhone = oldPhones == null ? null : oldPhones.get(phone.id);
            // Si la date/heure de RDV est renseignée, création automatique d'un projet et d'un RDV
            if((phone.dateHeureRDV__c != null && oldPhone!=null && phone.dateHeureRDV__c != oldPhone.dateHeureRDV__c) ||
               (phone.dureeRDV__c != null && oldPhone!=null && phone.dureeRDV__c != oldPhone.dureeRDV__c)) {
                if(phone.RDV__c != null) 
                    phonesAvecRdvExistant.add(phone);
                else if(phone.projet__c != null) 
                    phonesSansRdv.add(phone);
                else 
                    phonesSansProjet.add(phone);
                system.debug('phone.projet__c : '+phone.projet__c);
                system.debug('phonesAvecRdvExistant : '+phonesAvecRdvExistant);
                system.debug('phonesSansRdv : '+phonesSansRdv);
                system.debug('phonesSansProjet : '+phonesSansProjet);
            }
        }

        try{
            // 1er cas
            if(!phonesAvecRdvExistant.isEmpty()){
                List<Id> eventIdList = new List<Id>();
                List<Event> rdvToUpdate = new List<Event>();
                
                // Mise à jour du RDV
                for(PhoningVendeur__c phone : phonesAvecRdvExistant){
                    eventIdList.add(phone.rdv__c);
                }
                Map<Id, Event> events = new Map<Id, Event>([SELECT Id, StartDateTime, EndDateTime FROM Event WHERE Id IN :eventIdList]);
                for(PhoningVendeur__c phone : phonesAvecRdvExistant){
                    Event rdv = events.get(phone.rdv__c);
                    rdv.StartDateTime = phone.dateHeureRDV__c;
                    rdv.EndDateTime = phone.dateHeureRDV__c.addMinutes(integer.valueOf(phone.dureeRDV__c));
                    rdvToUpdate.add(rdv);
                }
                if(!rdvToUpdate.isEmpty())
                    update rdvToUpdate;
            }
            
            // 2ème cas
            if(!phonesSansRdv.isEmpty()){

                // Récupération des comptes reliés aux Phones concernés
                Set<Id> comptesIdList = new Set<Id>();
                for(PhoningVendeur__c phone : phonesSansRdv){
                    comptesIdList.add(phone.compte__c);
                }
                Map<Id, Account> comptes = comptesAssocie(comptesIdList);
                
                // Création et insertion du RDV
                for(PhoningVendeur__c phone : phonesSansRdv){
                    Event rdv = createRDV(phone, comptes, phone.projet__c);
                    rdvListACreer.add(rdv);
                    eventAssociePhone.put(phone.Id, rdv);
                    phonesToUpdate.add(phone);
                    system.debug('### rdv : ' + rdv); 
                }
                insert rdvListACreer;
                
                // Mise à jour des phones
                for(PhoningVendeur__c phone : phonesToUpdate){
                    phone.RDV__c = (eventAssociePhone.get(phone.Id)).Id;
                }
            }
            
            // 3ème cas 
            if(!phonesSansProjet.isEmpty()){
                
                // Récupération des comptes reliés aux Phones concernés
                Set<Id> comptesIdList = new Set<Id>();
                for(PhoningVendeur__c phone : phonesSansProjet){
                    comptesIdList.add(phone.compte__c);
                }
                Map<Id, Account> comptes = comptesAssocie(comptesIdList);
                
                System.debug('comptesIdList :'+comptesIdList);
                
                // Récupération des chantiers liés aux comptes récupérés                                                    
                Map<Id, Chantier__c> chantiers = new Map<Id, Chantier__c>([SELECT Id, Name, rue__c, codePostal__c, ville__c, departement__c, pays__c, complementAdresse__c, 
                                                                        proprietaire__c, locataire__c
                                                                    FROM Chantier__c WHERE proprietaire__c IN :comptesIdList OR autreProprietaire__c IN :comptesIdList OR proprietairePrecedent__c IN :comptesIdList
                                                                    OR locataire__c IN :comptesIdList OR autreLocataire__c IN :comptesIdList OR locatairePrecedent__c IN :comptesIdList
                                                                    OR occupant__c IN :comptesIdList OR autreOccupant__c IN :comptesIdList OR occupantPrecedent__c IN :comptesIdList]);
                for(PhoningVendeur__c phone : phonesSansProjet){
                    
                    // Si un chantier existe avec une adresse égale, il est sélectionné par défaut
                    Chantier__c chantierExistant = new Chantier__c();
                    for(Id cha : chantiers.keySet()){
                        if(comptes.get(phone.compte__c).rue__c == chantiers.get(cha).rue__c && comptes.get(phone.compte__c).codePostal__c == chantiers.get(cha).codePostal__c
                        && comptes.get(phone.compte__c).ville__c == chantiers.get(cha).ville__c && comptes.get(phone.compte__c).departement__c == chantiers.get(cha).departement__c
                        && comptes.get(phone.compte__c).pays__c == chantiers.get(cha).pays__c && comptes.get(phone.compte__c).complementAdresse__c == chantiers.get(cha).complementAdresse__c)
                            chantierExistant = chantiers.get(cha);
                        system.debug('chantierExistant : '+chantierExistant);
                    }
                    if(chantierExistant.Id != null) chantierAssociePhone.put(phone.Id, chantierExistant);
                    
                    // Sinon, création et insertion du chantier
                    else{
                        Chantier__c chantier = new Chantier__c();
                        chantier.OwnerId = UserInfo.getUserId();
                        chantier.Name    = ('CHA _ ' + TODAY.year() + (TODAY.month() < 10 ? '0' + TODAY.month() : TODAY.month().format())
                                                 + ' _ ' + (comptes.get(phone.compte__c).FirstName  == null ? '' : comptes.get(phone.compte__c).FirstName.toLowerCase())
                                                 + ' '   + (comptes.get(phone.compte__c).LastName    == null ? '' : comptes.get(phone.compte__c).LastName.toUpperCase())
                                                 + ' _ ' + comptes.get(phone.compte__c).ville__c
                                                 + ' _ Propriétaire')
                                        .left(MAX_NAME_LENGTH);
                        chantier.proprietaire__c = phone.compte__c;
                        chantier.rue__c = comptes.get(phone.compte__c).rue__c;
                        chantier.codePostal__c = comptes.get(phone.compte__c).codePostal__c;
                        chantier.ville__c = comptes.get(phone.compte__c).ville__c;
                        chantier.complementAdresse__c = comptes.get(phone.compte__c).complementAdresse__c;
                        chantier.departement__c = comptes.get(phone.compte__c).departement__c;
                        chantier.pays__c = comptes.get(phone.compte__c).pays__c;
                        chantierListACreer.add(chantier);
                        chantierAssociePhone.put(phone.Id, chantier);
                        system.debug('chantier : '+chantier);
                    }
                    system.debug('## création chantierAssociePhone : '+chantierAssociePhone);  
                }
                
                if(!chantierListACreer.isEmpty())
                    insert chantierListACreer;
                
                // Création et insertion du projet
                for(PhoningVendeur__c phone : phonesSansProjet){ 
                    Date datePrevisionSignature = System.today();
                    datePrevisionSignature = datePrevisionSignature.addDays(DEFAULT_PREVISIONSIGNATURE);
                    Opportunity projet = new Opportunity();
                    Boolean locataire = false;
                    
                    if((chantierAssociePhone.get(phone.Id)).locataire__c != null) locataire = true;
                    
                    projet.OwnerId   = UserInfo.getUserId();
                    projet.Name      = ('PRJ _ ' + TODAY.year() + (TODAY.month() < 10 ? '0' + TODAY.month() : TODAY.month().format())
                                             + ' _ ' + (comptes.get(phone.compte__c).FirstName  == null ? '' : comptes.get(phone.compte__c).FirstName.toLowerCase())
                                             + ' '   + (comptes.get(phone.compte__c).LastName    == null ? '' : comptes.get(phone.compte__c).LastName.toUpperCase())
                                             + ' _ ' + comptes.get(phone.compte__c).ville__c
                                             + ' _ ' + (locataire ? 'Locataire' : 'Proprietaire'))
                                   .left(MAX_NAME_LENGTH);
                    projet.Type      = 'Nouveau';
                    projet.premiereSource__c = 'TELEPHONE VENDEUR';
                    projet.LeadSource = 'TELEPHONE VENDEUR';
                    projet.AccountId = comptes.get(phone.compte__c).Id;
                    projet.chantier__c = (chantierAssociePhone.get(phone.Id)).Id;
                    projet.CloseDate = datePrevisionSignature;
                    projet.StageName = 'Analyse';
                    projetListACreer.add(projet);
                    projetAssociePhone.put(phone.Id, projet);
                    system.debug('## création projet : ' + projet);
                }
                insert projetListACreer;
                
                // Creation et insertion du RDV
                for(PhoningVendeur__c phone : phonesSansProjet){    
                    Event rdv = createRDV(phone, comptes, projetAssociePhone.get(phone.Id).Id);
                    rdvListACreer.add(rdv);
                    eventAssociePhone.put(phone.Id, rdv);
                    phonesToUpdate.add(phone);
                    system.debug('## création rdv : ' + rdv); 
                    
                }
                insert rdvListACreer;
                
                // Mise à jour des phones
                for(PhoningVendeur__c phone : phonesToUpdate){
                    phone.projet__c = (projetAssociePhone.get(phone.Id)).Id;
                    phone.RDV__c = (eventAssociePhone.get(phone.Id)).Id;
                }
            }
        } catch(exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    } 
    
    /**
    * @description Mise à jour d'un phone si son projet est supprimé.
    * @param opportunityList Liste des projets supprimés
    */
    public static void supprimerOpportunity(List<Opportunity> opportunityList) {
        List<String> oppId = new List<String>();
        List<Event> eventList = new List<Event>();
        
        try {
            for(Opportunity opp : opportunityList){
                oppId.add(opp.Id);
            }
            eventList = [SELECT Id FROM Event WHERE WhatId IN :oppId];
            supprimerEventLink(eventList);
            
        } catch(exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description Mise à jour d'un phone si son RDV est supprimé.
    * @param events Liste des RDV supprimés
    */
    public static void supprimerEventLink(List<Event> events) {
        List<String> eventsId = new List<String>();
        List<PhoningVendeur__c> phoneList = new List<PhoningVendeur__c>();
        try {
            for(Event ev : events){
                eventsId.add(ev.Id);
            }
            system.debug(eventsId);
            phoneList = [SELECT Id, RDV__c FROM PhoningVendeur__c WHERE RDV__c IN :eventsId];
            for(PhoningVendeur__c phone : phoneList){
                phone.RDV__c = null;
            }
            if(!phoneList.isEmpty())
                update phoneList;
                
        } catch(exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
    * @description Fonction de récupération des comptes associés à une liste de phones
    * @param comptesIdList Id des comptes
    * @return Map<Id, Account> Liste des comptes par liste de phone
    */
    public static Map<Id, Account> comptesAssocie(Set<Id> comptesIdList){
        Map<Id, Account> comptes = new Map<Id, Account>([SELECT Id, FirstName, LastName, IsPersonAccount, typeFichierSource__c, rue__c, codePostal__c, ville__c, 
                                                                complementAdresse__c, departement__c, pays__c, contactParDefaut__c, PersonContactId
                                                            FROM Account WHERE Id IN :comptesIdList]);
        return comptes;
    }
    
    /**
    * @description Fonction générique de création d'évènement à attacher pour un phone
    * @param phone Phoning utilisé pour le RDV
    * @param comptes Map des comptes des phoning
    * @param projetId Id du projet pour lier le RDV
    * @return Event Objet du RDV
    */
    public static Event createRDV(PhoningVendeur__c phone, Map<Id, Account> comptes, String projetId){
        system.debug('phone.projet__c : '+projetId);
        Event rdv = new Event(
            OwnerId             = UserInfo.getUserId(), 
            RecordTypeId        = RT_ACTIVITE_COMMERCIALE.id, 
            Type                = 'R1',
            WhoId               = ((comptes.get(phone.compte__c).IsPersonAccount) ? comptes.get(phone.compte__c).PersonContactId : comptes.get(phone.compte__c).contactParDefaut__c),
            WhatId              = projetId,
            StartDateTime       = phone.dateHeureRDV__c,
            EndDateTime         = phone.dateHeureRDV__c.addMinutes(integer.valueOf(phone.dureeRDV__c)),
            couplepresent__c    = Constants.EventCoupleAConfirmer,
            Subject             = 'Activité Commerciale'
        );
        return rdv;
    }
}