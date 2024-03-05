//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR020_Collaborator 
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 18/12/2020
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR020_Collaborator {

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les collaborateurs
    * @param userContext Objet contexte de l'utilisateur courant
    */
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        applyDataUpdateRules(userContext);
        applyAsyncUpdateRules(userContext);
    }

    /**
    * @description Méthode exécutant les différentes méthode de MAJ pour les collaborateurs
    * @param userContext Objet contexte de l'utilisateur courant
    */
   private static void applyDataUpdateRules(UserContext userContext) {
        // Initialisation des données intermédiaires 
        Map<Id, Collaborator__c>  oldCollaborators = (Map<Id, Collaborator__c>)Trigger.oldMap;
        List<Collaborator__c> calManagerCollaborator = new List<Collaborator__c>();

        for (Collaborator__c newCollaborator : (List<Collaborator__c>)Trigger.new) {
            if (!AlreadyUsed.isUsed('TR020_Collaborator.applyUpdateRules', newCollaborator.id)) {
                Collaborator__c oldCollaborator = oldCollaborators == null ? null : oldCollaborators.get(newCollaborator.id);

                /* Manager */
                if (Trigger.isBefore && String.isNotBlank(newCollaborator.employedBy__c) && String.isNotBlank(newCollaborator.job__c)
                    && (Trigger.isInsert || (Trigger.isUpdate && (newCollaborator.employedBy__c != oldCollaborator.employedBy__c || newCollaborator.job__c != oldCollaborator.job__c || ( newCollaborator.manager__c != oldCollaborator.manager__c && String.isNotBlank(oldCollaborator.manager__c) )
                            || ( newCollaborator.stageName__c != oldCollaborator.stageName__c && (newCollaborator.stageName__c == 'Provisionné' || newCollaborator.stageName__c == 'En cours') ) )
                            )
                        )
                    ) 
                {
                    calManagerCollaborator.add(newCollaborator);
                }
            }
        }

        // Calcul des managers
        if (!calManagerCollaborator.isEmpty()) {
            Map<String, Collaborator__c> managerMap = Utils_Collaborator.getManager(calManagerCollaborator, Date.today());
            if(managerMap != null) {
                for(Collaborator__c collab : calManagerCollaborator) {
                    collab.manager__c = (managerMap.get(collab.Id) != null) ? managerMap.get(collab.Id).Id : null;
                }
            }
        }
    }

    /**
    * @description Méthode exécutant les différentes méthode de MAJ asynchrone pour les collaborateurs
    * @param userContext Objet contexte de l'utilisateur courant
    */
    private static void applyAsyncUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        // A - Initialisation des données intermédiaires 
        List<Collaborator__c> newCollaborators = (List<Collaborator__c>)Trigger.new;
        Map<Id, Collaborator__c>  oldCollaborators = (Map<Id, Collaborator__c>)Trigger.oldMap;
        Boolean geoEnabled = PropertiesUtils.getBooleanValue('dqe.geocoder.enabled', false);
        List<Collaborator__c> geoCollaborator = new List<Collaborator__c>();

        if (Test.isRunningTest() || geoEnabled) {
            for (Collaborator__c newCollaborator : newCollaborators) {
                if (!AlreadyUsed.isUsed('TR020_Collaborator.applyAsyncUpdateRules', newCollaborator.id)) {
                    Collaborator__c oldCollaborator = oldCollaborators == null ? null : oldCollaborators.get(newCollaborator.id); 

                    // Géocodage
                    Boolean adresseModifiee = Trigger.isInsert ? true : (newCollaborator.street__c != oldCollaborator.street__c || newCollaborator.postalCode__c != oldCollaborator.postalCode__c 
                                                                        || newCollaborator.city__c != oldCollaborator.city__c || newCollaborator.country__c != oldCollaborator.country__c
                                                                        || newCollaborator.localisation__Latitude__s == null || newCollaborator.localisation__Longitude__s == null);

                    if (adresseModifiee && Trigger.isAfter) {
                        geoCollaborator.add(newCollaborator);
                    }
                }
            }
        }

        // B - Application des règles de mise à jour asynchrone 
        if (geoEnabled && !geoCollaborator.isEmpty()) {
            GeoUtils.updateCollaborators(geoCollaborator);
        }
    }
}