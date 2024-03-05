//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : LWC_RefundRequestWizard
//-- Modifie par : SOPRA STERIA
//-- Modifie le  : 13/05/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class LWC_RefundRequestWizard {

    /**
    * @description Récupération du mode de réglement par défaut
    * @return Mode de réglement par défaut
    */
    @AuraEnabled(cacheable = true)
    public static Referencial__c getDefaultPaymentMethod(){
       System.debug('### DEBUT LWC_RefundRequestWizard.getDefaultPaymentMethod'); 
       Referencial__c result = null;

        try {
            String refDefaultValue = PropertiesUtils.getStringValue('ref.paymentMethodBankCheck.code', 'PAY-0004');
            String refRTId = DAL.getRecordTypeIdByDevName('Referencial__c', 'PaymentMethod'); 
            for(Referencial__c ref : [SELECT  Id, Name, requiredExternalBankAccount__c, minPayableAmount__c, maxPayableAmount__c
                                        FROM Referencial__c 
                                        WHERE RecordTypeId = :refRTId AND KparKReference__c = :refDefaultValue LIMIT 1]) {     
                result = ref;
            }  
            System.debug('## result: '+result); 
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_RefundRequestWizard.getDefaultPaymentMethod'); 
        return result;
    }

    /**
    * @description Création de la piece comptable de demande de remboursement
    * @param creditMemoId Id de l'avoir
    * @param refundReasonId Id du motif de remboursement
    * @param inputEntityId Id de l'entité
    * @param paymentMethodId Id du mode de réglement
    * @param accountingDate Date comptable
    * @param pieceAmount Montant
    * @return Id du PDF
    */
    @AuraEnabled
    public static String createRefundRequestPiece(String creditMemoId, String refundReasonId, String inputEntityId, 
                                                    String paymentMethodId, Date pieceDate, Decimal pieceAmount) {
        System.debug('### DEBUT LWC_RefundRequestWizard.createRefundRequestPiece'); 
        System.debug('## creditMemoId: '+ creditMemoId);
        System.debug('## refundReasonId: '+ refundReasonId);
        System.debug('## inputEntityId: '+inputEntityId);
        System.debug('## paymentMethodId: '+paymentMethodId);
        System.debug('## pieceDate: '+ pieceDate);
        String result = null; 

        try{
            if(String.isNotBlank(creditMemoId)){
                // Récupération des infos de l'avoir
                CreditMemo__c credMemo = [SELECT Id, customerOrder__c, customerOrder__r.serviceEntity__c, refundReason__c, 
                                            refundReason__r.refundType__c FROM CreditMemo__c WHERE Id = :creditMemoId];
                // Récupération des infos du motif de remboursement
                Referencial__c refundRes = [SELECT Id, refundType__c FROM Referencial__c WHERE Id = :refundReasonId];
                System.debug('## RefundType: '+refundRes.refundType__c);
                // Récuéparation du RT
                String accPieceRTId = DAL.getRecordTypeIdByDevName('AccountingPiece__c', refundRes.refundType__c); 
                System.debug('## accPieceRTId: '+accPieceRTId);

                // Création de la piece
                AccountingPiece__c accPiece = new AccountingPiece__c(
                    RecordTypeId = accPieceRTId,
                    order__c = credMemo.customerOrder__c,
                    orderEntity__c = credMemo.customerOrder__r.serviceEntity__c,
                    inputEntity__c = inputEntityId,
                    creditMemo__c = credMemo.Id,
                    pieceDate__c = pieceDate,
                    refundReason__c = refundReasonId,
                    amount__c = pieceAmount,
                    paymentMethod__c = paymentMethodId
                );
                System.debug('## Accounting Piece: '+ accPiece);
                insert accPiece;

                // Création du PDF
                result = createDocumentPDF(accPiece.Id, credMemo.Id);
            }
        }
        catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_RefundRequestWizard.createRefundRequestPiece');
        return result;
         
    }

    /**
    * @description Fonction pour générer le document PDF 
    * @param accPieceId Id de la pièce
    * @param creditMemoId Id de l'avoir
    * @return String Id de la pièce jointe (ContentDocument)
    */
    @AuraEnabled
    public static String createDocumentPDF(String accPieceId, String creditMemoId) {
        System.debug('### DEBUT LWC_RefundRequestWizard.createDocumentPDF');
        System.debug('## accPieceId: '+accPieceId);
        String result;

        try {        
            // DR / <n° avoir> / <yyyy/mm/dd>
            List<CreditMemo__c> credMemo = [SELECT Id, creditMemoReference__c FROM CreditMemo__c WHERE Id = :creditMemoId LIMIT 1]; 
            String dateFormated = DateTime.newInstance(Date.today().year(),Date.today().month(),Date.today().day()).format('yyyy/MM/dd');
            String filename = 'DR / '+credMemo[0].creditMemoReference__c+' / '+dateFormated+'.pdf';
            System.debug('## filename: '+filename);

            AccountingPiece__c refundPiece;
            List<AccountingPiece__c> accountPieceList = [SELECT Id, Name, order__r.OrderNumber, order__r.amount__c,
                                                                account__r.Name, account__r.rue__c,account__r.codePostal__c, account__r.ville__c, 
                                                                order__r.chantier__r.rue__c, order__r.chantier__r.codePostal__c, order__r.chantier__r.ville__c,
                                                                creditMemo__r.creditMemoReference__c, creditMemo__r.creditMemoDate__c, creditMemo__r.amount__c,
                                                                paymentMethod__c, paymentMethod__r.Name, refundReason__c, refundReason__r.Name,
                                                                inputEntity__c, inputEntity__r.Name, CreatedBy.Name, CreatedDate, pieceDate__c, amount__c
                                                    FROM AccountingPiece__c WHERE Id = :accPieceId];

            // Creation PDF
            Blob documentBlob;            
            PageReference pagePDF = Page.VF_RefundRequestPDF;
            pagePDF.getParameters().put('accPieceId', accPieceId);
            if(!accountPieceList.isEmpty()) {
                refundPiece = accountPieceList[0];
                System.debug('## refundPiece: '+refundPiece);
                pagePDF.getParameters().put('accPiece', JSON.serialize(refundPiece));
            }
            if (Test.isRunningTest()) {
                documentBlob = Blob.valueof('test');
            } else {
                documentBlob = pagePDF.getContentAsPDF();
            }
            // Lien du PDF avec l'avoir
            result = Utils_APIMerkure.createContentDocument(creditMemoId, filename, documentBlob, 'Demande de remboursement');  
        } catch(Exception e) {
            System.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            throw generateAuraException(e.getMessage());
        }
        System.debug('### FIN LWC_RefundRequestWizard.createDocumentPDF');
        return result;
    }

    /**
    * @description Fonction pour construire le message d'exeption correctement (sinon pas de message)
    * https://salesforce.stackexchange.com/questions/122657/testing-aurahandledexceptions
    * @param msg Message d'erreur
    * @return AuraHandledException Exception avec le message d'erreur
    */
    public static AuraHandledException generateAuraException(String msg){
        System.debug('ERREUR : ' + msg);
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }
}