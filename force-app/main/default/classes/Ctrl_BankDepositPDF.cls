//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_BankDepositPDF
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/04/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_BankDepositPDF {
    public List<AccountingPiece__c> listAccPieceExport1 { get; set; }
    public List<AccountingPiece__c> listAccPieceExport2 { get; set; }
    public List<AccountingPiece__c> listAccPieceExport3 { get; set; }
    public Decimal totalPiecesAmount { get; set; }
    public Integer nbPieces { get; set; }
    public String brm { get; set; }
    
    /**
    * @description Constructeur
    * @return Ctrl_BankDepositPDF
    */
    public Ctrl_BankDepositPDF() {
        listAccPieceExport1 = new List<AccountingPiece__c>();
        listAccPieceExport2 = new List<AccountingPiece__c>();
        listAccPieceExport3 = new List<AccountingPiece__c>();

        String param = ApexPages.currentPage().getParameters().get('ids');
        brm = ApexPages.currentPage().getParameters().get('brm');
        System.debug('## param: ' + param);        
        
        if(String.isNotBlank(param)) {
            List<String> accPieceIds = param.split(',');
            
            // Récupération infos des pièces
            List<AccountingPiece__c> accountPieceList = [SELECT Id, Name, order__r.OrderNumber, account__r.Name, pieceDate__c, 
                                                    order__r.EffectiveDate, amount__c, externalBank__c, externalReference__c,
                                                    bankRemittanceNumber__c FROM AccountingPiece__c WHERE Id IN :accPieceIds 
                                                    ORDER BY order__r.OrderNumber];
            System.debug('## Taille liste export des pièces: ' + accountPieceList.size());
            System.debug('## accountPieceList: ' + accountPieceList);
            
            // Formatage des résultats pour l'export
            totalPiecesAmount = 0;
            nbPieces = 0;
            for(AccountingPiece__c accPiece : accountPieceList) {
                nbPieces++;
                if(nbPieces <= 1000) {
                    listAccPieceExport1.add(accPiece );
                } else if (nbPieces > 1000 && nbPieces <= 2000) {
                    listAccPieceExport2.add(accPiece );
                } else if (nbPieces > 2000 && nbPieces <= 3000) {
                    listAccPieceExport3.add(accPiece );
                }
                if(accPiece.amount__c != null) {
                    totalPiecesAmount = totalPiecesAmount + accPiece.amount__c;
                }
            }
            system.debug('## Taille liste export 1: ' + listAccPieceExport1.size());
            system.debug('## Taille liste export 2: ' + listAccPieceExport2.size());
            system.debug('## Taille liste export 3: ' + listAccPieceExport3.size());
        }
    }
    
    public Double offset{get{
        //Milliseconds to Day
        return UserInfo.getTimeZone().getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
    }}
}