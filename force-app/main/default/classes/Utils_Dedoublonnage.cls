//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_Dedoublonnage
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 18/01/2018
//-- Version     : 1.1
//-- * 1.0 : Initialisation
//-- * 1.1 : RQM-29 - Matrice de dédoublonnage
//-- --------------------------------------------------------------------------------- --
public without sharing class Utils_Dedoublonnage {

    /**
    * @description Fonction de fusion manuel de l'objet Account 
    * @param accMerged Objet contenant les valeurs saisies par l'utilisateur
    * @param newAccount Compte modifié
    * @param doublonId Id du compte en doublon
    * @param masterId Id du compte maitre sélectionné
    * @return String Id du compte maitre
    */
    public static String manualMergeAccount(Map<String,String> accMerged, String newAccount, String doublonId, String masterId, String personAccount, List<String> fieldlist) {
        system.debug('### DEBUT manualMergeAccount');
        system.debug('## accMerged : ' + accMerged);
        system.debug('## newAccount :' + newAccount);
        system.debug('## doublonId : ' + doublonId);
        system.debug('## masterId : ' + masterId);

        Account doublon = new Account();
        Account compteMaitre = new Account();
        Account compteSecondaire = new Account();
        Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();      
        Map<String, Account> valuesAccount = new Map<String, Account>();

        try {
            Account newAccountToMerge = (Account)JSON.deserialize(newAccount, Account.class);
            // Création requête SOQL pour récupération des champs
            String soqlQuery =  'SELECT ';
            for(String field : fieldsMap.keySet()){
                if (field != 'Name' && isMergeableField(field, fieldsMap)) { 
                    soqlQuery += fieldsMap.get(field) + ', ';
                }
            }
            if(personAccount=='false') soqlQuery += 'Name, ';
            soqlQuery = soqlQuery.substring(0, soqlQuery.length()-2);
            soqlQuery += ' FROM Account WHERE Id = ';
            system.debug('## SOQL Query : '+soqlQuery);
            // Récupération des informations des 2 comptes à fusionner
            if(String.isNotBlank(newAccountToMerge.Id))
                newAccountToMerge = Database.query(soqlQuery+'\''+newAccountToMerge.Id+'\'');
            if(String.isNotBlank(doublonId))
                doublon = Database.query(soqlQuery+'\''+doublonId+'\'');

            // Sélection du compte principal    
            compteMaitre = (masterId == newAccountToMerge.Id) ? newAccountToMerge : doublon;
            compteSecondaire = (masterId == newAccountToMerge.Id) ? doublon : newAccountToMerge;

            // Copie des valeurs (par type de champ)
            copyUserValueInFields(compteMaitre, accMerged, fieldlist, fieldsMap);
            
            // Mise à jour car second compte inexistant
            if(String.isBlank(compteSecondaire.Id)) {
                system.debug('## Compte esclave inexistant - Mise à jour compte maitre');
                upsert compteMaitre;
                compteMaitre = [SELECT Id, AccountNumber FROM Account WHERE Id = :compteMaitre.Id]; 
                valuesAccount.put(compteMaitre.Id, compteMaitre);
            } else {
                system.debug('## Comptes existants - Fusion');
                Account acc = [SELECT Id, AccountNumber FROM Account WHERE Id = :compteSecondaire.Id]; 
                valuesAccount.put(acc.Id, acc); 
                // Fusion des comptes existant
                Database.MergeResult resultat = Database.merge(compteMaitre, compteSecondaire, false);
                if (resultat.isSuccess()) {
                    system.debug('## Id des enregistrement modifié (parent) : ' + resultat.getUpdatedRelatedIds());
                } else {
                    for(Database.Error err : resultat.getErrors()) {
                        // Write each error to the debug output
                        System.debug(err.getMessage());
                        throw new KubeException(err.getMessage());
                    }
                }
                compteMaitre = [SELECT Id, AccountNumber FROM Account WHERE Id = :compteMaitre.Id]; 
                valuesAccount.put(compteMaitre.Id, compteMaitre);   
            }
            // Création tache de fusion
            String idSec = (String.isBlank(compteSecondaire.Id)) ? '' : compteSecondaire.Id;
            String refPri = (valuesAccount.get(compteMaitre.Id)==null) ? '' : valuesAccount.get(compteMaitre.Id).AccountNumber;
            String refSec = (valuesAccount.get(compteSecondaire.Id)==null) ? '' : valuesAccount.get(compteSecondaire.Id).AccountNumber;
            createTacheFusion('Compte', compteMaitre.Id, idSec, refPri, refSec, null);
            system.debug('### FIN manualMergeAccount');
            return compteMaitre.Id;
        } catch (Exception e) {
            throw e;
        }
    }

    /**
    * @description Fonction de fusion manuel de l'objet Chantier 
    * @param chantierMerged Objet contenant les valeurs saisies par l'utilisateur
    * @param newChantier Chantier modifié
    * @param doublonId Id du chantier en doublon
    * @param masterId Id du chantier maitre sélectionné
    * @return String Id du chantier maitre
    */
    public static String manualMergeChantier(Map<String,String> chantierMerged, String newChantier, String doublonId, String masterId, List<String> fieldlist) {
        system.debug('### DEBUT manualMergeChantier');
        system.debug('## chantierMerged : ' + chantierMerged);
        system.debug('## newChantier :' + newChantier);
        system.debug('## doublonId : ' + doublonId);
        system.debug('## masterId : ' + masterId);

        Chantier__c doublon = new Chantier__c();
        Chantier__c chantierMaitre = new Chantier__c();
        Chantier__c chantierSecondaire = new Chantier__c();
        Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get('Chantier__c').getDescribe().fields.getMap();
        Map<String, Chantier__c> valuesChantier = new Map<String, Chantier__c>();
        String mergeWarning;

        try {
            Chantier__c newChantierToMerge = (Chantier__c)JSON.deserialize(newChantier, Chantier__c.class);
            // Création requête SOQL pour récupération des champs
            String soqlQuery =  'SELECT ';
            for(String field : fieldsMap.keySet()){
                if (isMergeableField(field, fieldsMap)) {    
                    soqlQuery += fieldsMap.get(field) + ', ';
                }
            }
            soqlQuery = soqlQuery.substring(0, soqlQuery.length()-2);
            soqlQuery += ' FROM Chantier__c WHERE Id = ';
            system.debug('## SOQL Query : '+soqlQuery);
            // Récupération des informations des 2 chantiers à fusionner
            if(String.isNotBlank(newChantierToMerge.Id))
                newChantierToMerge = Database.query(soqlQuery+'\''+newChantierToMerge.Id+'\'');
            if(String.isNotBlank(doublonId))
                doublon = Database.query(soqlQuery+'\''+doublonId+'\'');

            // Sélection du compte principal    
            chantierMaitre = (masterId == newChantierToMerge.Id) ? newChantierToMerge : doublon;
            chantierSecondaire = (masterId == newChantierToMerge.Id) ? doublon : newChantierToMerge;
            system.debug('## chantier maitre: ' + chantierMaitre);
            system.debug('## chantier secondaire: ' + chantierSecondaire);

            // Récupération des règles de fusion sur chaque métadata
            List<RegleFusion__mdt> mergeRulesList = [SELECT Id, object__c, champ__c, regleAuto__c, profile__c, champDependant__c 
                                                        FROM RegleFusion__mdt WHERE object__c = 'Chantier'];

            // Fusion de l'intégralité des champs
            mergeWarning = processMergeObjectFields(chantierMaitre, chantierSecondaire, null, fieldsMap, mergeRulesList);
            system.debug('## Erreur fusion : '+mergeWarning);

            // Copie des valeurs (par type de champ)
            copyUserValueInFields(chantierMaitre, chantierMerged, fieldlist, fieldsMap);
                        
            // Mise à jour car second chantier inexistant
            if(String.isBlank(chantierSecondaire.Id)) {
                system.debug('## Chantier esclave inexistant - Mise à jour compte maitre');
                upsert chantierMaitre;
                chantierMaitre = [SELECT Id, numeroChantier__c FROM Chantier__c WHERE Id = :chantierMaitre.Id]; 
                valuesChantier.put(chantierMaitre.Id, chantierMaitre);
            } else {
                system.debug('## Chantiers existants - Fusion');
                // Valeur pour tache de fusion
                Chantier__c cha = [SELECT Id, numeroChantier__c FROM Chantier__c WHERE Id = :chantierSecondaire.Id]; 
                valuesChantier.put(cha.Id, cha);    
                // Fusion des enregistrements enfant du chantier
                doFusionChildObjectChantier(chantierMaitre,chantierSecondaire);
                // Valeur pour tache de fusion
                chantierMaitre = [SELECT Id, numeroChantier__c FROM Chantier__c WHERE Id = :chantierMaitre.Id]; 
                valuesChantier.put(chantierMaitre.Id, chantierMaitre);
            }
            // Création tache de fusion
            String idSec = (String.isBlank(chantierSecondaire.Id)) ? '' : chantierSecondaire.Id;
            String refPri = (valuesChantier.get(chantierMaitre.Id)==null) ? '' : valuesChantier.get(chantierMaitre.Id).numeroChantier__c;
            String refSec = (valuesChantier.get(chantierSecondaire.Id)==null) ? '' : valuesChantier.get(chantierSecondaire.Id).numeroChantier__c;
            createTacheFusion('Chantier', chantierMaitre.Id, idSec, refPri, refSec, mergeWarning);
            system.debug('### FIN manualMergeChantier');
            return chantierMaitre.Id;
        } catch (Exception e) {
            throw e;
        }
    }

    /**
    * @description Fonction de fusion automatique (rapide) de l'objet Account
    * @param account Objet du compte maitre (avec Id)
    * @param doublonKey Id Id du compte en doublon
    * @param personAccount Vrai si c'est un compte personnel
    * @param createTaskMerge Vrai si une tâche de fusion doit être créée
    * @return String Id du compte maitre
    */
    public static String autoMergeAccount(Account account, String doublonKeyId, Boolean personAccount, Boolean createTaskMerge){
        system.debug('### DEBUT autoMergeAccount');
        system.debug('## account : '+account);  
        system.debug('## doublonKeyId : '+doublonKeyId);  
        system.debug('## personAccount : '+personAccount);  
        Account accToMerge = new Account();
        Account doublon = new Account();
        Account compteMaitre = new Account();
        Account compteSecondaire = new Account();
        Account compteACopier = new Account();
        Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();
        Map<String, Object> fieldsToValue = account.getPopulatedFieldsAsMap();
        Map<String, Account> valuesAccount = new Map<String, Account>();
        String regleMaster;
        String regleStandard;
        String mergeWarning;

        try {
            accToMerge = account;       
            // Création requête SOQL pour récupération des champs
            String soqlQuery =  'SELECT ';
            for(String field : fieldsMap.keySet()){     
                if (field != 'Name' && isMergeableField(field, fieldsMap)) { 
                    //system.debug('## SOQL field: '+field);  
                    soqlQuery += fieldsMap.get(field) + ', ';
                }
            }   
            if(!personAccount) soqlQuery += 'Name, ';
            soqlQuery = soqlQuery.substring(0, soqlQuery.length()-2);
            soqlQuery += ' FROM Account WHERE Id = ';
            system.debug('## SOQL Query : '+soqlQuery);         
            // Récupération des informations du compte à fusionner
            if(String.isNotBlank(doublonKeyId))
                doublon = Database.query(soqlQuery+'\''+doublonKeyId+'\'');

            // Sélection du compte maitre
            if(String.isBlank(accToMerge.Id)) {
                // Copie des valeurs saisie par l'utilisateur dans le compte maitre. Les boolean ne sont pas copié
                for (String fieldName : fieldsToValue.keySet()){
                    copyUserAccountValue(fieldsToValue, fieldName, fieldsMap, personAccount, accToMerge);
                }
                compteMaitre = doublon;
                compteSecondaire = accToMerge;
            } else if(String.isNotBlank(doublonKeyId)){
                Account doublon2 = [SELECT Id, Type, LastModifiedDate, CreatedDate, AccountNumber FROM Account WHERE Id = :doublonKeyId];
                Account accToMerge2 = [SELECT Id, Type, LastModifiedDate, CreatedDate, AccountNumber FROM Account WHERE Id = :accToMerge.Id];
                // Récupération de tous les champs du compte et copie des valeurs saisie par l'utilisateur
                accToMerge = Database.query(soqlQuery+'\''+accToMerge.Id+'\'');

                // Récupération des règles de fusion sur chaque métadata
                String accountMetadataType = 'Compte B2C';
                if(!personAccount) accountMetadataType = 'Compte B2B';
                List<RegleFusion__mdt> mergeRulesList = [SELECT Id, object__c, champ__c, regleAuto__c, profile__c, champDependant__c 
                                                            FROM RegleFusion__mdt WHERE object__c = :accountMetadataType];
                // Récupération de la règle pour le compte maitre
                for(RegleFusion__mdt rule : mergeRulesList) {
                    if(rule.champ__c == '.') {
                        regleMaster = rule.regleAuto__c;
                        break;
                    }
                }
                // Récupération de la règle standard
                for(RegleFusion__mdt rule : mergeRulesList) {
                    if(rule.champ__c == '*') {
                        regleStandard = rule.regleAuto__c;
                        break;
                    }
                }
                
                if(!createTaskMerge) {
                    // Cas d'un batch de tache de fusion : comptes à garder/supprimer prédéfinis
                    compteMaitre = accToMerge;
                    compteSecondaire = doublon;
                } else {
                    // Sélection du compte maitre (compte existant)
                    system.debug('comparaison : '+accToMerge.Type+' / '+doublon.Type);
                    if(accToMerge.Type != doublon.Type){
                        if(accToMerge.Type == Constants.ACCOUNT_TYPE_CLIENT)                                                                 compteMaitre = accToMerge;
                        else if(doublon.Type == Constants.ACCOUNT_TYPE_CLIENT      || doublon.Type == Constants.ACCOUNT_TYPE_EXCLIENT)       compteMaitre = doublon;
                        else if(accToMerge.Type == Constants.ACCOUNT_TYPE_EXCLIENT || accToMerge.Type == Constants.ACCOUNT_TYPE_PROSPECT)    compteMaitre = accToMerge;
                        else if(doublon.Type == Constants.ACCOUNT_TYPE_PROSPECT    || doublon.Type == Constants.ACCOUNT_TYPE_CONTACT)        compteMaitre = doublon;
                        else if(accToMerge.Type == Constants.ACCOUNT_TYPE_CONTACT  || accToMerge.Type == Constants.ACCOUNT_TYPE_PRECONTACT)  compteMaitre = accToMerge;
                        else if(doublon.Type == Constants.ACCOUNT_TYPE_PRECONTACT  || doublon.Type == Constants.ACCOUNT_TYPE_PISTE)          compteMaitre = doublon;
                        else if(accToMerge.Type == Constants.ACCOUNT_TYPE_PISTE)                                                             compteMaitre = accToMerge;
                        else {
                            /*if(accToMerge2.CreatedDate >= doublon2.CreatedDate)                       compteMaitre = doublon;
                            else if(accToMerge2.CreatedDate < doublon2.CreatedDate)                   compteMaitre = accToMerge;*/
                            compteMaitre = determineMasterAccount(accToMerge, accToMerge2, doublon, doublon2, personAccount, regleMaster);
                            system.debug('\n Selection selon un type différent : '+compteMaitre + '\n');
                        }
                    } else {
                        /*if(accToMerge2.CreatedDate >= doublon2.CreatedDate)                           compteMaitre = doublon;
                        else if(accToMerge2.CreatedDate < doublon2.CreatedDate)                       compteMaitre = accToMerge;*/
                        compteMaitre = determineMasterAccount(accToMerge, accToMerge2, doublon, doublon2, personAccount, regleMaster);
                        system.debug('\n Selection selon le même type : '+compteMaitre + '\n');
                    }
                }
                compteACopier = selectAccountValuesToMerge(accToMerge, accToMerge2, doublon, doublon2, personAccount, regleStandard);

                // Copie des valeurs saisies par l'utilisateur du doublon dans l'enregistrement maitre
                for (String fieldName : fieldsToValue.keySet()){
                    copyUserAccountValue(fieldsToValue, fieldName, fieldsMap, personAccount, accToMerge);
                }

                // Sélection des valeurs modifiées en dernier
                system.debug('\n Valeurs à copier venant de : '+compteACopier + '\n');               
                // Copie des valeurs
                if(compteMaitre == accToMerge)      compteSecondaire = doublon;
                else if(compteMaitre == doublon)    compteSecondaire = accToMerge; 
                
                // Copie de tous les champs du doublon dans l'enregistrement maitre
                mergeWarning = processMergeObjectFields(compteMaitre, compteSecondaire, personAccount, fieldsMap, mergeRulesList);
                system.debug('## Erreur fusion : '+mergeWarning);
            }
            
            system.debug('## compte maitre: ' + compteMaitre);
            system.debug('## compte secondaire: ' + compteSecondaire);
            // Mise à jour car second compte inexistant
            if(String.isBlank(compteSecondaire.Id)) {
                system.debug('## Compte esclave inexistant - Mise à jour compte maitre');
                upsert compteMaitre;
                compteMaitre = [SELECT Id, AccountNumber FROM Account WHERE Id = :compteMaitre.Id]; 
                valuesAccount.put(compteMaitre.Id, compteMaitre);
            } else {
                system.debug('## Comptes existants - Fusion');
                Account acc = [SELECT Id, AccountNumber FROM Account WHERE Id = :compteSecondaire.Id]; 
                valuesAccount.put(acc.Id, acc); 
                // Fusion des comptes existant
                Database.MergeResult resultat = Database.merge(compteMaitre, compteSecondaire, false);
                if (resultat.isSuccess()) {
                    system.debug('## Id des enregistrements modifiés (parent) : ' + resultat.getUpdatedRelatedIds());
                } else {
                    for(Database.Error err : resultat.getErrors()) {
                        // Write each error to the debug output
                        System.debug(err.getMessage());
                        throw new KubeException(err.getMessage());
                    }
                }   
                compteMaitre = [SELECT Id, AccountNumber FROM Account WHERE Id = :compteMaitre.Id]; 
                valuesAccount.put(compteMaitre.Id, compteMaitre);   
            }           
            // Création tache de fusion
            if(createTaskMerge) {
                String idSec = (String.isBlank(compteSecondaire.Id)) ? '' : compteSecondaire.Id;
                String refPri = (valuesAccount.get(compteMaitre.Id)==null) ? '' : valuesAccount.get(compteMaitre.Id).AccountNumber;
                String refSec = (valuesAccount.get(compteSecondaire.Id)==null) ? '' : valuesAccount.get(compteSecondaire.Id).AccountNumber;
                system.debug('mergeWarning : '+mergeWarning);
                createTacheFusion('Compte', compteMaitre.Id, idSec, refPri, refSec, mergeWarning);
            }
            system.debug('### FIN autoMergeAccount');
            return compteMaitre.Id;
        } catch (Exception e) {
            throw e;
        }
    }

    /**
    * @description Fonction de fusion automatique (rapide) de l'objet Chantier
    * @param chantier Objet du chantier maitre (avec Id)
    * @param doublonKey Id Id du chantier en doublon
    * @param createTaskMerge Vrai si une tâche de fusion doit être créée
    * @return String String Id du chantier maitre
    */
    public static String autoMergeChantier(Chantier__c chantier, String doublonKeyId, Boolean createTaskMerge){
        system.debug('### DEBUT autoMergeChantier');
        system.debug('## chantier : '+chantier);  
        system.debug('## doublonKeyId : '+doublonKeyId);   
        
        Chantier__c chantierToMerge = new Chantier__c();
        Chantier__c doublon = new Chantier__c();
        Chantier__c chantierMaitre = new Chantier__c();
        Chantier__c chantierSecondaire = new Chantier__c();
        Chantier__c chantierACopier = new Chantier__c();
        Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get('Chantier__c').getDescribe().fields.getMap();
        Map<String, Object> fieldsToValue = chantier.getPopulatedFieldsAsMap();
        Map<String, Chantier__c> valuesChantier = new Map<String, Chantier__c>();
        String regleMaster;
        String regleStandard;
        String mergeWarning;

        try {
            chantierToMerge = chantier;       
            // Création requête SOQL pour récupération des champs
            String soqlQuery =  'SELECT ';
            for(String field : fieldsMap.keySet()){     
                //system.debug('## SOQL field: '+field);  
                soqlQuery += fieldsMap.get(field) + ', ';
            }   
            soqlQuery = soqlQuery.substring(0, soqlQuery.length()-2);
            soqlQuery += ' FROM Chantier__c WHERE Id = ';
            system.debug('## SOQL Query : '+soqlQuery);         
            system.debug('## doublonKeyId : '+doublonKeyId);              
            // Récupération des informations du compte à fusionner
            if(String.isNotBlank(doublonKeyId))
                doublon = Database.query(soqlQuery+'\''+doublonKeyId+'\'');

            // Récupération des règles de fusion sur chaque métadata
            List<RegleFusion__mdt> mergeRulesList = [SELECT Id, object__c, champ__c, regleAuto__c, profile__c, champDependant__c 
                                                        FROM RegleFusion__mdt WHERE object__c = 'Chantier'];
            // Récupération de la règle pour le compte maitre
            for(RegleFusion__mdt rule : mergeRulesList) {
                if(rule.champ__c == '.') {
                    regleMaster = rule.regleAuto__c;
                    break;
                }
            }
            // Récupération de la règle standard
            for(RegleFusion__mdt rule : mergeRulesList) {
                if(rule.champ__c == '*') {
                    regleStandard = rule.regleAuto__c;
                    break;
                }
            }

            // Sélection du compte maitre
            if(String.isBlank(chantierToMerge.Id)) {
                // Copie des valeurs saisie par l'utilisateur dans le compte maitre. Les boolean ne sont pas copié
                for (String fieldName : fieldsToValue.keySet()){
                    copyUserChantierValue(fieldsToValue, fieldName, fieldsMap, chantierToMerge);
                }
                chantierMaitre = doublon;
                chantierSecondaire = chantierToMerge;
            } else if(String.isNotBlank(doublonKeyId)){
                // Récupération de tous les champs du chantier et copie des valeurs saisies par l'utilisateur
                chantierToMerge = Database.query(soqlQuery+'\''+chantierToMerge.Id+'\'');

                for (String fieldName : fieldsToValue.keySet()){
                    copyUserChantierValue(fieldsToValue, fieldName, fieldsMap, chantierMaitre);
                }

                if(!createTaskMerge) {
                    // Cas d'un batch d'une tache de fusion : comptes à garder/supprimer prédéfinis
                    chantierMaitre = chantierToMerge;
                    chantierSecondaire = doublon;
                } else {
                    chantierMaitre = determineMasterChantier(chantierToMerge, chantierToMerge, doublon, doublon, regleStandard);
                    system.debug('\n Selection selon un type différent : '+chantierMaitre + '\n');

                    if(chantierMaitre == chantierToMerge)                                   chantierSecondaire = doublon;
                    else if(chantierMaitre == doublon)                                      chantierSecondaire = chantierToMerge;
                }
                chantierACopier = selectChantierValuesToMerge(chantierToMerge, chantierToMerge, doublon, doublon, regleStandard);
                
                system.debug('## chantier a copier: ' + chantierACopier);
                system.debug('## chantier maitre: ' + chantierMaitre);
                system.debug('## chantier secondaire: ' + chantierSecondaire);
 
                // Copie de tous les champs du doublon dans l'enregistrement maitre
                mergeWarning = processMergeObjectFields(chantierMaitre, chantierSecondaire, null, fieldsMap, mergeRulesList);
                system.debug('## Erreur fusion : '+mergeWarning);
            }

            // Mise à jour car second chantier inexistant
            if(String.isBlank(chantierSecondaire.Id)) {
                system.debug('## Chantier esclave inexistant - Mise à jour chantier maitre');
                upsert chantierMaitre;
                chantierMaitre = [SELECT Id, numeroChantier__c FROM Chantier__c WHERE Id = :chantierMaitre.Id]; 
                valuesChantier.put(chantierMaitre.Id, chantierMaitre);
            } else {
                system.debug('## Chantiers existants - Fusion');
                Chantier__c cha = [SELECT Id, numeroChantier__c FROM Chantier__c WHERE Id = :chantierSecondaire.Id]; 
                valuesChantier.put(cha.Id, cha);  
                // Fusion des enregistrements enfant du chantier             
                doFusionChildObjectChantier(chantierMaitre,chantierSecondaire); 
                // Valeur pour tache de fusion
                chantierMaitre = [SELECT Id, numeroChantier__c FROM Chantier__c WHERE Id = :chantierMaitre.Id]; 
                valuesChantier.put(chantierMaitre.Id, chantierMaitre);
            }                   
            // Création tache de fusion
            if(createTaskMerge) {
                String idSec = (String.isBlank(chantierSecondaire.Id)) ? '' : chantierSecondaire.Id;
                String refPri = (valuesChantier.get(chantierMaitre.Id)==null) ? '' : valuesChantier.get(chantierMaitre.Id).numeroChantier__c;
                String refSec = (valuesChantier.get(chantierSecondaire.Id)==null) ? '' : valuesChantier.get(chantierSecondaire.Id).numeroChantier__c;
                createTacheFusion('Chantier', chantierMaitre.Id, idSec, refPri, refSec, mergeWarning);
            }
            system.debug('### FIN autoMergeChantier');
            return chantierMaitre.Id;
        } catch (Exception e) {
            throw e;
        }
    }

    /**
    * @description Execution de la fusion de 2 enregistrements (compte ou chantier) : fusion champ par champ selon des règles pré-définies
    * @param obj Enregistrement maitre pour la fusion
    * @param objToMerge Enregistrement esclave
    * @param personAccount Vrai si l'enregistrement concerne un compte personnel ou faux si professionel. Doit être égale à null si autre objet
    * @param fieldsMap Liste de tous les champs de l'objet
    * @param mergeRulesList Liste des règles de fusion
    */
    public static String processMergeObjectFields(sObject obj, sObject objToMerge, Boolean personAccount, Map<String, Schema.SObjectField> fieldsMap, List<RegleFusion__mdt> mergeRulesList) {
        system.debug('### DEBUT processMergeObjectFields');
        String warnings='';

        // Création de la map pour associer chaque règle à son champ
        Map<String,RegleFusion__mdt> reglesFusionMap = new Map<String,RegleFusion__mdt>();
        for(RegleFusion__mdt regleFusion : mergeRulesList){
            reglesFusionMap.put(regleFusion.champ__c.toLowerCase(), regleFusion);
            system.debug('## Pour le champ '+regleFusion.champ__c+', règle auto : '+regleFusion.regleAuto__c);
        }
        // Boucle sur tous les champs pour récupérer la règle de fusion
        for(String fieldName : fieldsMap.keySet()){
            Boolean useStandardRule = false;
            if((personAccount == null || !personAccount || fieldName != 'Name') && isMergeableField(fieldName, fieldsMap) && objToMerge.get(fieldName) != null) {
                // Récupération de la règle de fusion selon le champ
                RegleFusion__mdt regleFusion = reglesFusionMap.get(fieldName.toLowerCase());
                // Si pas de règle, dans ce cas prendre la règle standard
                if(regleFusion==null)
                    useStandardRule=true;
                // Traitement
                if(regleFusion != null || useStandardRule){
                    Schema.DisplayType fieldType = fieldsMap.get(fieldName).getDescribe().getType();
                    system.debug('## Regle de fusion: '+regleFusion);
                    system.debug('## Type: '+fieldType);
                    //* REGLE "COPIE X DANS Y"
                    if(useStandardRule || regleFusion.regleAuto__c == 'Standard'){
                        // ACCOUNT OBJECT
                        if(personAccount!=null) {
                            if(fieldName == 'Name'){
                                if(!personAccount) obj.put(fieldName, objToMerge.get(fieldName));
                            } else {           
                                obj.put(fieldName, objToMerge.get(fieldName));
                            }
                        } else {
                            // OTHER OBJECT
                            obj.put(fieldName, objToMerge.get(fieldName));
                        }
                    }
                    //* REGLE "X + Y"
                    else if(regleFusion.regleAuto__c == 'Somme' && (fieldType == Schema.DisplayType.Integer ||
                                                                    fieldType == Schema.DisplayType.Double ||
                                                                    fieldType == Schema.DisplayType.Currency))
                        obj.put(fieldName, addTwoNumbers((Decimal)obj.get(fieldName), (Decimal)objToMerge.get(fieldName)));
                    //* REGLE "MAX ENTRE X ET Y (Date)"
                    else if(regleFusion.regleAuto__c == 'Maximum' && fieldType == Schema.DisplayType.Date) 
                        obj.put(fieldName, maximumDate((Date)obj.get(fieldName), (Date)objToMerge.get(fieldName)));
                    //* REGLE "MAX ENTRE X ET Y (Datetime)" 
                    else if(regleFusion.regleAuto__c == 'Maximum' && fieldType == Schema.DisplayType.DateTime)
                        obj.put(fieldName, maximumDateTime((Datetime)obj.get(fieldName), (Datetime)objToMerge.get(fieldName)));
                    //* REGLE "MIN ENTRE X ET Y (Date)"
                    else if(regleFusion.regleAuto__c == 'Minimum' && fieldType == Schema.DisplayType.Date)
                        obj.put(fieldName, minimumDate((Date)obj.get(fieldName), (Date)objToMerge.get(fieldName)));
                    //* REGLE "MIN ENTRE X ET Y (Datetime)"
                    else if(regleFusion.regleAuto__c == 'Minimum' && fieldType == Schema.DisplayType.DateTime)
                        obj.put(fieldName, minimumDateTime((Datetime)obj.get(fieldName), (Datetime)objToMerge.get(fieldName)));
                    //* REGLE "X OU Y"
                    else if(regleFusion.regleAuto__c == 'Ou' && fieldType == Schema.DisplayType.Boolean)  
                        obj.put(fieldName, (Boolean)obj.get(fieldName) || (Boolean)objToMerge.get(fieldName));
                    //* REGLE "X ET Y"
                    else if(regleFusion.regleAuto__c == 'Et' && fieldType == Schema.DisplayType.Boolean)  
                        obj.put(fieldName, (Boolean)obj.get(fieldName) && (Boolean)objToMerge.get(fieldName));
                    //* REGLE "DEPENDANCE DE X AVEC Y"
                    else if(regleFusion.regleAuto__c == 'Dépendance' && reglesFusionMap.get(regleFusion.champDependant__c).regleAuto__c == 'Maximum' && 
                                                                                                fieldsMap.get(regleFusion.champDependant__c).getDescribe().getType() == Schema.DisplayType.Date) 
                        obj.put(fieldName, conditionMaxDate((String)obj.get(fieldName), (String)objToMerge.get(fieldName), (Date)obj.get(regleFusion.champDependant__c), (Date)objToMerge.get(regleFusion.champDependant__c)));
                    else if(regleFusion.regleAuto__c == 'Dépendance' && reglesFusionMap.get(regleFusion.champDependant__c).regleAuto__c == 'Maximum' && 
                                                                                                fieldsMap.get(regleFusion.champDependant__c).getDescribe().getType() == Schema.DisplayType.DateTime) 
                        obj.put(fieldName, conditionMaxDateTime((String)obj.get(fieldName), (String)objToMerge.get(fieldName), (DateTime)obj.get(regleFusion.champDependant__c), (DateTime)objToMerge.get(regleFusion.champDependant__c)));
                    else if(regleFusion.regleAuto__c == 'Dépendance' && reglesFusionMap.get(regleFusion.champDependant__c).regleAuto__c == 'Minimum' && 
                                                                                                fieldsMap.get(regleFusion.champDependant__c).getDescribe().getType() == Schema.DisplayType.Date) 
                        obj.put(fieldName, conditionMinDate((String)obj.get(fieldName), (String)objToMerge.get(fieldName), (Date)obj.get(regleFusion.champDependant__c), (Date)objToMerge.get(regleFusion.champDependant__c)));
                    else if(regleFusion.regleAuto__c == 'Dépendance' && reglesFusionMap.get(regleFusion.champDependant__c).regleAuto__c == 'Minimum' && 
                                                                                                fieldsMap.get(regleFusion.champDependant__c).getDescribe().getType() == Schema.DisplayType.DateTime) 
                        obj.put(fieldName, conditionMinDateTime((String)obj.get(fieldName), (String)objToMerge.get(fieldName), (DateTime)obj.get(regleFusion.champDependant__c), (DateTime)objToMerge.get(regleFusion.champDependant__c)));
                    //* REGLE "SUPPRESSION DE LA VALEUR"
                    else if(regleFusion.regleAuto__c == 'Vide') 
                        obj.put(fieldName, null);
                    //* ERREUR IDENTIFIE
                    else {
                        String message = 'La fusion a échouée pour le champ '+regleFusion.champ__c+ ' avec la règle '+regleFusion.regleAuto__c+' et le type du champ '+ fieldType+'\n';
                        system.debug(message);
                        warnings += message;
                    }

                    if(regleFusion != null && (regleFusion.champ__c == 'statutDernierContrat__c' || regleFusion.champ__c == 'lastModifiedByCall__c')){
                        system.debug('\nregleFusion.regleAuto__c : '+regleFusion.regleAuto__c + '\n');
                        system.debug('\nregleFusion.champDependant__c : '+regleFusion.champDependant__c + '\n');
                        system.debug('\nreglesFusionobjMap.get(regleFusion.champDependant__c).regleAuto__c : '+reglesFusionMap.get(regleFusion.champDependant__c).regleAuto__c + '\n');
                        system.debug('\nfieldType : '+fieldType + '\n');
                    }
                }
            }
        }
        system.debug('### FIN processMergeObjectFields');
        return warnings;
    }

    /**
    * @description Vérifie si le champ peut être fusionné
    * @param fieldName Nom API du champ
    * @param fieldsMap Map contenant la liste des champs de l'objet
    * @return Boolean True si le champ peut être utilisé pour la fusion, sinon non
    */
    public static Boolean isMergeableField(String fieldName, Map<String, Schema.SObjectField> fieldsMap){    
        Boolean isMergeable = false;    
        if(fieldsMap.get(fieldName) != null) {
            // Récupération des informations du champ
            Schema.DescribeFieldResult fieldInfo = fieldsMap.get(fieldName).getDescribe();
            if (!fieldName.contains('__pc') && fieldInfo.isCreateable() && !fieldInfo.isDeprecatedAndHidden() 
                && ((fieldInfo.isCustom() && !fieldInfo.isCalculated()) || (!fieldInfo.isCustom() && fieldInfo.isUpdateable()))) { 
                isMergeable=true;
            }
        }       
        return isMergeable;
    }

    /**
    * @description Copie les valeurs des champs du nouvel objet dans l'ancien pour les comptes
    * @param fieldsToValue Liste des champs avec les nouvelles valeurs
    * @param fieldName Nom API du champ
    * @param fieldsMap Map metadata des champs
    * @param personAccount True si c'est un compte personnel
    * @param objectAcc L'objet avec les nouvelles valeurs
    */
    private static void copyUserAccountValue(Map<String, Object> fieldsToValue, String fieldName, 
                                            Map<String, Schema.SObjectField> fieldsMap, 
                                            Boolean personAccount, Account objectAcc) { 
        if (fieldsToValue.get(fieldName) != null && isMergeableField(fieldName, fieldsMap)) { 
            // Vérification si Name doit être enregistré (erreur sinon pour les comptes perso)
            // Ne copie pas la valeur si c'est un boolean dont la valeur est true
            DisplayType fieldType = fieldsMap.get(fieldName).getDescribe().getType();
            if((!personAccount || (personAccount && fieldName != 'Name')) 
                && ((fieldType == DisplayType.Boolean && fieldsToValue.get(fieldName)!=true) ||(fieldType != DisplayType.Boolean))) 
            {
                objectAcc.put(fieldName,fieldsToValue.get(fieldName));
                system.debug('## User Value: '+fieldName+' / '+fieldsToValue.get(fieldName));
            }
        }
    }

    /**
    * @description Copie les valeurs des champs du nouvel objet dans l'ancien pour les chantiers
    * @param fieldsToValue Liste des champs avec les nouvelles valeurs
    * @param fieldName Nom API du champ
    * @param fieldsMap Map metadata des champs
    * @param objectCha L'objet avec les nouvelles valeurs
    */
    private static void copyUserChantierValue(Map<String, Object> fieldsToValue, String fieldName, 
                                            Map<String, Schema.SObjectField> fieldsMap, 
                                            Chantier__c objectCha) {    
        if (fieldsToValue.get(fieldName) != null && isMergeableField(fieldName, fieldsMap)) { 
            DisplayType fieldType = fieldsMap.get(fieldName).getDescribe().getType();
            // Ne copie pas la valeur si c'est un boolean dont la valeur est true
            if((fieldType == DisplayType.Boolean && fieldsToValue.get(fieldName)==true)
                ||(fieldType != DisplayType.Boolean)) {
                objectCha.put(fieldName,fieldsToValue.get(fieldName));
                system.debug('## User Value: '+fieldName+' / '+fieldsToValue.get(fieldName));
            }
        }
    }

    /**
    * @description Création d'une tache de fusion pour l'historique
    * @param objet Type de l'objet (Compte ou Chantier)
    * @param idConserve ID de l'enregistrement conservé
    * @param idSupprime ID de l'enregistrement supprimé
    * @param refConserve Référance de l'enregistrement conservé
    * @param refSupprime Référence de l'enregistrement supprimé
    * @param erreur Message d'erreur reçue lors de la fusion
    */
    private static void createTacheFusion(String objet, String idConserve, String idSupprime, 
                                            String refConserve, String refSupprime, String erreur) {   
        TacheFusion__c tacheFusion = new TacheFusion__c(objet__c=objet, IDConserve__c=idConserve,IDSupprime__c=idSupprime,
                                                        refConservee__c=refConserve,refSupprimee__c=refSupprime,
                                                        dateFusion__c=Datetime.now(),estTermine__c=true,erreur__c=erreur);
        insert tacheFusion;
    }

    /**
    * @description Fusion des chantiers existants avec récupération des enregistrement enfants pour rattachement sur le maitre (utilisation de la classe Metadata)
    * @param chantierMaitre Chantier maitre
    * @param chantierSecondaire Chantier en doublon à supprimer
    */
    private static void doFusionChildObjectChantier(Chantier__c chantierMaitre, Chantier__c chantierSecondaire) {
        // Création requete SOQL pour récupération des champs
        List<SObject> objectListFinal = new List<SObject>();
        List<Schema.ChildRelationship> childRelationships = Chantier__c.SObjectType.getDescribe().getChildRelationships();
                
        for(Schema.ChildRelationship child : childRelationships){
            if(child.getChildSObject().getDescribe().isUpdateable() && child.getRelationshipName() != null){
                if(child.getChildSObject().getDescribe().getName() != 'Import__c'){
                    String soqlQuery2 = 'SELECT Id, ' +child.getField()+ ' FROM ' + child.getChildSObject().getDescribe().getName() + ' WHERE ' +child.getField()+ ' = ';
                    //system.debug('## SOQL Field : '+soqlQuery2);
                    List<SObject> sobjectsList = Database.query(soqlQuery2+'\''+chantierSecondaire.Id+'\'');
                    if(child.getField().getDescribe().isUpdateable() && sobjectsList != null){
                        for(SObject SO : sobjectsList){
                            SO.put(child.getField(), chantierMaitre.Id);
                            objectListFinal.add(SO);
                        }
                            
                    }
                }
            }
        }
        system.debug('## Liste objets modifiés : '+objectListFinal);
        // Fusion
        update objectListFinal;
        upsert chantierMaitre;
        if(String.isNotBlank(chantierSecondaire.Id)) {
            delete chantierSecondaire;
        }   
    }

    /**
    * @description Selection des valeurs à copier en se basant sur la règle standard pour les champs de l'objet Account (utilisation de la classe Metadata)
    * @param acc1           Compte avec tous les champs renseignés
    * @param acc1info       Information de création/modification du compte
    * @param acc2           Compte avec tous les champs renseignés
    * @param acc2info       Information de création/modification du compte
    * @param personAccount  Compte personnel ou professionnel
    */
    public static Account selectAccountValuesToMerge(Account acc1, Account acc1info, Account acc2, Account acc2info, Boolean personAccount, String regleStandard) {
        Account selectedAccount = null;

        system.debug('\n 1er compte : '+acc1.Id + '\n');
        system.debug('\n 1er compte créé le '+acc1info.CreatedDate + ', modifié le '+acc1info.LastModifiedDate + '\n');
        system.debug('\n 2e compte : '+acc2.Id + '\n');
        system.debug('\n 2e compte créé le '+acc2info.CreatedDate + ', modifié le '+acc2info.LastModifiedDate + '\n');

        if(regleStandard == 'Premier créé'){
            if(acc1info.CreatedDate >= acc2info.CreatedDate || acc1info.CreatedDate == null)                     
                selectedAccount = acc2;
            else if(acc1info.CreatedDate < acc2info.CreatedDate)
                selectedAccount = acc1;  
        } else if(regleStandard == 'Dernier créé'){
            if(acc1info.CreatedDate >= acc2info.CreatedDate)                     
                selectedAccount = acc1;
            else if(acc1info.CreatedDate < acc2info.CreatedDate || acc1info.CreatedDate == null)
                selectedAccount = acc2;  
        } else if(regleStandard == 'Premier modifié'){
            if(acc1info.LastModifiedDate >= acc2info.LastModifiedDate || acc1info.LastModifiedDate == null)                     
                selectedAccount = acc2;
            else if(acc1info.LastModifiedDate < acc2info.LastModifiedDate)
                selectedAccount = acc1;  
        } else if(regleStandard == 'Dernier modifié'){
            if(acc1info.LastModifiedDate >= acc2info.LastModifiedDate)                     
                selectedAccount = acc1;
            else if(acc1info.LastModifiedDate < acc2info.LastModifiedDate || acc1info.LastModifiedDate == null)
                selectedAccount = acc2;  
        }

        system.debug('\n Règle fusion : '+ regleStandard +' avec le compte : '+selectedAccount + '\n');        
        return selectedAccount;
    }
                

    /**
    * @description Selection du compte maitre pour la fusion des champs de l'objet Account (utilisation de la classe Metadata)
    * @param acc1           Compte avec tous les champs renseignés
    * @param acc1info       Information de création/modification du compte
    * @param acc2           Compte avec tous les champs renseignés
    * @param acc2info       Information de création/modification du compte
    * @param personAccount  Compte personnel ou professionnel
    */
    public static Account determineMasterAccount(Account acc1, Account acc1info, Account acc2, Account acc2info, Boolean personAccount, String regleStandard){
        Account compteMaitre = acc1;

        system.debug('\n 1er compte : '+acc1.Id + '\n');
        system.debug('\n 1er compte créé le '+acc1info.CreatedDate + ', modifié le '+acc1info.LastModifiedDate + '\n');
        system.debug('\n 2e compte : '+acc2.Id + '\n');
        system.debug('\n 2e compte créé le '+acc2info.CreatedDate + ', modifié le '+acc2info.LastModifiedDate + '\n');

        if(regleStandard == 'Premier créé'){
            if(acc1info.CreatedDate >= acc2info.CreatedDate)                       compteMaitre = acc2;
            else if(acc1info.CreatedDate < acc2info.CreatedDate)                   compteMaitre = acc1;
        } else if(regleStandard == 'Dernier créé'){
            if(acc1info.CreatedDate >= acc2info.CreatedDate)                       compteMaitre = acc1;
            else if(acc1info.CreatedDate < acc2info.CreatedDate)                   compteMaitre = acc2;
        } else if(regleStandard == 'Premier modifié'){
            if(acc1info.LastModifiedDate >= acc2info.LastModifiedDate)             compteMaitre = acc2;
            else if(acc1info.LastModifiedDate < acc2info.LastModifiedDate)         compteMaitre = acc1;
        } else if(regleStandard == 'Dernier modifié'){
            if(acc1info.LastModifiedDate >= acc2info.LastModifiedDate)             compteMaitre = acc1;
            else if(acc1info.LastModifiedDate < acc2info.LastModifiedDate)         compteMaitre = acc2;
        }

        system.debug('\n Règle Maitre : '+ regleStandard +' avec le compte : '+compteMaitre + '\n');
        return compteMaitre;
    }
    
    /**
    * @description  Selection des valeurs à copier en se basant sur la règle standard pour les champs de l'objet Chantier (utilisation de la classe Metadata)
    * @param cha1           Chantier avec tous les champs renseignés
    * @param cha1info       Information de création/modification du Chantier
    * @param cha2           Chantier avec tous les champs renseignés
    * @param cha2info       Information de création/modification du Chantier
    */
    public static Chantier__c selectChantierValuesToMerge(Chantier__c cha1, Chantier__c cha1info, Chantier__c cha2, Chantier__c cha2info, String regleStandard) {
        Chantier__c selectedChantier = null;

        system.debug('\n 1er chantier : '+cha1.Id + '\n');
        system.debug('\n 1er chantier créé le '+cha1info.CreatedDate + ', modifié le '+cha1info.LastModifiedDate + '\n');
        system.debug('\n 2e chantier : '+cha2.Id + '\n');
        system.debug('\n 2e chantier créé le '+cha2info.CreatedDate + ', modifié le '+cha2info.LastModifiedDate + '\n');

        if(regleStandard == 'Premier créé'){
            if(cha1info.CreatedDate >= cha2info.CreatedDate || cha1info.CreatedDate == null)                     
                selectedChantier = cha2;
            else if(cha1info.CreatedDate < cha2info.CreatedDate)
                selectedChantier = cha1;  
        } else if(regleStandard == 'Dernier créé'){
            if(cha1info.CreatedDate >= cha2info.CreatedDate)                     
                selectedChantier = cha1;
            else if(cha1info.CreatedDate < cha2info.CreatedDate || cha1info.CreatedDate == null)
                selectedChantier = cha2;  
        } else if(regleStandard == 'Premier modifié'){
            if(cha1info.LastModifiedDate >= cha2info.LastModifiedDate || cha1info.LastModifiedDate == null)                     
                selectedChantier = cha2;
            else if(cha1info.LastModifiedDate < cha2info.LastModifiedDate)
                selectedChantier = cha1;  
        } else if(regleStandard == 'Dernier modifié'){
            if(cha1info.LastModifiedDate >= cha2info.LastModifiedDate)                     
                selectedChantier = cha1;
            else if(cha1info.LastModifiedDate < cha2info.LastModifiedDate || cha1info.LastModifiedDate == null)
                selectedChantier = cha2;  
        }

        system.debug('\n Règle fusion : '+ regleStandard +' avec le chantier : '+selectedChantier + '\n');
        return selectedChantier;
    }
                

    /**
    * @description  Selection du chantier maitre pour la fusion des champs de l'objet Chantier__c (utilisation de la classe Metadata)
    * @param cha1           Compte avec tous les champs renseignés
    * @param cha1info       Information de création/modification du chantier
    * @param cha2           Compte avec tous les champs renseignés
    * @param cha2info       Information de création/modification du chantier
    */
    public static Chantier__c determineMasterChantier(Chantier__c cha1, Chantier__c cha1info, Chantier__c cha2, Chantier__c cha2info, String regleStandard){
        Chantier__c chantierMaitre = cha1;

        system.debug('\n 1er chantier : '+cha1.Id + '\n');
        system.debug('\n 1er chantier créé le '+cha1info.CreatedDate + ', modifié le '+cha1info.LastModifiedDate + '\n');
        system.debug('\n 2e chantier : '+cha2.Id + '\n');
        system.debug('\n 2e chantier créé le '+cha2info.CreatedDate + ', modifié le '+cha2info.LastModifiedDate + '\n');

        if(regleStandard == 'Premier créé'){
            if(cha1info.CreatedDate >= cha2info.CreatedDate)                       chantierMaitre = cha2;
            else if(cha1info.CreatedDate < cha2info.CreatedDate)                   chantierMaitre = cha1;
        } else if(regleStandard == 'Dernier créé'){
            if(cha1info.CreatedDate >= cha2info.CreatedDate)                       chantierMaitre = cha1;
            else if(cha1info.CreatedDate < cha2info.CreatedDate)                   chantierMaitre = cha2;
        } else if(regleStandard == 'Premier modifié'){
            if(cha1info.LastModifiedDate >= cha2info.LastModifiedDate)             chantierMaitre = cha2;
            else if(cha1info.LastModifiedDate < cha2info.LastModifiedDate)         chantierMaitre = cha2;
        } else if(regleStandard == 'Dernier modifié'){
            if(cha1info.LastModifiedDate >= cha2info.LastModifiedDate)             chantierMaitre = cha1;
            else if(cha1info.LastModifiedDate < cha2info.LastModifiedDate)         chantierMaitre = cha2;
        }

        system.debug('\n Règle Maitre : '+ regleStandard +' avec le chantier : '+chantierMaitre + '\n');        
        return chantierMaitre;
    }

    /**
    * @description Fonction permettant de copier les valeurs saisies par l'utilisateur dans les champs de l'objet maitre
    * @param obj Objet maitre
    * @param objToMerge Map contenant les valeurs saisie par le client
    * @param fieldlist Liste des champs disponibles dans la page
    * @param fieldsMap Liste de tous les champs de l'objet maitre
    */
    public static void copyUserValueInFields(sObject obj, Map<String,String> objToMerge, List<String> fieldlist, Map<String, Schema.SObjectField> fieldsMap) {
        system.debug('### DEBUT copyUserValueInFields');
        // Copie des valeurs (par type de champ)
        for(String champ : fieldlist){
            if(fieldsMap.get(champ) == null){
                system.debug('Le champ suivant n\'existe plus et doit être supprimé des metadata : '+champ);
            } else {
                Schema.DisplayType fieldType = fieldsMap.get(champ).getDescribe().getType();
                system.debug(champ + ' est de type : ' + fieldType);

                // TEXT
                if(fieldType == Schema.DisplayType.String || fieldType == Schema.DisplayType.Email || fieldType == Schema.DisplayType.Picklist ||
                   fieldType == Schema.DisplayType.Phone || fieldType == Schema.DisplayType.TextArea || fieldType == Schema.DisplayType.MultiPicklist){
                    obj.put(champ, objToMerge.get(champ));
                // DATE
                } else if(fieldType == Schema.DisplayType.Date){
                    if(String.isNotBlank((String)objToMerge.get(champ)))
                        obj.put(champ, Date.parse((String)objToMerge.get(champ)));
                // DATETIME
                } else if(fieldType == Schema.DisplayType.Datetime){
                    if(String.isNotBlank((String)objToMerge.get(champ)))
                        obj.put(champ, Datetime.parse((String)objToMerge.get(champ)));
                // BOOLEAN
                } else if(fieldType == Schema.DisplayType.Boolean){
                    if(objToMerge.get(champ) == 'Oui' || objToMerge.get(champ) == 'true')
                        obj.put(champ, true);
                    else 
                        obj.put(champ, false);
                // NUMBER
                } else if(fieldType == Schema.DisplayType.Double){
                    if(String.isNotBlank((String)objToMerge.get(champ)))
                        obj.put(champ, Integer.valueOf(objToMerge.get(champ)));
                // LOOKUP
                } else if(fieldType == Schema.DisplayType.Reference){
                    if(String.isNotBlank((String)objToMerge.get(champ)) && objToMerge.get(champ) != '000000000000000')
                        obj.put(champ, objToMerge.get(champ));
                }
            }
        }
        system.debug('### FIN copyUserValueInFields');
    }

    // Fonctions mathématiques récurentes utilisées pour les changement de valeurs
    public static Decimal addTwoNumbers(Decimal a, Decimal b){
        if(a == null) return b;
        else if(b == null) return a;
        else return a+b;
    }

    public static Date minimumDate(Date a, Date b){
        if(a >= b) return b;
        return b;
    }

    public static Date maximumDate(Date a, Date b){
        if(a >= b) return a;
        return b;
    }

    public static Datetime minimumDateTime(Datetime a, Datetime b){
        if(a >= b) return b;
        return b;
    }

    public static Datetime maximumDateTime(Datetime a, Datetime b){
        if(a >= b) return a;
        return b;
    }

    public static String conditionMinDate(String resultat1, String resultat2, Date date1, Date date2){
        if(date1 >= date2) return resultat2;
        return resultat2;
    }

    public static String conditionMinDateTime(String resultat1, String resultat2, Datetime date1, Datetime date2){
        if(date1 >= date2) return resultat2;
        return resultat2;
    }

    public static String conditionMaxDate(String resultat1, String resultat2, Date date1, Date date2){
        if(date1 >= date2) return resultat1;
        return resultat2;
    }

    public static String conditionMaxDateTime(String resultat1, String resultat2, Datetime date1, Datetime date2){
        if(date1 >= date2) return resultat1;
        return resultat2;
    }
}