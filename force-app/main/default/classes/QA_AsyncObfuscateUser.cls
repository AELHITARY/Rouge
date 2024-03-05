//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : QA_AsyncObfuscateUser
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 25/01/2019
//-- Version     : 1.0
//-- * 1.0 : Init
//-- --------------------------------------------------------------------------------- --
public without sharing class QA_AsyncObfuscateUser implements Queueable {
    public List<User> userList;
    public Boolean doActive;
    public Map<Id, Datetime> dateDesacByUser;
    public Boolean deleteLDP;
    
    /**
    * @description Constructeur
    * @param contratsId Liste des Ids des users
    * @param contratsId True si les utilisateurs doivent être activés (avant modifs des ressources de service) ou doivent être désactivés (avant anonymisation)
    * @param dateDesacByUser Map contenant les dates de désactivation des utilisateurs (récupéré de QA_AsyncObfuscateFSLDatas)
    * @return QA_AsyncObfuscateUser Classe QA_AsyncObfuscateUser
    */
    public QA_AsyncObfuscateUser(List<User> userList, Boolean doActive, Map<Id, Datetime> dateDesacByUser, Boolean deleteLDP) {
        this.userList= userList;
        this.doActive = doActive;
        this.dateDesacByUser = dateDesacByUser;
        this.deleteLDP = deleteLDP;
    }
    
    /**
    * @description Fonction principal d'exécution du batch Queueable
    * Méthode asynchrone pour faire appel au WS WebCallback d'Odigo pour envoyer une tâche d'appel (callback)
    * @param context Context du batch
    */
    public void execute(QueueableContext context) {
        system.debug('### DEBUT QA_AsyncObfuscateUser');   
        system.debug('## userList: '+userList); 
        system.debug('## doActive: '+doActive); 

        if(deleteLDP){
            // Suppression des listes de phone de l'utilisateur réservés/associés à cet utilisateur afin que les comptes redeviennent disponibles pour d’autres listes de phone
            List<ListePhoningVendeur__c> listePhoningVendeurList = [SELECT Id FROM ListePhoningVendeur__c WHERE user__c IN :userList];
            if(!listePhoningVendeurList.isEmpty())
                delete listePhoningVendeurList;
        } else {
            List<User> userToUp = new List<User>();
            if(dateDesacByUser == null) 
                dateDesacByUser = new Map<Id, Datetime>();
            
            // Activation/Désactivation
            for(User usr : userList) {
                usr.IsActive = doActive;
                // Si réactivation des users, sauvegarde de la date de désactivation, sinon maj de la date
                if(doActive) {
                    dateDesacByUser.put(usr.Id, usr.dateDesactivation__c);
                } else {
                    usr.dateDesactivation__c = dateDesacByUser.get(usr.Id);
                }
                userToUp.add(usr);
            }        
            update userToUp;
            
            if(doActive) {        
                // Appel Async pour supprimer les ressources de service FSL
                system.debug('## Call QA_AsyncObfuscateFSLDatas'); 
                if(!Test.isRunningTest()) //Ajout pour éviter erreur lors des tests (impossible de chainer les job Queuable)
                    system.enqueueJob(new QA_AsyncObfuscateFSLDatas(userToUp, dateDesacByUser));
            } else {  
                // Supprime toutes les permissions et tous les liens aux groupes
                List<PermissionSetAssignment> permissionSetList = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId IN :userToUp 
                                                                        AND PermissionSetId IN (SELECT Id FROM PermissionSet WHERE IsOwnedByProfile =false)];
                List<PermissionSetLicenseAssign> permissionSetLicenseList = [SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId IN :userToUp ];

                system.debug('## permissionSetList: '+permissionSetList);
                system.debug('## permissionSetLicenseList: '+permissionSetLicenseList);
                if(!permissionSetList.isEmpty())
                    delete permissionSetList;
                if(!permissionSetLicenseList.isEmpty())
                    delete permissionSetLicenseList;
            
                // Anonymisation du champ email et des champs standard
                system.debug('## Anonymisation'); 
                for(User usr : userToUp){
                    try {
                        system.debug('## User:'+usr.Id); 
                        System.UserManagement.obfuscateUser(usr.Id);
                    } catch(Exception e) { }
                }
            }
        }
        system.debug('### FIN QA_AsyncObfuscateUser');   
    }
}