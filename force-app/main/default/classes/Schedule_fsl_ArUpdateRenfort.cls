//-- --------------------------------------------------------------------------------- ------------------------------------
//-- * 
//-- Fichier     : Test_fsl_PlatformEvent
//-- Modifié par : CGI
//-- Modifié le  : 15/02/2018
//-- Version     : 1.0
//-- Description : Planification Batch Mise à jour des renforts sur les ressources secondaires pour pallier au bug visuel, toutes les 5 minutes. 
//-- --------------------------------------------------------------------------------- -----------------------------------/***
public with sharing class Schedule_fsl_ArUpdateRenfort implements Schedulable {
    
    public void execute(SchedulableContext sc){
        BA_fsl_ArUpdateRenfort baur = new BA_fsl_ArUpdateRenfort();
        Database.executeBatch(baur, 1000); 
    }
    
}