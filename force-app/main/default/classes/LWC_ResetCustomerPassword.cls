//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_ResetCustomerPassword
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 01/12/2020
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public with sharing class LWC_ResetCustomerPassword {
    
    /**
    * @description Réinitialisation du mot de passe client
    * @param objectName Nom API de l'objet
    * @param recordId Id de l'enregistrement
    * @return Texte retournant le message d'erreur ou le message OK
    */
    @AuraEnabled
    public static String resetCustomerPassword(String objectName, String recordId){
        System.debug('### DEBUT LWC_ResetCustomerPassword.resetCustomerPassword'); 
        System.debug('## objectName: '+objectName); 
        System.debug('## recordId: '+recordId); 
        String result = null;
        Account accToReset;

        try {
            if(String.isNotBlank(recordId) && String.isNotBlank(objectName)) {  
                // Récupération des noms des champs localisation
                if(objectName == 'Account') {
                    accToReset = [SELECT Id, Type FROM Account WHERE Id = :recordId LIMIT 1];
                }
                if(objectName == 'Contact') {
                    Contact cont = [SELECT Id, AccountId FROM Contact WHERE Id = :recordId LIMIT 1];
                    accToReset = [SELECT Id, Type FROM Account WHERE Id = :cont.AccountId LIMIT 1];
                }  
            }

            // Affichage message d'erreur si compte n'est pas de type "Client" ou "Ex-client"
            if(!(accToReset.Type==Constants.ACCOUNT_TYPE_CLIENT || accToReset.Type==Constants.ACCOUNT_TYPE_EXCLIENT)) {
                result = Label.acc_error_CustomerPasswordClientOnly;
            } else {
                // Demande d'envoi du mot de passe
                Boolean enablePasswordEmail = (PropertiesUtils.getBooleanValue('espaceclient.email.password', false)) ? true : false;
                ID jobID = system.enqueueJob(new QA_GenerateAccountPassword(new List<Account>{accToReset}, enablePasswordEmail, false, false));
                System.debug('## Appel du job de réinitialisation du mot de passe : ' + jobID);
                // Retour OK
                result = Label.acc_msg_ConfirmResetCustomerPassword;
            }
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('### FIN LWC_ResetCustomerPassword.resetCustomerPassword'); 
        return result;
    }
}