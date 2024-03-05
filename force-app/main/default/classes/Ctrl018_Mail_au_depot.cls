//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Ctrl018_Mail_au_depot
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 18/12/2019
//-- Version     : 1.1
//-- * 1.1 : KPKCRM_RQM-177 : Mise en place des nouveaux types d'enregistrement des comptes
//-- --------------------------------------------------------------------------------- --
public with sharing class Ctrl018_Mail_au_depot {

    private Id RT_RECLAMATION = DAL.getRecordTypeIdByDevName('Case', Constants.REQUETE_RECLAMATION_RT);
    private Id RT_AccEntity = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
    public String errorMsg {get; private set;}
    public Case myCase {get;private set;}
    private String depotName;

    public Pagereference init(){
        if(Apexpages.currentPage().getParameters().get('id') != null){
            string caseId = Apexpages.currentPage().getParameters().get('id');

            // Récupération information case
            myCase = [Select Id, RecordTypeId, Depot__c From Case where Id = :caseId];

            if(!StringUtils.isEmpty(myCase.Depot__c)) {
                depotName = '%DÉPÔT ' + myCase.Depot__c + '%';
                List<Account> depotList = [Select Id from Account where RecordTypeId = :RT_AccEntity and Name like :depotName limit 1];
                if(depotList.size() > 0) {
                    Account depot = depotList[0];
                    if (myCase.recordTypeId == RT_RECLAMATION)
                      return new PageReference('/_ui/core/email/author/EmailAuthor?p2_lkid='+ depot.Id +'&rtype=003&p3_lkid='+caseId+'&p4=reclamation@kpark.fr&p26=reclamation@kpark.fr&retURL=/'+caseId);
                    else
                      return new PageReference('/_ui/core/email/author/EmailAuthor?p2_lkid='+ depot.Id +'&rtype=003&p3_lkid='+caseId+'&retURL=/'+caseId);
                }
            }
        }
        return null;
    }

}