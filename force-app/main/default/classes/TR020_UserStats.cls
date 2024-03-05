public class TR020_UserStats {

    /***** A - Validation rules *****/
    /**
    public static void applyValidationRules(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;

        List<UserStats__c> newUserStats = (List<UserStats__c>)Trigger.new;
    }
    **/

    /***** B - Update rules *****/
    public static void applyUpdateRules(UserContext userContext) {
        if (!Trigger.isExecuting)
            return;
            
        List<UserStats__c> newUserStats = (List<UserStats__c>)Trigger.new;
        for (UserStats__c newUserStat : newUserStats) {
            // Ecrasement du propriétaire avec l'utilisateur afin de pouvoir gérer le scope (mes stats, les stats de mon équipe, etc.) dans les rapports
            newUserStat.ownerId = newUserStat.user__c;
        }
    }
}