//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_OdigoSendCallback_Opportunity
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 08/02/2019
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_OdigoSendCallback_Opportunity {

    /**
    * @description Méthode pour envoyer une tâche d'appel (callback) à Odigo
    * @param contratsToCheck Liste des projets
    */
    @InvocableMethod(label='Envoi callback Survey Opp a Odigo' description='Envoi d\'un callback a Odigo pour le questionnaire de SATcontact')
    public static void IV_OdigoSendCallback_Opportunity(List<Opportunity> oppsToCheck) {
        List<String> oppsId = new List<String>();
        
        // ODIGO VARIABLES
        String odigoCampaignName = PropertiesUtils.getStringValue('prosodie.odigo.survey', 'SATCONTACT');

        // Récupération ID des projets et appel méthode async
        for(Opportunity opp : oppsToCheck) {
            oppsId.add(opp.Id);
        }

        // Appel de la fonction asynchrone
        System.enqueueJob(new QA_OdigoSendCallback(oppsId, odigoCampaignName));
    }   
}