/**
 * Created by MCA on 15/09/2020.
 */


trigger SBQQ_QuoteLineTrigger on SBQQ__QuoteLine__c (after delete) {

  if (Trigger.isDelete && Trigger.isAfter) {
      SBQQ_QuoteLineTriggerHandler.removeOldProductOrdersOnAmendment(Trigger.old);
  }
}