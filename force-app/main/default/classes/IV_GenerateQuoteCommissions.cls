//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_GenerateQuoteCommissions
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 10/02/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public class IV_GenerateQuoteCommissions {
            
    @InvocableMethod(Label='Générer les commissions VRP' Description='Générer les commissions VRP')
    public static void calculateRemVRP(List<FlowInputParameters> inputList) {
        System.debug('### DEBUT IV_GenerateQuoteCommissions.calculateRemVRP');
        
        // Sauvegarde
        System.Savepoint sp = Database.setSavepoint();

        try{
            List<Id> quoteIds = inputList[0].quoteIds;
            if(quoteIds == null || quoteIds.isEmpty()) {                
                throw new FlowActionException('Ids inexistants');
            }
            
            System.debug('## Button launch remVRP commissions calculation for quotes ' + quoteIds);
            QA_QuoteProcessCommissions job = new QA_QuoteProcessCommissions(quoteIds);
            System.enqueueJob(job);
            
            System.debug('### FIN IV_GenerateQuoteCommissions.calculateRemVRP');
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /* Input parameters for the Apex action */
    public class FlowInputParameters{
        @InvocableVariable(label='Id des devis' required = true )
        public List<Id> quoteIds;
    }

    public class FlowActionException extends Exception {}
}