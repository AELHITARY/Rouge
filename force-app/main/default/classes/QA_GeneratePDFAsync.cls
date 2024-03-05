//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_GeneratePDFAsync 
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 16/01/2023
//-- Version     : 1.0
//-- Description : Classe pour générer des PDF via Merkure en asynchrone. Permet de contourner la limite des 6Mo
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class QA_GeneratePDFAsync implements Queueable, Database.AllowsCallouts {
    public String recordType;
    public String recordId;
    public String filename;
    public String docType;

    /**
    * @description Constructeur
    * @param recordType Type de l'enregistrement
    * @param recordId Id de l'enregistrement
    * @param filename Nom du fichier PDF
    * @param docType Type du document PDF à générer
    * @return Contexte du job Queueable
    */
    public QA_GeneratePDFAsync(String recordType, String recordId, String filename, String docType) {
        this.recordType = recordType; 
        this.recordId = recordId; 
        this.filename = filename; 
        this.docType = docType; 
    }

    /**
    * @description Fonction principal d'exécution du job Queueable
    * Méthode asynchrone pour générer des PDF via Merkure en asynchrone et créer une notification.
    * @param context Context job Queueable
    */
    public void execute(QueueableContext context) {
        System.debug('### DEBUT QA_GeneratePDFAsync.execute()');  
        System.debug('## recordType: '+recordType);    
        System.debug('## recordId: '+recordId); 
        System.debug('## filename: '+filename); 
        System.debug('## docType: '+docType); 

        try {
            //* Génération du PDF
            // PDF pour Devis CPQ
            if(this.recordType == 'Quote') {
                LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDF(this.recordId, this.filename, this.docType);
            } else if(this.recordType == 'Invoice') {
                LWC_InvoiceGeneratePDF.renderDocumentPDFAsync(this.recordId, this.filename, this.docType);
            }

            //* Génération de la notification
            // Récupération du type de notification
            CustomNotificationType notificationType =  [SELECT Id, DeveloperName FROM CustomNotificationType LIMIT 1];            
            // Création de la notification
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            // Contenu
            notification.setTitle('Génération fichier PDF');
            notification.setBody('Le fichier PDF '+this.filename+' est disponible dans l\'onglet "Fichier" de l\'enregistrement.');
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(this.recordId);
            // Envoi de la notification
            Set<String> recipientsIds = new Set<String>();
            recipientsIds.add(UserInfo.getUserId());
            notification.send(recipientsIds);
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }
        System.debug('### FIN QA_GeneratePDFAsync.execute()');  
    }
}