({
    /**
     * Effectue une RAZ des champs d'ajout/de modification des règles.
     * @param cmp - Object du composant Lightning principal.
     */    
    resetData: function (cmp) {
        this.displayError("",cmp);
        cmp.set("v.objetPrincipal", "");
        cmp.set("v.objetJointure", "");
        cmp.set("v.picklistVal_ChampsExclus", "");
        cmp.set("v.picklistVal_ChampJointure", "");
        cmp.set("v.defaultOptions", []);
        cmp.set('v.defaultOptionsModif', []);
        cmp.set("v.defaultOptions2", []); 
        cmp.set('v.defaultOptions2Modif', []);
        if(cmp.find("propPriorite")) 
            cmp.find("propPriorite").set("v.value", "");
        if(cmp.find("propPrioriteModif")) 
            cmp.find("propPrioriteModif").set("v.value", "");
        if(cmp.find("propChampsExclus")) 
            cmp.find("propChampsExclus").set("v.value", "");
        if(cmp.find("propChampJointure")) 
            cmp.find("propChampJointure").set("v.value", "");
        if(cmp.find("propActif")) 
            cmp.find("propActif").set("v.checked", "");
        if(cmp.find("propActifModif")) 
            cmp.find("propActifModif").set("v.checked", "");
    },

    /**
     * Fonction pour récupérer la liste des règles.
     * @param cmp - Object du composant Lightning principal.
     * @param helper - Classe Helper du composant Lightning principal.
     */ 
	getMetadatas : function(cmp,helper) {
        this.toggleSpinner(true,cmp); // loading
		var action = cmp.get("c.getReglesExportationDeDonnees");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.metadatas", response.getReturnValue());
            } else if (state === "ERROR") {
                var errors = response.getError();
                helper.displayError("Erreur (getMetadatas) : " + errors[0].message,cmp);
            } else {
                var errors = response.getError();
                helper.displayError('Erreur inconnue, Etat: ' + response.state + ', erreur: ' + errors[0].message, cmp); // Show error message
            }
            helper.toggleSpinner(false,cmp); 
        });
        $A.enqueueAction(action);
	},

    /**
     * Fonction pour supprimer la règle sélectionnée.
     * @param cmp - Object du composant Lightning principal.
     * @param event - Event du composant Lightning principal.
     * @param helper - Classe Helper du composant Lightning principal.
     */ 
    deleteMetadata : function(cmp, event, helper) {
        this.toggleSpinner(true,cmp); // loading
        var action = cmp.get("c.deleteMetadataById");
        action.setParams({
            "metadataId":event.getSource().get("v.name")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.getMetadatas(cmp,helper); // Reload Data
            } else if (state === "ERROR") {
                var errors = response.getError();
                helper.displayError("Erreur (deleteMetadata) : " + errors[0].message,cmp);
            } else {
                var errors = response.getError();
                helper.displayError('Erreur inconnue, Etat: ' + response.state + ', erreur: ' + errors[0].message, cmp); // Show error message
            }
            helper.toggleSpinner(false,cmp); 
        });
        $A.enqueueAction(action);
	},

    getStructure : function(cmp, event, helper, objectName) {
        this.toggleSpinner(true,cmp); // loading
        var action = cmp.get("c.getObjectStructure");
        action.setParams({
            "sObjectName": objectName
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultat = response.getReturnValue();
                for(var etape=0;etape<resultat.length;etape++){
                    console.log('OBJET '+resultat[etape].sObjectName);
                    console.log('CHAMP '+resultat[etape].sObjectRelationFields+' RELIE AU PARENT '+ resultat[etape].parentName);
                    console.log('***************');
                }
                cmp.set("v.metadataStructure", response.getReturnValue());
            } else if (state === "ERROR") {
                var errors = response.getError();
                helper.displayError("Erreur (getStructure) : " + errors[0].message,cmp);
            } else {
                var errors = response.getError();
                helper.displayError('Erreur inconnue, Etat: ' + response.state + ', erreur: ' + errors[0].message, cmp); // Show error message
            }
            helper.toggleSpinner(false,cmp); 
        });
        $A.enqueueAction(action);
    },
    
    setPickListObject : function(cmp, event, helper) {
        var action = cmp.get("c.populatePickListObject");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.picklistVal_NomObjet", response.getReturnValue());         
                cmp.set("v.picklistVal_ObjectNameList", response.getReturnValue());
            } else if (state === "ERROR") {
                var errors = response.getError();
                helper.displayError("Erreur (setPickListObject) : " + errors[0].message,cmp);
            } else {
                var errors = response.getError();
                helper.displayError('Erreur inconnue, Etat: ' + response.state + ', erreur: ' + errors[0].message, cmp); // Show error message
            }
            helper.toggleSpinner(false,cmp); 
        });
        $A.enqueueAction(action);
    },
    
    getFieldValues : function(cmp, event, helper, objectName) {
        // Init
        helper.toggleSpinner(true,cmp); 
        //cmp.set("v.picklistVal_ChampsExclus", "");
        // Call APEX action
        var action = cmp.get("c.populatePickListObjectField");
        action.setParams({
            "sObjectName": objectName
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var picklistVal = response.getReturnValue();
                var options = [];
                picklistVal.forEach(function(val)  {
                    options.push({ value: val, label: val});
                });
                cmp.set("v.picklistVal_ChampsExclus", options);
            } else if (state === "ERROR") {
                var errors = response.getError();
                helper.displayError("Erreur (getFieldValues) : " + errors[0].message,cmp);
            } else {
                var errors = response.getError();
                helper.displayError('Erreur inconnue, Etat: ' + response.state + ', erreur: ' + errors[0].message, cmp); // Show error message
            }
            helper.toggleSpinner(false,cmp); 
        });
        $A.enqueueAction(action);
    },
    
    getObjectDepedencies : function(cmp, event, helper, objectName) {
        // Init
        helper.toggleSpinner(true,cmp); 
        //cmp.set("v.picklistVal_ObjetJointure", "");
        var action = cmp.get("c.getObjectDepedencies");
        // Call APEX action
        action.setParams({
            "sObjectName": objectName
        });        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.picklistVal_ObjetJointure", response.getReturnValue());                
            } else if (state === "ERROR") {
                var errors = response.getError();
                helper.displayError("Erreur (getObjectDepedencies) : " + errors[0].message,cmp);
            } else {
                var errors = response.getError();
                helper.displayError('Erreur inconnue, Etat: ' + response.state + ', erreur: ' + errors[0].message, cmp); // Show error message
            }
            helper.toggleSpinner(false,cmp); 
        });
        $A.enqueueAction(action);
    },
    
    /**
     * Permet de définir la liste des champs de jointure disponible selon la relation parent/enfant.
     * @param cmp - Object du composant Lightning principal.
     * @param helper - Classe Helper du composant Lightning principal.
     * @param objectParentName - Nom de l'objet parent.
     * @param objectChildName - Nom de l'objet enfant.
     * @param defaultValues - Valeur par défaut renseigné (pour modification).
     */  
    objectJointChanged : function(cmp, helper, objectParentName, objectChildName, defaultValues) {
        if(objectParentName != "" && objectChildName != "") {
            // Init
            this.toggleSpinner(true,cmp); // loading      
            // Call APEX action
            var action = cmp.get("c.getObjectJointField");
            action.setParams({
                "objectParentName": objectParentName,
                "objectChildName": objectChildName
            });        
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    var picklistVal = response.getReturnValue();
                    // Construction de la picklist de valeur
                    var options = [];
                    picklistVal.forEach(function(val)  {
                        options.push({ value: val, label: val});
                    });
                    cmp.set("v.picklistVal_ChampJointure", options);    
                    // Si la relation ne dispose que d'un seul champ, sélection automatique du champ
                    if(options.length == 1) {    
                        var optUnique = []; optUnique.push(options[0].value);
                        cmp.set("v.defaultOptions2",optUnique);
                        cmp.set("v.defaultOptions2Modif",optUnique);
                    }            
                    // Si des valeurs par défaut (modification), ajout des valeurs sélectionné
                    if($A.util.isUndefinedOrNull(defaultValues) == false) {
                        cmp.set("v.defaultOptions2Modif",defaultValues);
                    }
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    helper.displayError("Erreur (objectJointChanged) : " + errors[0].message,cmp);
                } else {
                    var errors = response.getError();
                    helper.displayError('Erreur inconnue, Etat: ' + response.state + ', erreur: ' + errors[0].message, cmp); // Show error message
                }
                helper.toggleSpinner(false,cmp); 
            });
            $A.enqueueAction(action);
        }
    },
    
    /**
     * Méthode pour créer une ligne de règle d'export.
     * @param cmp - Object du composant Lightning principal.
     * @param event - Event du composant Lightning principal.
     * @param helper - Classe Helper du composant Lightning principal.
     */    
    newMetadata : function(cmp, event, helper) {
        this.toggleSpinner(true,cmp); // loading
        // Init        
        var priorite = cmp.find('propPriorite').get("v.value");
        var objetDeJointure = cmp.get('v.objetJointure');
        var champsExclusArray = cmp.find('propChampsExclus').get("v.value");
        var champDeJointureArray = cmp.get("v.defaultOptions2");
        var nomObjet = cmp.get('v.objetPrincipal');
        var actif = cmp.find('propActif').get("v.checked");
        var champsExclus = champsExclusArray.toString();
        var champDeJointure = champDeJointureArray.toString();
        
        // Vérifie des champs
        if(helper.checkFieldsValue(cmp, nomObjet,champsExclusArray,objetDeJointure,champDeJointureArray,actif,priorite)) {
            // Mise à jour si champ OK        
            var action = cmp.get("c.createCustomMetadata");
            action.setParams({
                "objetDeJointure": objetDeJointure,
                "priorite": priorite,
                "nomObjet": nomObjet,
                "actif": actif,
                "champsExclus": champsExclus,
                "champDeJointure": champDeJointure
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    helper.getMetadatas(cmp,helper); // Reload Data
                    cmp.set("v.showAddTable",false);
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    helper.displayError("Erreur (newMetadata) : " + errors[0].message,cmp);
                } else {
                    var errors = response.getError();
                    helper.displayError('Erreur inconnue, Etat: ' + response.state + ', erreur: ' + errors[0].message, cmp); // Show error message
                }
                helper.toggleSpinner(false,cmp); 
            });
            $A.enqueueAction(action);
        } else {
            helper.toggleSpinner(false,cmp);             
        }
    },
    
    /**
     * Récupère les informations d'une ligne de règle d'export.
     * @param cmp - Object du composant Lightning principal.
     * @param event - Event du composant Lightning principal.
     * @param helper - Classe Helper du composant Lightning principal.
     * @param metadataId - Id de la règle d'export à récupérer.
     */    
    getMetadataById : function (cmp, event, helper, metadataId) {
        var action = cmp.get("c.getMetadataById");
        action.setParams({
            "metadataId": metadataId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.metadataToModify", response.getReturnValue());
            } else if (state === "ERROR") {
                var errors = response.getError();
                helper.displayError("Erreur (getMetadataById) : " + errors[0].message,cmp);
            } else {
                var errors = response.getError();
                helper.displayError('Erreur inconnue, Etat: ' + response.state + ', erreur: ' + errors[0].message, cmp); // Show error message
            }
            helper.toggleSpinner(false,cmp); 
        });
        $A.enqueueAction(action);
    },
    
    /**
     * Modifie une ligne de règle d'export.
     * @param cmp - Object du composant Lightning principal.
     * @param event - Event du composant Lightning principal.
     * @param helper - Classe Helper du composant Lightning principal.
     * @param paramId - Id de la règle d'export à modifier.
     */    
    modifyMetadataById: function (cmp, event, helper, paramId) {
        this.toggleSpinner(true,cmp); // loading
        // Init        
        var priorite = cmp.find('propPrioriteModif').get("v.value");
        var objetDeJointure = cmp.get('v.objetJointure');
        var champsExclusArray = cmp.find('propChampsExclusModif').get("v.value");
        var champDeJointureArray = cmp.find('propChampJointureModif').get("v.value");
        var nomObjet = cmp.get('v.metadataToModify.nomObjet__c');
        var actif = cmp.find('propActifModif').get("v.checked");
        var champsExclus = champsExclusArray.toString();
        var champDeJointure = champDeJointureArray.toString();

        // Vérifie des champs
        if(helper.checkFieldsValue(cmp, nomObjet,champsExclusArray,objetDeJointure,champDeJointureArray,actif,priorite)) {
            // Mise à jour si champ OK        
            var action = cmp.get("c.modifyMetadataById");
            action.setParams({
                "metadataId": paramId,
                "objetDeJointure": objetDeJointure,
                "priorite": priorite,
                "nomObjet": nomObjet,
                "actif": actif,
                "champsExclus": champsExclus,
                "champDeJointure": champDeJointure
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    helper.getMetadatas(cmp, helper); // Reload Data
                    cmp.set("v.showAddTable",false);
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    helper.displayError("Erreur (modifyMetadataById) : " + errors[0].message,cmp);
                } else {
                    var errors = response.getError();
                    helper.displayError('Erreur inconnue, Etat: ' + response.state + ', erreur: ' + errors[0].message, cmp); // Show error message
                }
                helper.toggleSpinner(false,cmp); 
            });
            $A.enqueueAction(action);
        } else {
            helper.toggleSpinner(false,cmp);             
        }
    },
    
    /** 
     * Règles de vérification des champs.
     * @param cmp - Object du composant Lightning principal.
     * @param nomObjet - Nom de l'objet principal de la règle.
     * @param champsExclusArray - Liste des champs à exclure.
     * @param objetDeJointure - Objet de jointure.
     * @param champDeJointureArray - Liste des champs de jointure.
     * @param actif - true si la règles est active.     
     * @param priorite - Priorité de la règle.
     */
    checkFieldsValue: function (cmp, nomObjet, champsExclusArray, objetDeJointure, champDeJointureArray, actif, priorite) {
        // Init        
        var result = true;

        // Vérifie des champs
        if($A.util.isUndefinedOrNull(nomObjet) || nomObjet == "") {
            this.displayError("Veuillez définir le champ 'Nom de l'objet'" ,cmp);
        }
        if($A.util.isUndefinedOrNull(priorite) || priorite == "") {
            this.displayError("Veuillez remplir le champ Priorité", cmp);
            result = false;
        } 
        if($A.util.isUndefinedOrNull(objetDeJointure) == false && objetDeJointure != "" && champDeJointureArray.length == 0) {
            this.displayError("Veuillez sélectionner un champ de jointure" ,cmp);
        }
        if (nomObjet == "Account" && ($A.util.isUndefinedOrNull(objetDeJointure) || objetDeJointure == "")) {
            // Vérifie si le champ priorité est égale à 1 pour l'Account primaire
            if(priorite != "1") {
                this.displayError("La priorité doit être égale à 1 pour l'enregistrement d'export principal (Account parent)", cmp);
                result = false;
            }
            if(actif == false) {
                this.displayError("L'enregistrement d'export principal ne peut pas être désactivé", cmp);
                result = false;
            }
        } 
        if (nomObjet != "Account") {
            // Vérifie si le champ priorité est égale à 1 pour l'Account primaire
            if(priorite == "1") {
                this.displayError("Vous pouvez définir la priorité à 1 seulement pour l'enregistrement d'export principal (Account)", cmp);
                result = false;
            }
        } 
        return result;
    }, 
    
    /**
     * Affiche le spinner ou non.
     * @param display - true pour afficher le spinner.
     * @param cmp - Object du composant Lightning principal.
     */
    toggleSpinner: function (display, cmp) {
        cmp.set("v.spinner", display);
    },    
    
    /**
     * Affiche un message d'erreur.
     * @param msg - Message.
     * @param cmp - Object du composant Lightning principal.
     */
    displayError: function (msg, cmp) {
    	cmp.set("v.errorMsg", msg); // Show error message
        if(msg == "")
            cmp.set("v.showError", false);
        else
            cmp.set("v.showError", true);
        this.toggleSpinner(false,cmp); // loading
	}
})