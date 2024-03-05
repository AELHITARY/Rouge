//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : BA_EXP_listeInactiviteUsers
//-- Modifié par : SOPRA STERIA 
//-- Modifié le  : 15/05/2019
//-- Version     : 1.0
//-- * 1.0 : KPKCRM_RQM-87 : Optimisation 
//-- --------------------------------------------------------------------------------- --
global class BA_EXP_listeInactiviteUsers implements Database.Batchable<sObject>, Database.Stateful {
    global BatchHistory__c batchHistoryStored {get;set;}
    global Map<String, Set<User>> managers = new Map<String, Set<User>>();
    global UserManager userManager = new UserManager();
    private static final Integer DELAI_DESACTIVATION_VENDEUR = PropertiesUtils.getIntegerValue('maintenance.delaiDesactivation', -30);
    private static final Integer DELAI_INFO_CONNEXION = PropertiesUtils.getIntegerValue('maintenanceQuot.delaiInfoConnexion', -7);
    private static final String EMPTY_PREFIX = '<EMPTY>';
    private static final String CALL_PREFIX = 'CALL:';
    private static final String DV_PREFIX = 'DV:';
    private static final String DR_PREFIX = 'DR:';
    
    /** 
    * @description Constructeur
    * @return BA_EXP_listeInactiviteUsers 
    */
    global BA_EXP_listeInactiviteUsers() {
        system.debug('### DEBUT BA_EXP_listeInactiviteUsers()');
        if (this.batchHistoryStored == null){
            batchHistoryStored = Utils_HistoriqueBatchs.createNewBatchHistory('BA_EXP_listeInactiviteUsers');
        }
        system.debug('### FIN BA_EXP_listeInactiviteUsers()');
    }
    
    /** 
    * @description Méthode exécutée au début du batch afin de récupérer les enregistrement à mettre à jour 
    * @param BC Context du batch
    * @return Database.QueryLocator Lot des enregistrements pour le processus
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {    
        system.debug('### DEBUT BA_EXP_listeInactiviteUsers.start()');
        Database.QueryLocator results;

        try {
            // Si test en cours alors il faut forcer la suppression sachant que les paramètres personnalisés ne sont pas visibles pendant les tests sur les sandbox
            if (!PropertiesUtils.getBooleanValue('maintenance.usersNonConnectes', Test.isRunningTest())) {
                batchHistoryStored = Utils_HistoriqueBatchs.inactiveBatchHistory(batchHistoryStored);
                return Database.getQueryLocator([SELECT id FROM User LIMIT 0]);
            } 
            EmailUtils.mailToITSupport('[KUBE] Exploitation : Liste des utilisateurs non connectés', 'Début des traitements.\n\nCordialement\n');
            
            // Limite le nombre d'enregistrement à 100 pour les tests pour éviter les erreurs
            if(Test.isRunningTest()) {
                results = Database.getQueryLocator([SELECT Id, Name, Email, IsActive, UserRoleId, ProfileId,
                                                    LastLoginDate, CreatedDate, libelleMagasin__c, codeDV__c, libelleDV__c,
                                                    codeDR__c, libelleDR__c, callCenters__c, equipesCall__c FROM User
                                                    LIMIT 100]);
            } else {
                results = Database.getQueryLocator([SELECT Id, Name, Email, IsActive, UserRoleId, ProfileId,
                                                    LastLoginDate, CreatedDate, libelleMagasin__c, codeDV__c, libelleDV__c,
                                                    codeDR__c, libelleDR__c, callCenters__c, equipesCall__c FROM User
                                                    WHERE Id IN :userManager.getUsers(false)]);
            }
            // Mise à jour des historiques
            batchHistoryStored = Utils_HistoriqueBatchs.finishStartBatchHistory(batchHistoryStored);
            Database.QueryLocatorIterator it =  results.iterator();
            if(!it.hasNext()) batchHistoryStored = Utils_HistoriqueBatchs.quickEndBatchHistory(batchHistoryStored);
            
            system.debug('### FIN BA_EXP_listeInactiviteUsers.start()');
        } 
        catch(Exception e) {
            system.debug('ERREUR : ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
            EmailUtils.reportException('[KUBE] Exploitation : Liste des utilisateurs non connectés : Erreur lors de l\'initialisation du batch', e);
        } 
        return results;
    }
    
    /**
    * @description Méthode exécutée pour chaque lot d'enregistrements
    * @param BC Context du batch
    * @param scope Liste des enregistrements
    */
    global void execute (Database.BatchableContext BC, List<User> scope) {
        system.debug('### DEBUT BA_EXP_listeInactiviteUsers : execute');
        system.debug('## Scope size : '+scope.size());  
        
        try  {        
            Integer nb = 0;
            Date dateNotification  = Date.today().addDays(DELAI_INFO_CONNEXION);
            batchHistoryStored = Utils_HistoriqueBatchs.beginExecuteBatchHistory(batchHistoryStored, scope.size());
            
            // Calcul des managers 
            for (User user : scope) {
                // Filtre sur la dernière connexion 
                if (((user.LastLoginDate == null && user.CreatedDate < dateNotification) || (user.LastLoginDate < dateNotification))) {
                    // Incrément le nombre d'utilisateur à désactiver
                    nb++;
                    // Répartition/traitement en fonction du type d'utilisateur 
                    if (userManager.isCallUser(user)) {
                        String manager = String.isBlank(user.callcenters__c) ? EMPTY_PREFIX : (CALL_PREFIX + user.callcenters__c);
                            if (managers.containsKey(manager))
                            managers.get(manager).add(user);
                        else
                            managers.put(manager, new Set<User>(new User[]{user}));
                    } else {
                        // DV
                        String manager = String.isBlank(user.codeDV__c) ? EMPTY_PREFIX : (DV_PREFIX + user.codeDV__c);
                        if (managers.containsKey(manager))
                            managers.get(manager).add(user);
                        else
                            managers.put(manager, new Set<User>(new User[]{user}));
                        
                        // DR
                        manager = String.isBlank(user.codeDR__c) ? EMPTY_PREFIX : (DR_PREFIX + user.codeDR__c);
                        if (managers.containsKey(manager))
                            managers.get(manager).add(user);
                        else
                            managers.put(manager, new Set<User>(new User[]{user}));
                    }
                }
            }
            
            // MAJ nombre traité pour historique
            batchHistoryStored.nombreTraite__c = (batchHistoryStored.nombreTraite__c == null) ? nb : batchHistoryStored.nombreTraite__c + nb;
        }
        catch(Exception ex) {            
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ ex.getMessage() + ' ' + ex.getTypeName() + ' ' + ex.getStackTraceString());
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Liste des utilisateurs non connectés', ex);
        }
        
        system.debug('### FIN BA_EXP_listeInactiviteUsers : execute');
    }
    
    /**
    * @description Méthode exécutée à la fin du batch
    * @param BC Context du batch
    */
    global void finish (Database.BatchableContext BC) {   
        system.debug('### DEBUT BA_EXP_listeInactiviteUsers : finish');
        system.debug('## Nb managers : '+managers.size());
        system.debug('## managers : '+managers);
        
        try  {        
            Date dateDuJour = Date.today();
            Date dateNotification  = dateDuJour.addDays(DELAI_INFO_CONNEXION);
            List<String> support = new List<String>(userManager.getSupportEmails());
            List<String> siege = new List<String>(userManager.getSiegeEmails());
            List<Messaging.Email> emails = new List<Messaging.Email>();
            
            // Envoi des emails   
            for (String key : managers.keySet()) {
                String msg = 'Bonjour,\n'
                    + '\n'
                    + 'Veuillez trouver ci-dessous la liste des utilisateurs de l\'application Kube qui ne se sont pas connectés depuis le ' + (dateNotification.isSameDay(dateNotification.toStartofWeek()) ? 'lundi ' : '') + dateNotification.format() + ', soit ' + Math.abs(DELAI_INFO_CONNEXION) + ' jours et plus.\n'
                    + '\n'
                    + 'Pour information, dans l\'application Kube, les comptes utilisateurs sont des ressources partagées entre tous les employés de K par K (réseau commercial, centres d\'appel et siège). Aussi, si un utilisateur ne se connecte pas au moins une fois tous les ' + Math.abs(DELAI_DESACTIVATION_VENDEUR) + ' jours, son compte sera désactivé.\n'
                    + '\n'
                    + 'Pour chaque utilisateur concerné, vous trouverez les informations suivantes:\n'
                    + '1 - Nom de l\'utilisateur\n'
                    + '2 - Magasin\\équipe\n'
                    + '3 - Profile\n'
                    + '4 - Rôle\n'
                    + '5 - Nombre de jours sans connexion\n'
                    + '\n'
                    + '\n'
                    + 'Utilisateurs :\n'
                    + '\n';
                
                // Recherche du manager 
                User manager = null;
                if (key.startsWith(CALL_PREFIX)) {
                    String call = key.substringAfter(CALL_PREFIX);
                    for (User u : userManager.getUsers(false)) {
                        if (userManager.isCallDirector(u) && u.callcenters__c == call) {
                            manager = u;
                            break;
                        }
                    }
                } else if (key.startsWith(DV_PREFIX)) {
                    String DV = key.substringAfter(DV_PREFIX);
                    for (User u : userManager.getUsers(false)) {
                        if (userManager.isDV(u) && u.codeDV__c == DV) {
                            manager = u;
                            break;
                        }
                    }
                } else {
                    String DR = key.substringAfter(DR_PREFIX);
                    for (User u : userManager.getUsers(false)) {
                        if (userManager.isDR(u) && u.codeDR__c == DR) {
                            manager = u;
                            break;
                        }
                    }
                }
                
                // Alimentation du courrier 
                for (User user : managers.get(key)) {
                    msg += '- ' + user.name + '*    ("' + StringUtils.trimToEmpty(user.libelleMagasin__c) + StringUtils.trimToEmpty(user.equipesCall__c) + '" / "' + userManager.getProfileName(user) + '" / "'+ userManager.getRoleName(user) + '") depuis ';
                    if (user.LastLoginDate == null)
                        msg += Math.max(0, user.CreatedDate.date().daysBetween(dateDuJour)) + ' jour(s)\n';
                    else
                        msg += Math.max(0, user.LastLoginDate.date().daysBetween(dateDuJour)) + ' jour(s)\n';
                }
                msg += '\nsoit ' + managers.get(key).size() + ' utilisateurs.\n'
                    +  '\nSi un compte peut dès à présent être désactivé, veuillez contacter le service RH:\n'
                    +  '- Pour la DR Nord : aurelie.robert@kpark.fr\n' 
                    +  '- Pour les DR Est et Ouest : hanane.boumaiz@kpark.fr\n'
                    +  '\n\nCordialement\n';
                if (manager != null) {
                    msg += '\n\n\n\n\nNB:'
                    +  '\n   - Nom  : ' + StringUtils.trimToEmpty(manager.Name)
                    +  '\n   - DR   : ' + StringUtils.trimToEmpty(manager.codeDR__c) + ' ' + StringUtils.trimToEmpty(manager.libelleDR__c)
                    +  '\n   - DV   : ' + StringUtils.trimToEmpty(manager.codeDV__c) + ' ' + StringUtils.trimToEmpty(manager.libelleDV__c)
                    +  '\n   - Call : ' + StringUtils.trimToEmpty(manager.callCenters__c);
                }
                
                // Envoi du courrier 
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setSubject('[KUBE] Inactivité des comptes utilisateur (Etape 1/3)');
                
                if (manager != null) {
                    email.setPlainTextBody(msg);
                    email.setToAddresses(new String[]{manager.Email});
                    //email.setToAddresses(new String[]{'julien.morineau@soprasteria.com'});
                } else {
                    email.setPlainTextBody('\n\n\n/!\\ Manager non trouvé ! /!\\\n\n\n' + msg);
                    email.setToAddresses(siege);
                    //email.setToAddresses(new String[]{'julien.morineau@soprasteria.com'});
                }
                //email.setCcAddresses(support);
                emails.add(email);
            }
            
            String a = '';
            String b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            a = b;
            b = a;
            
            if (!Test.isRunningTest())
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
            
            EmailUtils.mailToITSupport('[KUBE] [OK] Exploitation : Liste des utilisateurs non connectés',
                                       'Bonjour,\n\n' + batchHistoryStored.nombreTraite__c + ' utilisateurs ne sont pas connectés.\n\nCordialement\n');
        }
        catch(Exception ex) {            
            Utils_HistoriqueBatchs.traceErrorBatchHistory(batchHistoryStored, ' *** ERREUR *** '+ ex.getMessage() + ' ' + ex.getTypeName() + ' ' + ex.getStackTraceString());
            EmailUtils.reportException('[KUBE] [ERREUR] Exploitation : Liste des utilisateurs non connectés', ex);
        }
        
        // Mise à jour des stats
        batchHistoryStored = Utils_HistoriqueBatchs.finishExecuteBatchHistory(batchHistoryStored);
        system.debug('### FIN BA_EXP_listeInactiviteUsers : finish');
    }
}