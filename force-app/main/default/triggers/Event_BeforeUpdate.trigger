trigger Event_BeforeUpdate on Event (before update) {
    UserContext context = UserContext.getContext();

    if(context == null || !context.canByPassWorkflowRules()) {
        TR020_Event.applyUpdateRules(context);
    }

    if(context == null || !context.canByPassTrigger('TR022_Event')) {
        List<Event> TR022 = new List<Event>{};
        Id RT_RDVCommercial = DAL.getRecordTypeIdByDevName('Event', Constants.ACTIVITE_COMMERCIALE_RT);
        for(Integer i = (Trigger.new.size()-1); i >=0 ; i--) {
            // Si le RDV est activité commerciale
            if(Trigger.new[i].RecordTypeId == RT_RDVCommercial) {
                UserContext userOwner = UserContext.getContext(Trigger.new[i].OwnerId);
                if(context.isCallUser() && Trigger.new[i].OwnerId != Trigger.old[i].OwnerId) {
                    TR022.add(Trigger.new[i]);
                } else if(context.isSaleUser()) {
                    TR022.add(Trigger.new[i]);
                } else if(userOwner.isSaleUser()) {
                    TR022.add(Trigger.new[i]);
                }
            }
        }

        if(!TR022.isEmpty()) {
            TR022_Event.changeEventAndOppOwner(TR022, context);
        }
    }
}