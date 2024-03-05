public class TR007_SetLastMeeting {
  public static void execute(UserContext context) {
    Set<Id> idSet = new Set<Id>();
    Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
    Schema.DescribeSObjectResult r =  gd.get('Opportunity').getDescribe();
    string OppPrefix =  r.getKeyPrefix();
    
    List<Event> eventList = (List<Event>) (trigger.isDelete ?  trigger.old : trigger.new);
    for(Event event:eventList){
      String WhatPrefix = event.WhatId;
      if(((trigger.isUpdate && event.StartDateTime != ((Event) Trigger.oldMap.get(event.id)).StartDateTime) || trigger.isInsert || trigger.isDelete) &&
            (WhatPrefix != null && WhatPrefix.subString(0,3)==OppPrefix) )
        idSet.add(event.WhatId);
    }
    
    if (!idSet.isEmpty())
      setLastMeeting(idSet);  
  }
  
  private static void setLastMeeting(set<Id> idSet) {
    List<Opportunity> oppList = [Select o.Account.PersonContactId,Dernier_RDV__c, o.AccountId,(Select e.StartDateTime,e.WhoId, e.WhatId From Events e where StartDateTime<=:datetime.now()  ORDER BY StartDateTime DESC  limit 1) From Opportunity o where Id IN:idSet];
    for(Opportunity opp:oppList) {
      if(opp.Events.size()>0)
        opp.Dernier_RDV__c = opp.Events[0].StartDateTime;
      else 
        opp.Dernier_RDV__c = null;
    }
    update oppList;
  }
}