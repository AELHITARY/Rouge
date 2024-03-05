//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_CalculateOrderStatusGC
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/10/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_CalculateOrderStatusGC {

/**
* @description Méthode pour exécuter le processus de calcul du statut GC sur une commande client depuis un Flow ou Process Builder
* @param request Liste des paramètres d'entrée
*/
@InvocableMethod(callout=true label='Commande - Calcul Statut GC' description='Exécute le processus de calcul du statut GC sur une commande client')
public static void calculateOrderStatusGC(List<FlowInputParameters> request) {        
    System.debug('### DEBUT IV_CalculateOrderStatusGC.calculateOrderStatusGC');
    
    try {
        if(!request.isEmpty()) {
            // Récupération des paramètres d'entrée
            FlowInputParameters param = request[0];
            // Gestion des erreurs
            if(String.isBlank(param.recordId)) {
                throw new FlowActionException('Le paramètre recordId est vide');
            }
            
            // Exécution calcul
            Set<Id> ordersId = new Set<Id>();
            ordersId.add(param.recordId);
            System.enqueueJob(new QA_UpdateOrderStatusGC(ordersId));
        }

        System.debug('### FIN IV_CalculateOrderStatusGC.calculateOrderStatusGC');
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