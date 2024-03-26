public with sharing class fsapp_AssetImages {
    @AuraEnabled(cacheable=true)
    public static List<Asset> getAssetRecords(Id serviceAppointmentId) {
        // Retrieve the asset records from the database or any other source
        serviceAppointment serviceAppointmentRecord = [SELECT Id,customerOrder__c FROM serviceAppointment WHERE Id = :serviceAppointmentId LIMIT 1];
        List<Asset> assetRecords = [SELECT Id, Name, Description FROM Asset WHERE customerOrder__c = :serviceAppointmentRecord.customerOrder__c LIMIT 100];
        system.debug('assetRecords: ' + assetRecords);
        return assetRecords;
    }
}