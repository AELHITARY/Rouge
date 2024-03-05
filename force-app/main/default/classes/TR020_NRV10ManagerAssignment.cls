/**
* @author Gregory Quinet
* @date 2020-07-27
* @description Manager Assignment validation class. Used to check validity of the manager assignment object before/after insert/update
**/
public class TR020_NRV10ManagerAssignment {
    
    /**
     * @author Gregory Quinet
     * @date 2020-07-27
     * @description Validate there is no concurrent assignment for the same manager or store and period
     **/
    public static void applyValidationRules() {
        NRV10ManagerAssignmentContext ctx = buildContext();

        //Parse all new assignments
        for (NRV10ManagerAssignment__c assignment : ctx.newAssignments) {
            Boolean hasEndDate = assignment.endDate__c != null;
            Boolean isRVJ = assignment.role__c == 'RVJ';
            Boolean isRV = assignment.role__c == 'RV';
            Integer rvjCount = isRVJ || isRV ? 1 : 0;

            //validate managers unicity
            if (ctx.managerAssignmentsMaps.containsKey(assignment.salesManager__c)) {
                for (NRV10ManagerAssignment__c assign : ctx.managerAssignmentsMaps.get(assignment.salesManager__c)) {
                    if ( ((assign.startDate__c < assignment.startDate__c && (assign.endDate__c == null || assign.endDate__c > assignment.startDate__c))
                            || (!hasEndDate && assign.startDate__c > assignment.startDate__c)
                            || (hasEndDate && assign.startDate__c > assignment.startDate__c && assign.startDate__c < assignment.endDate__c))
                            && assign.Id != assignment.Id ) {
                        System.debug('Found a matching manager assignment for the period');
                        System.debug('  -> startdate new: ' + assignment.startDate__c + ' VS old: ' + assign.startDate__c);
                        System.debug('  -> enddate new: ' + assignment.endDate__c + ' VS old: ' + assign.endDate__c);
                        System.debug('  -> manager new: ' + assignment.salesManager__c + ' VS old: ' + assign.salesManager__c);
                        System.debug('  -> replaced new: ' + assignment.replaced__c + ' VS manager old: ' + assign.salesManager__c);
                            assignment.AddError(System.Label.NRV10ManagerAssignmentValidationFailManager);
                    }
                }
            }

            //validate role unicity
            if (ctx.storesMaps.containsKey(assignment.store__c)) {
                for (NRV10ManagerAssignment__c assign : ctx.storesMaps.get(assignment.store__c)) {
                    if ( ((assign.startDate__c < assignment.startDate__c && (assign.endDate__c == null || assign.endDate__c > assignment.startDate__c))
                            || (!hasEndDate && assign.startDate__c > assignment.startDate__c)
                            || (hasEndDate && assign.startDate__c > assignment.startDate__c && assign.startDate__c < assignment.endDate__c))
                            && assign.Id != assignment.Id
                            && assign.store__c == assignment.store__c ) {
                        //In case the other manager assigned to the store is the replaced one, no error, but update it
                        System.debug('Found a matching store assignment for the period');
                        System.debug('  -> startdate new: ' + assignment.startDate__c + ' VS old: ' + assign.startDate__c);
                        System.debug('  -> enddate new: ' + assignment.endDate__c + ' VS old: ' + assign.endDate__c);
                        System.debug('  -> manager new: ' + assignment.salesManager__c + ' VS old: ' + assign.salesManager__c);
                        System.debug('  -> replaced new: ' + assignment.replaced__c + ' VS manager old: ' + assign.salesManager__c);

                        if ((isRV && assign.role__c == 'RVJ') || (isRVJ && assign.role__c == 'RV')) {
                            //If the assignment is a RV and the other is a RVJ (and so for RVJ and RV), it's ok,
                            // we can have a pair on a store.
                            System.debug('  -> RV+RVJ is allowed');
                            rvjCount++;
                        }
                        if ( ((isRVJ || isRV) && rvjCount > 2)
                                || (isRV && assign.role__c == 'RV')
                                || (isRVJ && assign.role__c == 'RVJ') ){
                            //if there is already a RV and a RVJ, error
                            if (assignment.replaced__c != assign.salesManager__c && assignment.salesManager__c != assign.replaced__c) {
                                System.debug('  -> real conflict');
                                assignment.AddError(System.Label.NRV10ManagerAssignmentValidationFailRole);
                            }
                        }
                    }
                }
            }
        }
    }


