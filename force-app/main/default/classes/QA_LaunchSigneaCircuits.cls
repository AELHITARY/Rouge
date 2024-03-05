//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_LaunchSigneaCircuits
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 22/05/2017
//-- Version     : 1.3
//-- * 1.3 : Suppression du champ "Circuit de signature"
//-- * 1.2 : Correction des statuts Completed
//-- --------------------------------------------------------------------------------- --
public without sharing class QA_LaunchSigneaCircuits implements Queueable, Database.AllowsCallouts {
    Set<Id> quotesIdList;

    /**
    * @description Constructeur
    * @param quoteIds Liste des IDs des devis
    * @return QA_LaunchSigneaCircuits Classe Queueable 
    */
    public QA_LaunchSigneaCircuits(Set<Id> quoteIds) {
        this.quotesIdList = quoteIds;
    }

    /**
    * @description Exécution d'un circuit de signature 'Contrat' pour les devis
    * @param context Context classe Queueable 
    */
    public void execute(QueueableContext context) {
        System.debug('### DEBUT QA_LaunchSigneaCircuits');
        try {
            // Traitement
            for (Quote devis : [SELECT Id, circuitSignatureDevis__c, circuitSignatureDevis__r.Signea__Status__c,
                                    circuitSignatureContrat__c, circuitSignatureContrat__r.Signea__Status__c
                                    FROM Quote
                                    WHERE Id IN :quotesIdList]) {
                System.debug('## Id: ' + devis.Id);
                // Circuit de signature du contrat
                if((devis.circuitSignatureDevis__c != null 
                    && devis.circuitSignatureDevis__r.Signea__Status__c.equalsIgnoreCase('Completed')
                    && devis.circuitSignatureContrat__r.Signea__Status__c == 'Draft') || Test.isRunningTest()) 
                {
                    if(!AlreadyUsed.isUsed('QA_LaunchSigneaCircuits', devis.Id)) {
                        // Exécution du circuit
                        Signea.Signea_Entities_V2.SigneaServicesResult launchResult;
                        if(!Test.isRunningTest()) {
                            launchResult = Signea.Signea_API_V2.launchCircuit(devis.circuitSignatureContrat__c);
                            System.debug('## Result: ' + launchResult);
                        }
                        // Envoi email si erreur
                        if ((!('000'.equalsIgnoreCase(launchResult.errorCode))) || Test.isRunningTest()) {
                            EmailUtils.reportException('[KUBE] Erreur exécution signature électronique contrat', 
                                'Erreur lors de l\'exécution du circuit pour le devis '+devis.Id+'\nCode: '+launchResult.errorCode+'\nRésultat: '+launchResult);
                        }
                    }
                }
            }
            System.debug('### FIN QA_LaunchSigneaCircuits');
        } catch (Exception e) {
            System.debug('ERREUR # Signea : execute (' + e.getMessage() + ' ' + e.getTypeName() + ') Ligne : '  + String.valueOf(e.getLineNumber()) + ' !)');
            EmailUtils.reportException('[KUBE] Erreur exécution signature électronique contrat', e);
        }
    }
}