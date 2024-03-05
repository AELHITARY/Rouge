//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_KMDCEinstein
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 22/02/2023
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_KMDCEinstein {

/**
* @description Méthode pour exécuter le processus de génération de KMDC sur une commande client depuis un Flow ou Process Builder
* @param request Liste des paramètres d'entrée
*/
@InvocableMethod(callout=true label='Commande - Génération KMDC' description='Exécute le processus de génération de KMDC sur une commande client')
public static void generateKMDC(List<FlowInputParameters> request) {        
    System.debug('### DEBUT IV_KMDCEinstein.generateKMDC');
    
    try {
        if(!request.isEmpty()) {
            // Récupération des paramètres d'entrée
            FlowInputParameters param = request[0];
            // Gestion des erreurs
            if(String.isBlank(param.recordId)) {
                throw new FlowActionException('Le paramètre recordId est vide');
            }
            
            // Exécution calcul
            List<Order> recordsList = [SELECT Id FROM Order WHERE Id =:param.recordId];
            System.enqueueJob(new QA_KMDCEinstein('Quote', recordsList));
        }

        System.debug('### FIN IV_KMDCEinstein.generateKMDC');
    } catch(Exception e){
        throw e;
    }
}

// Input parameters for the Apex action 
public class FlowInputParameters{
    @InvocableVariable(label='Id de la commande' required=true)
    public String recordId;        
}

public class FlowActionException extends Exception {}

}