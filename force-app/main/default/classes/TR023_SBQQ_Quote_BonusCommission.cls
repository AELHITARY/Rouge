/**
 * Created by 4C on 18/09/2020.
 */

public with sharing class TR023_SBQQ_Quote_BonusCommission {

    /**
     * @author Gregory Quinet
     * @date 2020-09-15
     * @description Multiple collaborator processing, create/update commissions on every sales of the list
     *
     * @param context All queried elements of sales commission processing
     */
    public static void processBonusCommissions(TR022_SBQQ_Quote_Commission.NRV10CommissionContext context) {
        System.debug('Start processing bonus commissions');
        List<NRV10Calendar__c> lastSnapshotDates;
        lastSnapshotDates = [SELECT Id, commDate__c FROM NRV10Calendar__c WHERE
                commDate__c <= TODAY ORDER BY commDate__c DESC LIMIT 2];

        if (lastSnapshotDates.isEmpty() || lastSnapshotDates.size() < 2) {
            System.debug('Can\'t find M-2 snapshotDate, cannot calculate bonus commission');
            return;
        }

        //Get all collaborators CA M-2 FROM KMDC
        System.debug('Get all sales CA on M-2 for each concerned collaborators from KMDC');
        Map<String, List<KMDC__c>> collaboratorLastCommissionsMap = new Map<String, List<KMDC__c>>();
        if (!context.collaboratorSGIds.isEmpty()) {
            for (KMDC__c CA : [
                    SELECT Id, montantHT__c, SGID__c, dateStats__c
                    FROM KMDC__c
                    WHERE
                    SGID__c IN :context.collaboratorSGIds AND dateStats__c >= :lastSnapshotDates.get(1).commDate__c
                    AND dateStats__c < :lastSnapshotDates.get(0).commDate__c
            ]) {

                if (!collaboratorLastCommissionsMap.containsKey(CA.SGID__c)) {
                    collaboratorLastCommissionsMap.put(CA.SGID__c, new List<KMDC__c>());
                }
                collaboratorLastCommissionsMap.get(CA.SGID__c).add(CA);
            }
        }
        System.debug('  -> got data for ' + collaboratorLastCommissionsMap.size() + ' collaborators');

        //get all current commissions where customer get quote or accepted it
        System.debug('Get all current sales commissions for each concerned collaborators');
        Map<Id, List<NRV10Commission__c>> collaboratorCommissionsMap = new Map<Id, List<NRV10Commission__c>>();
        for (NRV10Commission__c comm : [SELECT Id, comType__c, remuneration__c, ecPercent__c, productRate__c,
                discountCoefficient__c, teamRate__c, salesRem__c, turnoverLevel__c, orderProduct__c,
                user__c, status__c, calculationDate__c, instantDate__c FROM NRV10Commission__c WHERE user__c IN :context.collaboratorIds
        AND instantDate__c = NULL AND status__c = :Constants.COMMISSION_STATUS_COMMISSIONABLE
        AND calculationDate__c >= :lastSnapshotDates.get(0).commDate__c
        AND comType__c = :Constants.COMMISSION_TYPE_SALES]) {
            if (!collaboratorCommissionsMap.containsKey(comm.user__c)) {
                collaboratorCommissionsMap.put(comm.user__c, new List<NRV10Commission__c>());
            }
            collaboratorCommissionsMap.get(comm.user__c).add(comm);
        }

        //process collaborators to calculate bonus
        List<NRV10Commission__c> toUpsert = new List<NRV10Commission__c>();
        for (Collaborator__c c : context.collaboratorsMap.values()) {
            System.debug('Processing collaborator ' + c.Name);

            if (!context.collaboratorContractMap.containsKey(c.Id)) {
                System.debug(System.LoggingLevel.INFO, 'Collaborator don\'t have employment contract');
                continue;
            }

            //get contract according to the quote date
            NRV10RemunerationContract__c contract;
            for (NRV10RemunerationContract__c ct : context.collaboratorContractMap.get(c.Id)) {
                if (ct.startDate__c < Date.today()
                        && (ct.endDate__c == null || ct.endDate__c >= Date.today())) {
                    contract = ct;
                }
            }
            if (contract == null) {
                System.debug(System.LoggingLevel.INFO, 'Collaborator don\'t have employment contract for the period');
                continue;
            }
            System.debug('  -> Collaborator have a contract for current period: ' + contract);

            //get contract grid
            NRV10GridRevision__c ctGrid;
            if (context.contractRevisionsMap.containsKey(contract.employmentContractType__c)) {
                ctGrid = context.contractRevisionsMap.get(contract.employmentContractType__c);
            }
            if (ctGrid == null) {
                System.debug('No contract grid found for the collaborator, process next');
                continue;
            }
            System.debug('  -> Also have an associated contract grid revision: ' + ctGrid);

            //get bonus rates from bonus grid
            List<NRV10RemunerationRate__c> bonusRates = new List<NRV10RemunerationRate__c>();
            if (context.remunerationRatesGridMap.containsKey(ctGrid.bonusGridRevision__c)) {
                for(NRV10RemunerationRate__c r : context.remunerationRatesGridMap.get(ctGrid.bonusGridRevision__c)) {
                    if (r.startDate__c < Date.today() && (r.endDate__c == null || r.endDate__c >= Date.today())) {
                        bonusRates.add(r);
                    }
                }
            }
            if (bonusRates.isEmpty()) {
                System.debug('No bonus rates for the period, process next');
                continue;
            }
            System.debug('  -> Found ' + bonusRates.size() + ' bonnus rates: ' + bonusRates);

            //sum commissions to get CA
            Double totalPrev = 0.0;
            if (context.collabIdSgIdMap.containsKey(c.Id)
                    && collaboratorLastCommissionsMap.containsKey(context.collabIdSgIdMap.get(c.Id))) {

                for (KMDC__c com : collaboratorLastCommissionsMap.get(context.collabIdSgIdMap.get(c.Id))) {
                    if (com.montantHT__c != null) totalPrev = totalPrev + Double.valueOf(com.montantHT__c);
                }
            }
            System.debug('  -> Total ammount of CA for previous period is: ' + totalPrev);

            Double totalCA = 0.0;
            if (collaboratorCommissionsMap.containsKey(c.Id)) {
                for (NRV10Commission__c com : collaboratorCommissionsMap.get(c.Id)) {
                    totalCA = totalCA + Double.valueOf(com.remuneration__c);
                }
            }
            System.debug('  -> Total ammount of CA for current period is: ' + totalCA);

            Double totalBonus = 0.0;
            Double highestTO = 0.0;
            if (totalCA - totalPrev > 0) {
                System.debug('  -> CA has increased compared to last period: ' + (totalCA - totalPrev));
                for (NRV10RemunerationRate__c rem : bonusRates) {
                    if (totalCA - totalPrev > rem.turnoverLevel__c) {
                        highestTO = rem.turnoverLevel__c;
                        System.debug('  -> CA step ' + rem.turnoverLevel__c + ' has been reached, add bonus amount from ' + rem);
                        totalBonus = totalBonus + Double.valueOf(rem.bonusAmount__c);
                    }
                }
            }

            if (totalBonus > 0) {
                NRV10Commission__c bonus;
                if (context.bonusMap.containsKey(c.Id)) {
                    System.debug('  -> Collaborator already have a calculated bonus commission, update it');
                    bonus = context.bonusMap.get(c.Id);
                } else {
                    System.debug('  -> Creation of the bonus commission');
                    bonus = new NRV10Commission__c();
                    bonus.comType__c = Constants.COMMISSION_TYPE_BONUS;
                    bonus.status__c = Constants.COMMISSION_STATUS_PREVISIONEL;
                    bonus.user__c = c.Id;
                }
                bonus.totalAmountTTC__c = totalCA;
                bonus.remuneration__c = totalBonus;
                bonus.turnoverLevel__c = highestTO;
                bonus.calculationDate__c = Date.today();
                toUpsert.add(bonus);
            }
        }

        System.debug('End of bonus process, upsert ' + toUpsert.size() + ' elements');
        upsert toUpsert;
    }

}