    /**
     * @author Gregory Quinet
     * @date 2020-09-14
     * @description Update replaced managers assignments to set end dates or adjust start date
     **/
    public static void applyUpdateRules() {
        NRV10ManagerAssignmentContext ctx = buildContext();

        List<NRV10ManagerAssignment__c> complementaryUpdates = new List<NRV10ManagerAssignment__c>();
        List<NRV10ManagerAssignment__c> complementaryDeletes = new List<NRV10ManagerAssignment__c>();
        //Parse all new assignments
        for (NRV10ManagerAssignment__c assignment : ctx.newAssignments) {
            Boolean hasEndDate = assignment.endDate__c != null;

            //validate role unicity
            if (ctx.storesMaps.containsKey(assignment.store__c)) {
                for (NRV10ManagerAssignment__c assign : ctx.storesMaps.get(assignment.store__c)) {
                    if ( ((assign.startDate__c < assignment.startDate__c && (assign.endDate__c == null || assign.endDate__c > assignment.startDate__c))
                            || (!hasEndDate && assign.startDate__c > assignment.startDate__c)
                            || (hasEndDate && assign.startDate__c > assignment.startDate__c && assign.startDate__c < assignment.endDate__c))
                            && assign.Id != assignment.Id) {
                        //In case the other manager assigned to the store is the replaced one, no error, but update it
                        System.debug('Found a matching store assignment for the period');
                        System.debug('  -> startdate new: ' + assignment.startDate__c + ' VS old: ' + assign.startDate__c);
                        System.debug('  -> enddate new: ' + assignment.endDate__c + ' VS old: ' + assign.endDate__c);
                        System.debug('  -> manager new: ' + assignment.salesManager__c + ' VS old: ' + assign.salesManager__c);
                        System.debug('  -> replaced new: ' + assignment.replaced__c + ' VS manager old: ' + assign.salesManager__c);

                        if (assignment.replaced__c == assign.salesManager__c) {
                            System.debug('  -> Matching manager replaced');
                            if (hasEndDate && assign.startDate__c <= assignment.endDate__c) {
                                System.debug('  -> old assignment startDate was before replacement, update it');
                                //Replaced manager was planified before end of replacement, update old assignment startDate
                                assign.startDate__c = assignment.endDate__c.addDays(1);
                                complementaryUpdates.add(assign);
                            } else if (!hasEndDate && assign.startDate__c >= assignment.startDate__c) {
                                System.debug('  -> old assignment startDate is after replacement and replacement has no end, remove it');
                                //Replaced manager was intended to start after replacement, remove the record
                                complementaryDeletes.add(assign);
                            } else if (!hasEndDate && assign.startDate__c < assignment.startDate__c) {
                                System.debug('  -> old assignment startDate was before replacement, update endDate');
                                //Replaced manager was intended to start before replacement, change endDate
                                assign.endDate__c = assignment.startDate__c.addDays(-1);
                                complementaryUpdates.add(assign);
                            }
                        } else if (assignment.salesManager__c == assign.replaced__c) {
                            System.debug('  -> Matching manager replacement');
                            if (assign.startDate__c < assignment.startDate__c
                                    && (assign.endDate__c == null || assign.endDate__c >= assignment.startDate__c)) {
                                //Manager is back before replacement end date, update the replacement end date
                                System.debug('  -> replacement assignment endDate was after manager back start, update it');
                                assign.endDate__c = assignment.startDate__c.addDays(-1);
                                complementaryUpdates.add(assign);
                            }
                            if ( (assign.startDate__c >= assignment.startDate__c && !hasEndDate)
                                    || (assign.startDate__c >= assignment.startDate__c && hasEndDate
                                    && assign.endDate__c != null
                                    && assign.endDate__c <= assignment.endDate__c) ) {
                                //Manager is back and will not go before planned replacement, remove it
                                complementaryDeletes.add(assign);
                            }
                            if (assign.startDate__c >= assignment.startDate__c
                                    && hasEndDate
                                    && assign.startDate__c <= assignment.endDate__c
                                    && assign.endDate__c > assignment.endDate__c) {
                                //Manager is back and will go before planned replacement, update it
                                assign.startDate__c = assignment.endDate__c.addDays(1);
                                complementaryUpdates.add(assign);
                            }
                        }
                    }
                }
            }
        }
        update complementaryUpdates;
        delete complementaryDeletes;
    }


    private static NRV10ManagerAssignmentContext buildContext() {
        NRV10ManagerAssignmentContext ctx = new NRV10ManagerAssignmentContext();

        ctx.newAssignments = (List<NRV10ManagerAssignment__c>)Trigger.new;

        for (NRV10ManagerAssignment__c assignment : ctx.newAssignments) {
            if (!ctx.managersIds.contains(assignment.salesManager__c)) {
                ctx.managersIds.add(assignment.salesManager__c);
            }
            if (!ctx.storeIds.contains(assignment.store__c)) {
                ctx.storeIds.add(assignment.store__c);
            }
        }

        //prepare lists for managers and store unicity
        //Map managers Ids with the list of their assignments as manager
        for (NRV10ManagerAssignment__c assign : [SELECT Id, salesManager__c,
                replaced__c, store__c, startDate__c,
                endDate__c, role__c FROM NRV10ManagerAssignment__c WHERE salesManager__c IN :ctx.managersIds OR store__c IN :ctx.storeIds
        ]) {
            if (ctx.managersIds.contains(assign.salesManager__c)) {
                if (!ctx.managerAssignmentsMaps.containsKey(assign.salesManager__c)) {
                    ctx.managerAssignmentsMaps.put(assign.salesManager__c, new List<NRV10ManagerAssignment__c>());
                }
                ctx.managerAssignmentsMaps.get(assign.salesManager__c).add(assign);
            }
            if (ctx.storeIds.contains(assign.store__c)) {
                if (!ctx.storesMaps.containsKey(assign.store__c)) {
                    ctx.storesMaps.put(assign.store__c, new List<NRV10ManagerAssignment__c>());
                }
                ctx.storesMaps.get(assign.store__c).add(assign);
            }
        }

        return ctx;
    }

    public class NRV10ManagerAssignmentContext {
        public List<NRV10ManagerAssignment__c> newAssignments;
        public List<Id> managersIds = new List<Id>();
        public List<Id> storeIds = new List<Id>();
        public Map<Id, List<NRV10ManagerAssignment__c>> managerAssignmentsMaps = new Map<Id, List<NRV10ManagerAssignment__c>>();
        public Map<Id, List<NRV10ManagerAssignment__c>> storesMaps = new Map<Id, List<NRV10ManagerAssignment__c>>();
    }
}