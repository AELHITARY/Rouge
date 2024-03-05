//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_RefundRequestPDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/04/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_RefundRequestPDF {
    public AccountingPiece__c refundPiece { get; set; }
    public String adresseChantier { get; set; }
    public String adresseClient { get; set; }
    
    /**
    * @description Constructeur
    * @return Ctrl_RefundRequestPDF
    */
    public Ctrl_RefundRequestPDF() {
        refundPiece = new AccountingPiece__c();

        String param = ApexPages.currentPage().getParameters().get('accPieceId');
        System.debug('## accPieceId: ' + param);      
        String param2 = ApexPages.currentPage().getParameters().get('accPiece');
        System.debug('## accPiece: ' + param2);

        if(String.isNotBlank(param)) {  
            // Récupération infos de la pièces
            List<AccountingPiece__c> accountPieceList = [SELECT Id, Name, order__r.OrderNumber, order__r.amount__c,
                                                                account__r.Name, account__r.rue__c,account__r.codePostal__c, account__r.ville__c, 
                                                                order__r.chantier__r.rue__c, order__r.chantier__r.codePostal__c, order__r.chantier__r.ville__c,
                                                                creditMemo__r.creditMemoReference__c, creditMemo__r.creditMemoDate__c, creditMemo__r.amount__c,
                                                                paymentMethod__c, paymentMethod__r.Name, refundReason__c, refundReason__r.Name,
                                                                inputEntity__c, inputEntity__r.Name, CreatedBy.Name, CreatedDate, pieceDate__c, amount__c
                                                    FROM AccountingPiece__c WHERE Id = :param];
            System.debug('## Taille: ' + accountPieceList.size());
            // Formatage des résultats pour l'export
            if(!accountPieceList.isEmpty()) {
                refundPiece = accountPieceList[0];
            } else if(String.isNotBlank(param2)) {
                refundPiece = (AccountingPiece__c)JSON.deserialize(param2, AccountingPiece__c.class);
            }
            adresseClient = refundPiece.account__r.rue__c+' - '+refundPiece.account__r.codePostal__c+' '+refundPiece.account__r.ville__c;
            adresseChantier = refundPiece.order__r.chantier__r.rue__c+' - '+refundPiece.order__r.chantier__r.codePostal__c+' '+refundPiece.order__r.chantier__r.ville__c;
            System.debug('## refundPiece: ' + refundPiece);
        }
    }
    
    public Double offset{get{
        //Milliseconds to Day
        return UserInfo.getTimeZone().getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
    }}
}