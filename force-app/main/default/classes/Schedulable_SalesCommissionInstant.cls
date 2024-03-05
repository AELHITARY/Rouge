/**
 * @description Classe planifiée pour vérifier si un cliché sur commission doit être réalisé.
 * Dans le cas ou un cliché à date du jour est prévu, déclenche le batch de cliché et de génération du csv.
 *
 * Created by Gregory Quinet on 05/10/2020.
 */

global class Schedulable_SalesCommissionInstant implements Schedulable {

    global void execute(SchedulableContext sc) {
        NRV10Calendar__c[] cal = [SELECT Id, commDate__c FROM NRV10Calendar__c WHERE commDate__c = TODAY LIMIT 1];

        if (cal != null && cal.size() > 0) {
            BA_SalesCommissionInstant instant = new BA_SalesCommissionInstant();
            Database.executeBatch(instant);
        }
    }
}