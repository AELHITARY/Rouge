({
    /**
    * Action de création d'un nouveau RDV de prospection selon la ligne du tableau de RDV de service
    * @param cmp - Object du composant Lightning principal.
    * @param event - Event du composant Lightning principal.
    * @param helper - Classe Helper du composant Lightning principal.
    */
	openCreateEventPage : function(cmp, event, helper) {
		var endDate;

		//get the row where click happened and its position
		var clickedRow = event.getParam('row');
		var startDate = clickedRow.SchedStartTime;
		endDate = clickedRow.SchedEndTime;
		var dateDebut = new Date(clickedRow.SchedStartTime);
		var dateFin = new Date(clickedRow.SchedEndTime);
		var diffTime = Math.abs(dateFin.getTime() - dateDebut.getTime());
		var diffMinutes = Math.ceil(diffTime / (1000 * 60)); 
		if(diffMinutes > 60){
			var dateFinForcee = new Date(dateDebut.getTime() + (1000 * 60 * 60));
			endDate = dateFinForcee.toISOString();
		}
		var typeRDV = 'Visite de pose';
		if(clickedRow.Chantier__r) {
			var rue = clickedRow.Chantier__r.rue__c;
			var cp = clickedRow.Chantier__r.codePostal__c;
			var ville = clickedRow.Chantier__r.ville__c;
		}
		var lat = clickedRow.Latitude;
		var long = clickedRow.Longitude;
		if(clickedRow.ContratK__r.devis__c != undefined){
			var projetId = clickedRow.ContratK__r.devis__r.OpportunityId;
		}
		var contactId = clickedRow.Contact.Id;
		var vendeur = cmp.get("v.userInfo");
		var rtId = cmp.get("v.eventProspectionRTId");

		var url = '/lightning/o/Event/new?recordTypeId='+rtId+'&retURL=%2Fapex%2FVF_Calendrier&defaultFieldValues=';
		url += "Type="+typeRDV;
		// Adresse
		if(rue) url += ",rue__c="+encodeURIComponent(rue);
		if(cp) url += ",codePostal__c="+cp;
		if(ville) url += ",ville__c="+encodeURIComponent(ville);
		if(lat) url += ",localisation__Latitude__s="+lat;//.toString().replace('.',','); //remplacement du point par une virgule
		if(long) url += ",localisation__Longitude__s="+long;//.toString().replace('.',','); //remplacement du point par une virgule
		// Client (Nom)
		url += ",WhoId="+contactId;
		// Projet (Associé à)
		if(projetId){  
			url += ",WhatId="+projetId;
		}
		// Vendeur
		url += ",OwnerId="+vendeur.Id;
		// Date et heure
		url += ",StartDateTime="+startDate; // Date
		url += ",EndDateTime="+endDate; // Time
		window.open(url, '_blank');  

		/** // OLD
		 * var clickedRow = event.getParam('row');
            var formattedDay = $A.localizationService.formatDate(clickedRow.SchedStartTime, "DD/MM/YYYY");
            var formattedStartHour = $A.localizationService.formatDate(clickedRow.SchedStartTime, "HH:mm");
            var formattedEndHour = $A.localizationService.formatDate(clickedRow.SchedEndTime, "HH:mm");
            var dateDebut = new Date(clickedRow.SchedStartTime);
            var dateFin = new Date(clickedRow.SchedEndTime);
            var diffTime = Math.abs(dateFin.getTime() - dateDebut.getTime());
            var diffMinutes = Math.ceil(diffTime / (1000 * 60)); 
            if(diffMinutes > 60){
                var dateFinForcee = new Date(dateDebut.getTime() + (1000 * 60 * 60));
                formattedEndHour = $A.localizationService.formatDate(dateFinForcee, "HH:mm");
            }
            var typeRDV = 'Visite de pose';
            var rue = clickedRow.Chantier__r.rue__c;
            var cp = clickedRow.Chantier__r.codePostal__c;
            var ville = clickedRow.Chantier__r.ville__c;
            var lat = clickedRow.Latitude;
            var long = clickedRow.Longitude;
            if(clickedRow.ContratK__r.devis__c != undefined){
            	var projetId = clickedRow.ContratK__r.devis__r.OpportunityId;
            	var projetName = clickedRow.ContratK__r.devis__r.Opportunity.Name;
            }
            var contactId = clickedRow.Contact.Id;
            var contactName = clickedRow.Contact.Name;
            var vendeur = cmp.get("v.userInfo");
            var rtId = cmp.get("v.eventProspectionRTId");

            var url = '/00U/e?RecordType='+rtId+'&retURL=%2Fapex%2FVF_Calendrier';
            url += "&evt10="+typeRDV;
            // Adresse
            if(rue) url += "&00ND00000034daw="+encodeURIComponent(rue);
            if(cp) url += "&00ND00000034dau="+cp;
            if(ville) url += "&00ND00000034dax="+encodeURIComponent(ville);
            if(lat) url += "&0BCD0000000XZNa="+lat.toString().replace('.',','); //remplacement du point par une virgule
            if(long) url += "&0BCD0000000XZNb="+long.toString().replace('.',','); //remplacement du point par une virgule
            // Client (Nom)
            url += "&evt2_lkid="+contactId.substring(0,15); //ID en 15 sinon erreur
            url += "&evt2="+encodeURIComponent(contactName);
            // Projet (Associé à)  
            if(clickedRow.ContratK__r.devis__c != undefined){  
            	url += "&evt3_lkid="+projetId.substring(0,15); //ID en 15 sinon erreur
            	url += "&evt3="+encodeURIComponent(projetName);
            }
            // Vendeur
            url += "&evt1_lkid="+vendeur.Id.substring(0,15); //ID en 15 sinon erreur
            url += "&evt1="+encodeURIComponent(vendeur.Name);
            // Date et heure
            url += "&evt4="+formattedDay; // Date
            url += "&StartDateTime_time="+formattedStartHour; // Time
            url += "&EndDateTime_time="+formattedEndHour; // Time
            console.log(url);
            window.open(url, '_blank');    
		*/
    }
})