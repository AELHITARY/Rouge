//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_CalculateOrderStatusGC
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/10/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_CalculateAfterSalesServiceStatusGC {

    /**
    * @description Méthode pour exécuter le processus de calcul du statut GC sur un dossier SAV depuis un Flow ou Process Builder
    * @param request Liste des paramètres d'entrée
    */
    @InvocableMethod(callout=true label='Dossier SAV - Calcul Statut GC' description='Exécute le processus de calcul du statut GC sur un dossier SAV')
    public static void calculateAfterSalesServiceStatusGC(List<FlowInputParameters> request) {        
        System.debug('### DEBUT IV_CalculateAfterSalesServiceStatusGC.calculateAfterSalesServiceStatusGC');
        
        try {
            if(!request.isEmpty()) {
                // Récupération des paramètres d'entrée
                FlowInputParameters param = request[0];
                // Gestion des erreurs
                if(String.isBlank(param.recordId)) {
                    throw new FlowActionException('Le paramètre recordId est vide');
                }
                
                // Exécution calcul
                Set<Id> savId = new Set<Id>();
                savId.add(param.recordId);
                System.enqueueJob(new QA_UpdateAfterSalesServiceStatusGC(savId));
            }
    
            System.debug('### FIN IV_CalculateOrderStatusGC.calculateOrderStatusGC');
        } catch(Exception e){
            throw e;
        }
    }
    
    // Input parameters for the Apex action 
    public class FlowInputParameters{
        @InvocableVariable(label='Id du dossier SAV' required=true)
        public String recordId;        
    }
    
    public class FlowActionException extends Exception {}
    
    }