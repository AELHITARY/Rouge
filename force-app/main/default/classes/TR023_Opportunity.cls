public class TR023_Opportunity
{
  public static void associerALaCampagne(UserContext context) {
    if (!Trigger.isExecuting)
      return;
      
    List<Opportunity> opportunities = (List<Opportunity>) Trigger.new;
      
    Set<ID> campaignIds = new Set<ID>();
    Set<ID> accountIds  = new Set<ID>();
 

    List<CampaignMember> membersToInsert = new List<CampaignMember>();

    for (Opportunity opportunity : opportunities)
      if (opportunity.campaignId != null) {
        campaignIds.add(opportunity.campaignId);
        if (opportunity.accountId != null)
          accountIds.add(opportunity.accountId);
        if (opportunity.autreCompte__c != null)
          accountIds.add(opportunity.autreCompte__c);
      }

    if(!campaignIds.isEmpty()) {
      Map<Id, Contact>     contacts = new Map<Id, Contact>([SELECT Id, accountId FROM Contact WHERE accountId IN :accountIds]);
      List<CampaignMember> members  = [SELECT Id FROM CampaignMember WHERE contactId IN :contacts.keySet() AND campaignId IN :campaignIds];

      for (Opportunity opportunity : opportunities) {
        if (opportunity.campaignId != null) {
          /* Pour chaque contact associé à un compte (standard ou autre compte) du projet avec campagne, il faut vérifier
             que le contact est un membre de la campagne. Si tel n'est pas le cas, il faut alors l'insérer comme membre. */
          for (Contact contact : contacts.values()) { // Récupération des contacts des comptes du projet
            if(contact.accountId == opportunity.accountId || contact.accountId == opportunity.autreCompte__c) {
              // Vérifie de son existence comme membre de campagne
              Boolean found = false;
              for (CampaignMember member : members) {
                if (member.campaignId == opportunity.campaignId && member.contactId == contact.id) {
                  found = true;
                  break;
                }
              }
              // Non existant, alors insertion comme membre de la campagne
              if (!found) {
                CampaignMember member = new CampaignMember(campaignId = opportunity.campaignId,
                                                           contactId = contact.id,
                                                           status='Envoyé');
                membersToInsert.add(member);
              }
            }
          }
        }
      }

      if (!membersToInsert.isEmpty())
        insert membersToInsert;
    }
  }
}