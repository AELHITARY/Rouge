//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_UserStats
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 30/08/2017
//-- Version     : 1.0
//-- * Classe utilitaire d'incrémentation compteur de l'objet UserStats__c
//-- --------------------------------------------------------------------------------- --
public without sharing class Utils_UserStats {

    /**
    * @description Fonction générique pour incrémentation d'un compteur d'un utilisateur
    * Fait appel à la méthode asynchrone insertUserStatsFuture
    * @param userId Id d l'utilisateur
    * @param champCompteur Nom API du champ de l'objet UserStats__c à incrémenter
    */
    public static void insertUserStats(Id userId, String champCompteur) {
        insertUserStatsFuture(userId, champCompteur);
    }

    /**
    * @description Fonction asynchrone pour incrémentation d'un compteur d'un utilisateur
    * @param userId Id d l'utilisateur
    * @param champCompteur Nom API du champ de l'objet UserStats__c à incrémenter
    */
    @future
    public static void insertUserStatsFuture(Id userId, String champCompteur) {
        UserStats__c stats;
        List<UserStats__c> statsList = new List<UserStats__c>();

        String soqlQuery ='SELECT id, name, user__c, date__c, ' +champCompteur;
                soqlQuery+=' FROM UserStats__c';
                soqlQuery+=' WHERE user__c = :userId AND date__c = TODAY';
        statsList = database.query(soqlQuery);
        
        // Pas d'enregistrement existant, création d'une stat
        if (statsList.isEmpty()) {
            User user = [SELECT FirstName, LastName FROM User WHERE Id=:userId LIMIT 1];
            stats = new UserStats__c(name   = user.FirstName + ' ' + user.LastName + ' / ' + System.today(),
                                    user__c = userId,
                                    date__c = System.today());
            stats.put(champCompteur, 1);
        } else {
            // Sinon incrémentation enregistrement existant
            stats = statsList[0];
            stats.put(champCompteur, (Decimal)stats.get(champCompteur) + 1);
        }
        // MAJ
        if (stats != null)
            upsert stats;
    }
}