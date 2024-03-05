//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_FlowMapRecordClass
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 13/10/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class Utils_FlowMapRecordClass {

    @AuraEnabled
    public string key; //Map key
    @AuraEnabled
    public sObject record; //sObject attribute for sObject Map type
}