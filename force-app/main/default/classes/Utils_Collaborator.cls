//-- -------------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : Utils_Collaborator
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 22/07/2022
//-- Version     : 1.0
//-- * 1.0 : Init
//-- -------------------------------------------------------------------------------------- --
public without sharing class Utils_Collaborator {

    /**
    * @description Méthode permettant de calculer le manager d'un collaborateur par rapport au entités de rattachement et au métier
    * @param collaborator Collaborateur dont le manager doit être calculé
    * @param dateRef Date de référence
    * @return Map<String, Collaborator__c> Retourne une map des managers : Key = Id du collaborateur, valeur = Objet manager
    */
    public static Collaborator__c getManager(Collaborator__c collaborator, Date dateRef) {
        Collaborator__c manager = null;
        Map<String, Collaborator__c> result = getManagerByJob(new List<Collaborator__c>{collaborator}, dateRef, null);
        if(!result.isEmpty()) {
            manager = result.values()[0];
        }
        return manager;
    }

    /**
    * @description Méthode permettant de calculer le manager de plusieurs collaborateurs par rapport au entités de rattachement et au métier
    * @param newCollaborators Liste des collaborateurs dont le manager doit être calculé
    * @param dateRef Date de référence
    * @return Map<String, Collaborator__c> Retourne une map des managers : Key = Id du collaborateur, valeur = Objet manager
    */
    public static Map<String, Collaborator__c> getManager(List<Collaborator__c> newCollaborators, Date dateRef) {
        return getManagerByJob(newCollaborators, dateRef, null);
    }
    
    /**
    * @description Méthode permettant de calculer le manager de plusieurs collaborateurs par rapport au entités de rattachement et au métier du manager recherché
    * @param newCollaborators Liste des collaborateurs dont le manager doit être calculé
    * @param dateRef Date de référence
    * @param managerJobToFind Type du métier du manager à trouver
    * @return Map<String, Collaborator__c> Retourne une map des managers : Key = Id du collaborateur, valeur = Objet manager
    */
    public static Map<String, Collaborator__c> getManagerByJob(List<Collaborator__c> newCollaborators, Date dateRef, String managerJobToFind) {
        System.debug('### DEBUT Utils_Collaborator.getManagerByJob');
        Map<String, CollaboratorContract__c> collaboratorContractsMap = new Map<String, CollaboratorContract__c>();
        Map<String, Collaborator__c> managerCollaboratorsMap = new Map<String, Collaborator__c>();
        Set<String> entitiesIds = new Set<String>();
        Set<String> jobsIds = new Set<String>();
        System.debug('## Date Ref: '+dateRef); 
        System.debug('## Metier du manager à rechercher: '+managerJobToFind); 
        
        // Récupération de la hierarchie des métiers
        Map<String, String> jobHierarchieMap = getJobHierarchy();
        System.debug('## jobHierarchieMap: '+jobHierarchieMap); 
        // Récupération de la hierarchie des entités
        Map<String, String> entityHierarchieMap = getEntityHierarchyId();
        System.debug('## entityHierarchieMap: '+entityHierarchieMap); 

        // Recherche du contrat actif du collaborateur C à la date date (si plusieurs contrats, il faut prendre le 1er contrat actif à la date D)
        // Objectifs: Récupérer l'entité et le métier du collaborateur C, ainsi que le métier de son manager
        List<CollaboratorContract__c> contractList = [SELECT Id, employedBy__c, job__c, job__r.jobHierarchy__r.parent__c, collaborator__c, startDate__c, endDate__c
                                                        FROM CollaboratorContract__c 
                                                        WHERE collaborator__c IN :newCollaborators ORDER BY startDate__c, signatureDate__c DESC];

        System.debug('## Recherche des contrats actifs'); 
        for(Collaborator__c collab : newCollaborators) {
            System.debug('## Collaborateur: '+collab.Id+' / '+collab.Name); 
            CollaboratorContract__c lastContract = null;
            Boolean hasActiveContract = false;
            // Récupère le contrat actif pour les collaborateurs
            for(CollaboratorContract__c cnt : contractList) {
                lastContract = cnt;
                if(collaboratorContractsMap.get(collab.Id) == null && cnt.startDate__c <= dateRef && (cnt.endDate__c == null || cnt.endDate__c >= dateRef)) {
                    System.debug('## Contrat actif: '+cnt);
                    collaboratorContractsMap.put(cnt.collaborator__c, cnt); 
                    hasActiveContract = true;
                }
            }
            // Si pas de contrat actif trouvé, on récupère le dernier
            if(!hasActiveContract) {
                System.debug('## Dernier contrat: '+lastContract);
                collaboratorContractsMap.put(collab.Id, lastContract); 
            }
        }
        
        // Récupère les entités et métier parent
        for(CollaboratorContract__c cnt : collaboratorContractsMap.values()) {
            if(cnt != null && String.isNotBlank(cnt.employedBy__c)) {
                entitiesIds.add(cnt.employedBy__c);
            }
            if(cnt != null && cnt.job__c != null && cnt.job__r.jobHierarchy__c != null && String.isNotBlank(cnt.job__r.jobHierarchy__r.parent__c)) {
                jobsIds.add(cnt.job__r.jobHierarchy__r.parent__c);
            }
        }
        // Si recherche d'un job en particulier, ajout dans la liste de recherche
        if(String.isNotBlank(managerJobToFind)) {
            jobsIds.add(managerJobToFind);
        }
        
        System.debug('## entitiesIds: '+entitiesIds);
        System.debug('## jobsIds: '+jobsIds);
        // Recherche de tous les contrats actifs à la date D sur l'entité du collaborateur et le métier du manager ou le métier du manager du manager (récursif)
        // Trie sur les métiers afin d'avoir les métiers du bas vers le haut
        List<CollaboratorContract__c> managersList = [SELECT id, employedBy__c, job__c, collaborator__c, collaborator__r.Id, job__r.jobHierarchy__r.Name,
                                                            collaborator__r.Name, collaborator__r.user__c, job__r.jobHierarchy__c, job__r.Name, employedBy__r.Name
                                                        FROM CollaboratorContract__c
                                                        WHERE (employedBy__c IN :entitiesIds OR employedBy__c IN :entityHierarchieMap.values())
                                                            AND (job__r.jobHierarchy__c IN :jobsIds OR job__r.jobHierarchy__c IN :jobHierarchieMap.values())
                                                            AND startDate__c <= :dateRef AND (endDate__c = null OR endDate__c >= :dateRef)
                                                        ORDER BY startDate__c DESC, signatureDate__c DESC, job__r.jobHierarchy__r.hierarchyLevel__c ASC];
                                                        
        System.debug('## managersList: '+managersList.size());

        // Calcul
        for(Collaborator__c collab : newCollaborators) {
            System.debug('## -------- Collaborateur: '+collab.Id+' / '+collab.Name); 
            Boolean hasManager = false;
            CollaboratorContract__c manager = null;
            // Récupère le contrat actif pour le collaborateur
            CollaboratorContract__c cntCollab = collaboratorContractsMap.get(collab.Id); 
            if(cntCollab != null) {
                // Récupère le manager par rapport au métier parent et à la meme entité
                // Si aucun manager ne peut être trouvé, alors la recherche est relancée depuis l'entité du collaborateur mais sur le manager du manager 
                // (ex: en l'absence d'un DV, le responsable d'un RV sera le DR, sinon le DO sinon le DE).
                // Et, ainsi de suite, jusqu'à l'obtention du manager où qu'il n'y ait plus de possibilité.
                // Récupère le manager par rapport au métier parent et par rapport à la meme entité
                System.debug('## --- Recherche sur l\'entité du collaborateur: '+cntCollab.employedBy__c);
                for(CollaboratorContract__c managerCnt : managersList) {
                    System.debug('## Potentiel: '+managerCnt.collaborator__c+' / '+managerCnt.collaborator__r.Name+' / '+managerCnt.job__r.Name+' / '
                                    +managerCnt.job__r.jobHierarchy__c+' / '+managerCnt.job__r.jobHierarchy__r.Name+' / '+managerCnt.employedBy__c+' / '+managerCnt.employedBy__r.Name); 
                    if(hasManager == false) {
                        manager = calculateManagerByJob(cntCollab.employedBy__c, cntCollab.job__r.jobHierarchy__c, cntCollab, managerCnt, jobHierarchieMap, true);
                        if(manager != null) {
                            // Si recherche par job du manager, on check le manager
                            if((String.isNotBlank(managerJobToFind) && manager.job__r.jobHierarchy__c == managerJobToFind) || String.isBlank(managerJobToFind)) {
                                managerCollaboratorsMap.put(collab.Id, manager.collaborator__r);
                                hasManager = true;
                                break;
                            }
                        }
                    }
                }
                // Recherche pas l'entité parente 
                if(hasManager == false) {
                    System.debug('## --- Recherche par entité parente');
                    for(CollaboratorContract__c managerCnt : managersList) {
                        System.debug('## Potentiel2: '+managerCnt.collaborator__c+' / '+managerCnt.collaborator__r.Name+' / '+managerCnt.job__r.Name+' / '
                                        +managerCnt.job__r.jobHierarchy__c+' / '+managerCnt.job__r.jobHierarchy__r.Name+' / '+managerCnt.employedBy__c+' / '+managerCnt.employedBy__r.Name); 
                        if(hasManager == false) {
                            manager = calculateManagerByEntity(cntCollab.employedBy__c, cntCollab.job__r.jobHierarchy__c, cntCollab, managerCnt, jobHierarchieMap, entityHierarchieMap);
                            if(manager != null) {
                                // Si recherche par job du manager, on check le manager
                                if((String.isNotBlank(managerJobToFind) && manager.job__r.jobHierarchy__c == managerJobToFind) || String.isBlank(managerJobToFind)) {
                                    managerCollaboratorsMap.put(collab.Id, manager.collaborator__r);
                                    hasManager = true;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            System.debug('## --------------------------------'); 
        }

        System.debug('## managerCollaboratorsMap: '+managerCollaboratorsMap);
        System.debug('### FIN Utils_Collaborator.getManagerByJob');
        return managerCollaboratorsMap;
    }
    
    /**
    * @description Méthode récurive permettant de vérifier le manager par rapport à la hiéarchie des entités et des métiers
    * @param entityId Id de l'entité
    * @param jobId Id du métier
    * @param collab Information du contrat du collaborateur
    * @param manager Information du contrat du manager potentiel
    * @param jobHierarchieMap Objet contenant la hiéarchie des métiers
    * @param entityHierarchieMap Objet contenant la hiéarchie des entités
    * @return CollaboratorContract__c Contrat du manager
    */
    private static CollaboratorContract__c calculateManagerByEntity(String entityId, String jobId, CollaboratorContract__c collab, CollaboratorContract__c manager, 
                                                                        Map<String, String> jobHierarchieMap, Map<String, String> entityHierarchieMap) {
        String entityParentId = entityHierarchieMap.get(entityId);
        if(String.isNotBlank(entityParentId)) {
            System.debug('## Recherche par l\'entité parente: '+entityParentId); 
            // Recherche le manager par rapport à l'entité parent et au métier parent, si trouvé, on retourne le manager
            CollaboratorContract__c managerFound = calculateManagerByJob(entityParentId, jobId, collab, manager, jobHierarchieMap, true);
            if(managerFound != null) {
                return managerFound;
            } else {
                // Sinon on effectue une récursivité sur l'entité
                return calculateManagerByEntity(entityParentId, jobId, collab, manager, jobHierarchieMap, entityHierarchieMap);
            }
        } else {
            return null;
        }
    }
    
    /**
    * @description Méthode récurive permettant de vérifier le manager par rapport à la hiéarchie des métiers
    * @param entityId Id de l'entité
    * @param jobId Id du métier
    * @param collab Information du contrat du collaborateur
    * @param manager Information du contrat du manager potentiel
    * @param jobHierarchieMap Objet contenant la hiéarchie des métiers
    * @return CollaboratorContract__c Contrat du manager
    */
    private static CollaboratorContract__c calculateManagerByJob(String entityId, String jobId, CollaboratorContract__c collab, CollaboratorContract__c manager, 
                                                                    Map<String, String> jobHierarchieMap, Boolean checkEmployedBy) {
        String jobParentId = jobHierarchieMap.get(jobId);
        if(String.isNotBlank(jobParentId)) {
            System.debug('## Recherche par hiearchie métier: '+jobParentId); 
            // Si le manager fait partie de l'entité et à le bon métier, on retourne le manager
            if(((checkEmployedBy && entityId == manager.employedBy__c) || !checkEmployedBy) && jobParentId == manager.job__r.jobHierarchy__c) {
                System.debug('## Manager: '+manager.collaborator__c+' / '+manager.collaborator__r.Name); 
                return manager;
            } else {
                // Sinon on effectue une récursivité sur le métier
                return calculateManagerByJob(entityId, jobParentId, collab, manager, jobHierarchieMap, checkEmployedBy);
            }
        } else {
            return null;
        }
    }
    
    /**
    * @description Méthode permettant de construire la hiéarchie des métiers
    * @return Map<String, String> Retourne une map des métiers : Key = Id hiéarchie métier, valeur = Id du parent
    */
    private static Map<String, String> getJobHierarchy() {
        Map<String, String> result = new Map<String, String>();
        String rtId = DAL.getRecordTypeIdByDevName('Referencial__c', Constants.REFERENCIAL_JOBHIERARCHY_RT);
        for(Referencial__c job : [SELECT Id, Name, jobHierarchy__c, jobHierarchy__r.parent__c , parent__c
                                    FROM Referencial__c WHERE RecordTypeId = :rtId AND parent__c != null 
                                    ORDER BY hierarchyLevel__c DESC]) {
            result.put(job.Id, job.parent__c);
        }
        return result;
    }


    /**
    * @description Méthode permettant de construire la hiéarchie des entités
    * @return Map<String, String> Retourne une map des entités : Key = Id entité, valeur = Id du parent
    */
    public static Map<String, String> getEntityHierarchyId() {
        Map<String, String> result = new Map<String, String>();
        String rtId = DAL.getRecordTypeIdByDevName('Account', Constants.ACCOUNT_ENTITY_RT);
        for(Account acc : [SELECT Id, Name, ParentId, Parent.Name FROM Account WHERE RecordTypeId = :rtId AND ParentId != null]) {
            result.put(acc.Id, acc.ParentId);
        }
        return result;
    }
}