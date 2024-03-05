//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR001_fsl_GenerateurRessource
//-- Modifié par : CGI - FSL
//-- Modifié le  : 09/04/2018
//-- Description : Classe exécutée par le PB - Création auto d'un user ou modification s'il existe déjà
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --

public with sharing class TR001_fsl_GenerateurRessource {
 
    
    @InvocableMethod
    public static void createUser(List<fsl_tech_generateurRessource__c> userRessourceList){
        system.debug('################## Start - TR001_fsl_GenerateurRessource ');

        // Variables globales
        List<User> userToUpsertList = new List<User>();
		Map<String, fsl_tech_generateurRessource__c> generatorMap = new Map <String,fsl_tech_generateurRessource__c>();
        Map<ID, fsl_tech_generateurRessource__c> generatorRoleMap = new Map <ID,fsl_tech_generateurRessource__c>();
		Map<String, ID> userMap = new Map <String,ID>();
        FieldServiceError generatedError = new FieldServiceError();
        
        // Construction des collections par SOQL
        for (fsl_tech_generateurRessource__c gnr :  userRessourceList) {
				generatorMap.put(gnr.fsl_matriculeGC__c, gnr);  
                generatorRoleMap.put(gnr.fsl_roleID__c, gnr); 
        }
		for (User usr : [Select ID, matriculeGC__c From User where matriculeGC__c IN :generatorMap.KeySet()]) {
				userMap.put(usr.matriculeGC__c, usr.ID);  
        }
        Map<String, ID> profileMap = FieldServiceUtils.loadFslProfileMap();

        //Préparation des User à créer/modifier
        for (fsl_tech_generateurRessource__c generator : userRessourceList) {

            // Etape 0 : Contrôle des données de référence   
            if ((generator.fsl_roleID__c != null) && !generatorRoleMap.containsKey(generator.fsl_roleID__c)){
                system.debug('################## DEBUG - Erreur code 1 : roleID inexistant');
                generator.fsl_statut__c = '1';
                generator.fsl_messageErreur__c = 'Erreur roleID inexistant : '+generator.fsl_roleID__c;
                generatorMap.put(generator.fsl_matriculeGC__c, generator);
                throw new FieldServiceException(generator.fsl_messageErreur__c);
            }
        
            // Etape 1 : Création de la liste des utilisateurs à crééer/modifier 
            User userToUpsert = new User();
			try{  
                userToUpsert.Alias = generator.fsl_alias__c;
                userToUpsert.CommunityNickname = generator.fsl_communityNickname__c;
                userToUpsert.DefaultGroupNotificationFrequency = generator.fsl_defaultGroupNotificationFrequency__c;
                userToUpsert.DigestFrequency = generator.fsl_digestFrequency__c;
                userToUpsert.EmailEncodingKey = generator.fsl_emailEncodingKey__c;                
                userToUpsert.LanguageLocaleKey = generator.fsl_languageLocaleKey__c;                
                userToUpsert.LocaleSidKey = generator.fsl_localeSidKey__c;                
                userToUpsert.Phone = generator.fsl_phone__c;   
                userToUpsert.UserRoleId = generator.fsl_roleID__c; 
                system.debug('**profileMap'+profileMap);
                if(profileMap.containsKey(generator.fsl_typePlanification__c))
                    userToUpsert.ProfileId = profileMap.get(generator.fsl_typePlanification__c);
                userToUpsert.TimeZoneSidKey = generator.fsl_timeZoneSidKey__c;                
                userToUpsert.Title = generator.fsl_title__c;                
                userToUpsert.Username = generator.fsl_username__c;                
                userToUpsert.UserPreferencesContentEmailAsAndWhen = Boolean.valueOf(generator.fsl_contentEmailAsAndWhen__c);                
                userToUpsert.UserPreferencesContentNoEmail = Boolean.valueOf(generator.fsl_contentNoEmail__c);                
                userToUpsert.Phone = generator.fsl_phone__c;                
                userToUpsert.MobilePhone = generator.fsl_mobilePhone__c;               
                userToUpsert.Username = generator.fsl_username__c ;
                userToUpsert.Email = generator.fsl_email__c;
                userToUpsert.typePlanification__c = generator.fsl_typePlanification__c;
                userToUpsert.matriculeGC__c = generator.fsl_matriculeGC__c;
                userToUpsert.metier__c  = generator.fsl_metier__c;
                userToUpsert.SGID__c = generator.fsl_SGID__c;
                userToUpsert.codeDepot__c = generator.fsl_depotCodeGC__c;
                
                // Calcul des champs Nom et Prénom  
                if ((generator.fsl_firstName__c != null &&  generator.fsl_lastName__c != null)){               
                    userToUpsert.FirstName = generator.fsl_firstName__c;
                    userToUpsert.LastName = generator.fsl_lastName__c;
                }
                else if (generator.fsl_name__c != null){               
                    userToUpsert.LastName = generator.fsl_name__c;
                }
                 
                userToUpsert.dateEntree__c  =  Date.parse(generator.fsl_dateEntree__c);
                if (generator.fsl_dateSortie__c != null)
                    userToUpsert.dateSortie__c  =  Date.parse(generator.fsl_dateSortie__c);
                userToUpsert.codeDepot__c = generator.fsl_depotCodeGC__c;
                
                // Calcul de l'activation du user
                if(userToUpsert.dateEntree__c <= System.today() && (userToUpsert.dateSortie__c == null || userToUpsert.dateSortie__c >= System.today() ))
                    userToUpsert.isActive = true;
                
                if (userMap.containsKey(userToUpsert.matriculeGC__c)){
                    userToUpsert.id = userMap.get(userToUpsert.matriculeGC__c);
                }
                userToUpsertList.add(userToUpsert);   

            } catch (Exception e){
                system.debug('################## DEBUG - Erreur Conversion du générateur de ressource en User '+generator);
                String subject = 'Erreur Conversion du générateur de ressource en User';
                generatedError.addExeptionError(e,subject);
        	}     
        }
  
		// Création de l'utilisateur  
        if (!userToUpsertList.isEmpty()){       
			// Etape 2 : Création/Modification des utilisateurs et attribution des permissions
			ID jobID = System.enqueueJob(new TR002_fsl_GenerateurRessource(userToUpsertList,generatorMap,generatedError));    
		}

    }   
}