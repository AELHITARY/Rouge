trigger Event_BeforeInsert on Event (before insert) {
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
                // Si RDV sur projet et utilisateur du CALL, on applique le référent
                String eventWhatID = Trigger.new[i].WhatId;
                if (String.isNotBlank(eventWhatID)){
                    if(Trigger.new[i].WhoId != null && eventWhatID.substring(0,3) == '006') {
                        TR022.add(Trigger.new[i]);
                    }
                }
            }
        }

        if(!TR022.isEmpty()) {
            TR022_Event.changeEventAndOppOwner(TR022, context);
        }
    }
}