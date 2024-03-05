//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : IV_CreateAndSendInvoice
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 26/04/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class IV_CreateAndSendInvoice {

    /**
    * @description Méthode pour envoyer un générer et envoyer le PDF de la facture depuis un Flow ou Process Builder
    * @param request Liste des paramètres d'entrée
    */
    @InvocableMethod(callout=true label='Envoi PDF facture' description='Exécute les processus de génération et d\'envoi du PDF de la facture')
    public static void createAndSendInvoice(List<FlowInputParameters> request) {        
        System.debug('### DEBUT IV_CreateAndSendInvoice.createAndSendInvoice');
        String fileName;
        Date dateToUse;
        
        try {
            if(!request.isEmpty()) {
                // Récupération des paramètres d'entrée
                FlowInputParameters param = request[0];
                // Gestion des erreurs
                if(String.isBlank(param.recordId)) {
                    throw new FlowActionException('Le paramètre recordId est vide');
                }
                
                // Défini le nom du fichier
                Invoice__c invoice = [SELECT invoiceReference__c, Id, invoiceDate__c, Name FROM Invoice__c WHERE Id=: param.recordId];
                if(invoice.invoiceDate__c != null) {
                    dateToUse = invoice.invoiceDate__c;
                } else {
                    dateToUse = Date.today();
                }
                String dateFormated = DateTime.newInstance(dateToUse.year(),dateToUse.month(),dateToUse.day()).format('yyyy/MM/dd');
                if(param.docType != null && param.docType == 'Facture') {
                    fileName = 'Facture ' + invoice.invoiceReference__c + ' ' + dateFormated;
                } else {
                    fileName = 'Acompte ' + invoice.Name + ' ' + dateFormated;
                }
            
                // Exécution de la génération et de l'envoie
                if(param.generatePDF != null && param.generatePDF) {
                    LWC_InvoiceGeneratePDF.renderDocumentPDF(param.recordId, fileName, param.docType);
                }
                if((param.sendPDF == null || param.sendPDF) && !Test.isRunningTest()){	
                    LWC_InvoiceSendToCustomer.sendInvoiceToCustomer(param.recordId, param.docType);
                }
            }

            System.debug('### FIN IV_CreateAndSendInvoice.createAndSendInvoice');
        } catch(Exception e){
            throw e;
        }
    }
    
    // Input parameters for the Apex action 
    public class FlowInputParameters{
        @InvocableVariable(label='Id de la facture' required=true)
        public String recordId;        
        @InvocableVariable(label='Générer facture')
        public Boolean generatePDF; 
        @InvocableVariable(label='Type du document')
        public String docType;
        @InvocableVariable(label='Envoi du document')
        public Boolean sendPDF;
    }
    
    public class FlowActionException extends Exception {}
    
}