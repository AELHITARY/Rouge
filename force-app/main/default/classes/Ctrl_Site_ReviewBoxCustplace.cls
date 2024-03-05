//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl_Site_ReviewBoxCustplace
//-- Modifié par : SOPRA STERIA
//-- Modifie le  : 09/03/2022
//-- Version     : 1.0
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class Ctrl_Site_ReviewBoxCustplace {
    // Parametres
    public String objectId {get; set;}
    public Set<String> magNameList {get; set;}


    // ERRORS
    public Utils_logger log {get; set;}
    public String titre {get; set;}
    public String avis {get; set;}
    public String nom {get; set;}
    public String email {get; set;}
    public String dateAvis {get; set;}
    public String magasin {get; set;}

    /**
    * @description Constructeur
    * @return Ctrl_Site_Questionnaire_NPS 
    */
    public Ctrl_Site_ReviewBoxCustplace() {
        log = new Utils_logger();
        objectId = ApexPages.currentPage().getParameters().get('oId');
        titre = ApexPages.currentPage().getParameters().get('titre');
        avis = ApexPages.currentPage().getParameters().get('avis');
        magNameList = Constants.CUSTPLACE_MAG_ID.keySet();
        List<KContrat__c> contrat = [SELECT Id, nomCompte__c, emailCompte__c, magasin__c FROM KContrat__c WHERE id = :objectId LIMIT 1];
        if(!contrat.isEmpty()) {
            nom = contrat[0].nomCompte__c;
            email = contrat[0].emailCompte__c;
            Datetime todayDate = Date.today();
            dateAvis = String.valueOf(todayDate.format('dd/MM/yyyy'));
            List<Sectorisation__c> secto = [SELECT Id, codeMagasin__c, libelleMagasin__c FROM Sectorisation__c WHERE codeMagasin__c = :contrat[0].magasin__c LIMIT 1];
            system.debug('contrat[0].magasin__c : '+contrat[0].magasin__c);
            for(String magName : magNameList){
                system.debug('magName : '+magName);
                if(!secto.isEmpty() && magName.CONTAINS(secto[0].libelleMagasin__c)){
                    magasin = Constants.CUSTPLACE_MAG_ID.get(magName);
                } else if(!secto.isEmpty() && magName.CONTAINS(contrat[0].magasin__c)){
                    magasin = Constants.CUSTPLACE_MAG_ID.get(magName);
                }
            }
        }
    }
}