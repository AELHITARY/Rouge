//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_OdigoSendCallback
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 10/01/2019
//-- Version     : 1.0
//-- * 1.0 : Initialisation
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_OdigoSendCallback {
    
    /**
    * @description Méthode pour envoyer une tâche d'appel (callback) à Odigo
    * @param contratsToCheck Liste des contrats
    */
    @InvocableMethod(label='Envoi callback Survey a Odigo' description='Envoi d\'un callback a Odigo pour le questionnaire de satisfaction')
    public static void sendSurveyCallBack(List<KContrat__c> contratsToCheck) {
        List<String> contratsId = new List<String>();
        // ODIGO VARIABLES
        String odigoCampaignName = PropertiesUtils.getStringValue('prosodie.odigo.survey', 'SATCLI');
        // Récupération ID des contrats et appel méthode async
        for(KContrat__c contrat : contratsToCheck)
            contratsId.add(contrat.Id);
        // Appel de la fonction asynchrone
        System.enqueueJob(new QA_OdigoSendCallback(contratsId, odigoCampaignName));
    }   
}