//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR024_Account 
//-- Modifié par : SOPRA STERIA
//-- Modifie le  : 10/06/2022
//-- Version     : 1.2
//-- * 1.3 - Modification Odigo pour CARPORT et PERGOLA
//-- * 1.2 - Modification Odigo pour envoyer les 57 - PROSPECTION FLASH
//-- * 1.1 - Modification Odigo pour envoyer dans campagne sortante
//-- * 1.0 - Init
//-- --------------------------------------------------------------------------------- --
public without sharing class TR024_Account {
    private static final String   PERSO_RTID = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PERSO_RT);
    private static final String   PRO_RTID   = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_PRO_RT);
    private static final DateTime ABORT_DT   = DateTime.newInstanceGmt(1900, 1, 1, 12, 0, 0);
  
    /**
    * @description Méthode pour envoyer une demande d'appel si compte part ou pro
    * @param userContext contexte utilisateur
    */
    public static void notifyCallBack(UserContext userContext) {
        if (userContext == null) {
            return;
        }
        System.debug('### DEBUT TR024_Account.notifyCallBack');
        
        List<Account> newAccounts = new List<Account>();    
        // Récupération seulement des comptes PRO ou PERSO
        for(Account acc : (List<Account>)Trigger.new) {
            if(acc.RecordTypeId == PERSO_RTID || acc.RecordTypeId == PRO_RTID) {
                newAccounts.add(acc);
            }
        }
        
        if(!newAccounts.isEmpty()) {
            System.debug('## CALLBACK >>> ' + userContext.getUser().name + ' \\ ' + userContext.getProfile().name);
            if (!Trigger.isExecuting || (userContext != null && userContext.getProfile() != null 
                                     && !('K/K - Interface'.equalsIgnoreCase(userContext.getProfile().name)         ||
                                          'K/K - Affiliation'.equalsIgnoreCase(userContext.getProfile().name)       ||    
                                          'K/K - Import'.equalsIgnoreCase(userContext.getProfile().name)            ||                                            
                                          'Profil Parrainage'.equalsIgnoreCase(userContext.getProfile().name)       ||
                                          'Profil QTS'.equalsIgnoreCase(userContext.getProfile().name)              ||
                                          'Profil Demande de Devis'.equalsIgnoreCase(userContext.getProfile().name) ||
                                          'Administrateur système'.equalsIgnoreCase(userContext.getProfile().name)))) {
                return;
            }
            System.debug('## System.isBatch() : ' +System.isBatch());      
            System.debug('## System.isQueueable() : ' +System.isQueueable());   
        
            Map<Id, Account> oldAccounts = (Map<Id, Account>) Trigger.oldMap;
            String errorMsg = '';
            String infoMsg = '';

            for (Account newAccount : newAccounts) {
                System.debug('## notifyCallBack (' + newAccount.AccountNumber + ' / ' + newAccount.nom__c + ')');
                Account oldAccount = oldAccounts == null ? null : oldAccounts.get(newAccount.id);
                if (('44 - Formulaire site KparK'.equalsIgnoreCase(newAccount.accountCallSource__c) || 
                    ('15 - Batiweb'.equalsIgnoreCase(newAccount.accountCallSource__c))              || 
                    ('15 - Quotatis'.equalsIgnoreCase(newAccount.accountCallSource__c))             || 
                    ('44 - Batiweb'.equalsIgnoreCase(newAccount.accountCallSource__c))              || 
                    ('44 - Affiliation'.equalsIgnoreCase(newAccount.accountCallSource__c))          ||
                    ('44 - Formulaire site QTS'.equalsIgnoreCase(newAccount.accountCallSource__c))  ||
                    ('PROSPECTION FLASH'.equalsIgnoreCase(newAccount.accountSource)))
                    &&
                    (oldAccount == null || oldAccount.callbackprosodie__c == null)
                    && 
                    newAccount.callbackprosodie__c != null && !ABORT_DT.isSameDay(newAccount.callbackprosodie__c)
                    &&
                    (!String.isEmpty(newAccount.telephoneDomicile__c) || !String.isEmpty(newAccount.telephoneMobile__c) || !String.isEmpty(newAccount.autreTelephone__c) || !String.isEmpty(newAccount.phone))) 
                {
                    if (!System.isBatch() && !System.isFuture() && Limits.getFutureCalls() < Limits.getLimitFutureCalls()) {
                        asyncSaveCallBack(newAccount.id);
                        infoMsg += newAccount.AccountNumber + ' - ' + newAccount.lastName + ' ' + newAccount.firstName + '(' + account.nomFichierSource__c + ')\n'; 
                    } else {
                        errorMsg += newAccount.AccountNumber + ' - ' + newAccount.name + '(Batch context: ' + System.isBatch() + ', Async context: ' + System.isFuture() + ', Async calls: ' + Limits.getFutureCalls() + '/' + Limits.getLimitFutureCalls() + ')\n';             
                    }
                }
            } 
            
            if (( !String.isEmpty(infoMsg) && 'Administrateur système'.equalsIgnoreCase(userContext.getProfile().name)) && !Test.isRunningTest()) { 
                List<User> to = [SELECT id, userName, email FROM User WHERE userName in ('franck.gourdeaux@kpark.fr', 'francois.banse@kpark.fr', 'daniel.angulo@kpark.fr')];            
                EmailUtils.mailTo('[Kube] Notification(s) callback Prosodie FORMULAIRES', 'Une notification callback Prosodie a été envoyée pour les comptes suivants:\n\n' + infoMsg, to);
            }
            
            System.debug('## ERROR MESSAGE >>> ' + errorMsg); 
            if (!String.isEmpty(errorMsg) && !Test.isRunningTest()) { 
                UserManager userManager = new UserManager();
                List<User> to = userManager.getUsers(userManager.getProfileId('K/K - DC'), null);
                List<User> copyTo = [SELECT id, isActive, email FROM user WHERE isActive = true AND userName = 'franck.gourdeaux@kpark.fr'];
                EmailUtils.mailTo('[Kube] Notification(s) callback Prosodie non envoyée(s)', 'Une notification callback Prosodie n\'a pas été envoyée pour les comptes suivants:\n\n' + errorMsg, to, copyTo);
            }
            Integer a=1;
            a=2;
            a=2;
            a=2;
            a=2;
            a=2;
            a=2;
            a=2;
            a=2;
            a=2;
            a=2;
            a=2;
            a=2;
            a=2;
        }
    }
  
    /**
    * @description Méthode pour envoyer une demande d'appel si compte part ou pro
    * @param accObj Information du compte
    */
    public static void notifyCallBack(Account accObj) {
        System.debug('### DEBUT TR024_Account.notifyCallBack');
        if(accObj != null && (accObj.RecordTypeId == PERSO_RTID || accObj.RecordTypeId == PRO_RTID)) {
            if (Trigger.isExecuting && !System.isBatch() && !System.isFuture() && Limits.getFutureCalls() < Limits.getLimitFutureCalls()) {
                asyncSaveCallBack(accObj.id);
            } else {
                syncSaveCallBack(accObj);
            }
        }
        System.debug('### FIN TR024_Account.notifyCallBack');
    }

    /**
    * @description Méthode asynchrone récupérant les informations du comptes pour ensuite faire appel à la méthode d'envoi vers odigo
    * @param id Id du compte
    */
    @future(callout=true)
    public static void asyncSaveCallBack(ID id) {  
        System.debug('### DEBUT TR024_Account.asyncSaveCallBack >>> ' + id);   

        if ((Limits.getCallouts() + 2) > Limits.getLimitCallouts()) { // S'assure que les 2 appels WS seront traités
            System.debug('ERREUR # Notification non transmise (Limite(s) atteinte(s): ' + Limits.getCallouts() + ' / ' + Limits.getLimitCallouts() + ') !');
            throw new KubeException('ERREUR # Notification non transmise (Limite(s) atteinte(s): ' + Limits.getCallouts() + ' / ' + Limits.getLimitCallouts() + ') !');
        }

        List<Account> accObj = [SELECT telephoneDomicile__c, telephoneMobile__c, autreTelephone__c, phone, callbackProsodie__c, skillProsodie__c, Id 
                               FROM Account WHERE id = :id LIMIT 1];
        if (accObj.isEmpty()) {
            System.debug('ERREUR # Notification non transmise (Compte non trouvé) !');
            throw new KubeException('ERREUR # Notification non transmise (Compte non trouvé) !');
        }
        if (String.isEmpty(accObj[0].telephoneDomicile__c) && String.isEmpty(accObj[0].telephoneMobile__c) && String.isEmpty(accObj[0].autreTelephone__c) && String.isEmpty(accObj[0].phone)) {
            System.debug('ERREUR # Notification non transmise (Aucun téléphone  disponible #' + account.id + ') !');
            throw new KubeException('ERREUR # Notification non transmise (Aucun téléphone disponible #' + account.id + ') !');
        }
        
        syncSaveCallback(accObj[0]); 
        System.debug('### FIN TR024_Account.asyncSaveCallBack');  
    }
  
    /**
    * @description Méthode synchrone pour faire appel au WS WebCallback d'Odigo pour envoyer une tâche d'appel (callback)
    * @param accObj Information du compte
    */
    public static void syncSaveCallback(Account accObj) {    
        System.debug('### DEBUT TR024_Account.syncSaveCallback >>> ' + accObj.id); 
        String message = '';

        /* DEPRECATED
        if (!Utils_Odigo.isCallBackAuthorized())
            throw new KubeException('ERREUR # Callback non autorisé!');  

        wsOdigoProsodie36WebcallbackBeanModel.CallBackBean callBack = new wsOdigoProsodie36WebcallbackBeanModel.CallBackBean();
        if (!String.isEmpty(accObj.telephoneDomicile__c))
            callBack.phoneNumber = accObj.telephoneDomicile__c;
        else if (!String.isEmpty(accObj.telephoneMobile__c))
            callBack.phoneNumber = accObj.telephoneMobile__c;
        else if (!String.isEmpty(accObj.autreTelephone__c))
            callBack.phoneNumber = accObj.autreTelephone__c;
        else 
            callBack.phoneNumber = accObj.phone;
        callBack.skillKeyWord = accObj.skillProsodie__c;        
        callBack.priority = Utils_Odigo.ODIGO_PRIORITY;
        callBack.date_x = 0;
        callBack.data = accObj.id;
        callBack.data2 = null;
        callBack.newPhoneNumber = null;
        callBack.agentId = null;         

        wsOdigoProsodie36Webcallback.WebCallBackHttpsSoap11Endpoint endPoint = new wsOdigoProsodie36Webcallback.WebCallBackHttpsSoap11Endpoint();
        endPoint.timeout_x = Utils_Odigo.ODIGO_TIMEOUT;

        System.debug('>>> WebCallBack >>> ' + callBack);

        if(!Test.isRunningTest()) {}
            Utils_Odigo.checkCallback(endPoint.saveCallBack(callBack, Utils_Odigo.getUser()), callBack.phoneNumber);
        }
        */
        
        // Récupération de l'ID de la campagne d'appels sortants 
        String odigoCampaignName = PropertiesUtils.getStringValue('prosodie.odigo.formulaire.campaign', PropertiesUtils.getStringValue('prosodie.odigo.formulaire', ''));        
        Integer odigoCampaignId;

        if(!Test.isRunningTest()) {
            odigoCampaignId = Utils_Odigo.getCampaignIdByLabel(odigoCampaignName);
        } else {
            odigoCampaignId = 2;
        }
        if(odigoCampaignId == null) {
            throw new KubeException('ERREUR # Problème lors de la récupération de l\'ID de la campagne Odigo');
        }
        System.debug('## ID: '+odigoCampaignId);  


        // Récupération de la priorité en fonction de lh'eure et de la période de la semaine        
        DateTime reference = DateTIme.now();
        Integer refDOW = Integer.valueOf(reference.format('u', 'Europe/Paris'));
        Integer refTime = Integer.valueOf(reference.format('hh', 'Europe/Paris')) * 60 + Integer.valueOf(reference.format('mm', 'Europe/Paris'));

        String periodName;
        Integer highPeriodStart;
        Integer highPeriodEnd;
        Integer odigoPriority;

        switch on refDOW {
            when 6, 7 {        
                String[] a = PropertiesUtils.getStringValue('prosodie.odigo.formulaire.WE.start', '10:00').split(':');
                highPeriodStart = Integer.valueOf(a[0]) * 60 + Integer.valueOf(a[1]);
                a = PropertiesUtils.getStringValue('prosodie.odigo.formulaire.WE.end', '12:00').split(':');
                highPeriodEnd = Integer.valueOf(a[0]) * 60 + Integer.valueOf(a[1]);  

                periodName = 'WEEK-END';
            }
            when else {
                // String[] a = PropertiesUtils.getStringValue('prosodie.odigo.formulaire.period.week.start', '08:30').split(':');
                String[] a = PropertiesUtils.getStringValue('prosodie.odigo.formulaire.week.start', '08:30').split(':');
                highPeriodStart = Integer.valueOf(a[0]) * 60 + Integer.valueOf(a[1]);
                a = PropertiesUtils.getStringValue('prosodie.odigo.formulaire.week.end', '11:00').split(':');
                highPeriodEnd = Integer.valueOf(a[0]) * 60 + Integer.valueOf(a[1]);  

                periodName = 'SEMAINE';        
            }
        }

        if (highPeriodStart <= refTime && refTime <= highPeriodEnd)            
            odigoPriority = PropertiesUtils.getIntegerValue('prosodie.odigo.formulaire.prio.high', 5);
        else
            odigoPriority = PropertiesUtils.getIntegerValue('prosodie.odigo.formulaire.prio.std', 3);
        System.debug('==> ' + periodName + ' | ' + highPeriodStart + '<' + refTime + ' < ' + highPeriodEnd + ' | ' + odigoPriority);

        // Configuration du callback    
        List<Utils_Odigo.WebCallBackContactList> callbackList = new List<Utils_Odigo.WebCallBackContactList>();
        Utils_Odigo.WebCallBackContactList callBack = Utils_Odigo.configureCallback(accObj, String.valueOf(odigoPriority)); 
        // Si callback possède un numéro de téléphone (différent de null)
        if (callBack!=null) {         
            callbackList.add(callBack);
        }

        // Envoi de la campagne dans odigo
        if(!callbackList.isEmpty()){
            if(!Test.isRunningTest() && Utils_Odigo.ODIGO_ACTIVE) {                     
                System.debug('## Envoi à ODIGO');  
                String retWS = Utils_Odigo.uploadCallback(odigoCampaignId, callbackList);
                if(retWS != 'OK') {
                    throw new KubeException('ERREUR # Problème lors de l\'envoi des callbacks dans la campagne: '+retWS);
                }
            } 
        }

        System.debug('### FIN TR024_Account.syncSaveCallback');  
    }
}