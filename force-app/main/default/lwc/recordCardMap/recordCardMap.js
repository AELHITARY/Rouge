/* eslint-disable no-console */
import { LightningElement, api, track, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Apex class methods
import getRecordLocAndInfos from '@salesforce/apex/LWC_RecordCardMap.getRecordLocAndInfos';
import getParentRecordLocAndInfos from '@salesforce/apex/LWC_RecordCardMap.getParentRecordLocAndInfos';
import getRelatedRecordLocAndInfos from '@salesforce/apex/LWC_RecordCardMap.getRelatedRecordLocAndInfos';
import getEntitiesLocAndInfos from '@salesforce/apex/LWC_RecordCardMap.getEntitiesLocAndInfos';
import getServiceTerritoryRecordLocAndInfos from '@salesforce/apex/LWC_RecordCardMap.getServiceTerritoryRecordLocAndInfos';
import getFSLMapPolygonInfos from '@salesforce/apex/LWC_RecordCardMap.getFSLMapPolygonInfos';
import forceRecordGeolocalisation from '@salesforce/apex/LWC_RecordCardMap.forceRecordGeolocalisation';
 
export default class RecordCardMap extends LightningElement {
    // Current object api name
    @api objectApiName;
    // Current record's id
    @api recordId;
    // Config data
    @api mapHeight = 320;
    @api popupTitleField;
    @api popupFields;
    @api salesEntityField;
    @api serviceEntityField;

    // Record data
    @track latitude;
    @track longitude;
    // Event data
    @track showLoadingSpinner = false;
    @track showForceLocalisationButton = false;
    @track center = false;
    @track error;
    @track mapObject;
    @track marker;
    
    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();        
        this.showLoadingSpinner = true;
        console.debug("RecordCardMap : constructor");
    }
    
    /* ========== WIRED METHODS ========== */

    /**
     * Retrieving the latitude/longitude of the record.
     */
    /*@wire(getLocalisation, { objectName: '$objectApiName', recordId: '$recordId' })
    localisation(result) {
        if (result.data) {
            this.latitude = result.data.latitude;
            this.longitude = result.data.longitude;
            
            this.error = undefined;

            // Creates the event with the contact ID data.
            const selectedEvent = new CustomEvent('update_record_marker', { latitude: this.latitude, longitude: this.longitude });
            // Dispatches the event.
            this.dispatchEvent(selectedEvent);

            this.template.querySelector('c-leaflet-map').addMarker('test', this.latitude, this.longitude);
        } else if (result.error) {
            this.latitude = undefined;
            this.longitude = undefined;
            this.processErrorMessage(result.error);
        }
    }*/

    /**
     * Function executed on the "oninitialized" of the leaflet map.
     */
    showLocalisations() {
        console.debug("RecordCardMap : showLocalisations");

        this.mapObject = this.template.querySelector('c-leaflet-map');
        // Record Localisation
        this.getRecordLocalisation();

        // Show Entities
        if(this.salesEntityField || this.serviceEntityField) {            
            this.getEntitiesRecordLocalisation();
        }

        // Display the force geolocalisation button    
        if(this.objectApiName === "Account" || this.objectApiName === "Contact" 
            || this.objectApiName === "Chantier__c" || this.objectApiName === "EntityVersion__c"
            || this.objectApiName === "Collaborator__c"
        ) {  
            this.showForceLocalisationButton = true;
        }

        // Get related localisations
        this.getRelatedLocalisationsAndSectors();
    }

    
    /**
     * Function executed to get related localisations.
     */
    getRelatedLocalisationsAndSectors() {
        // Show parent record for Entities and Providers
        if(this.objectApiName === "Account") {            
            this.getParentRecordLocalisation();
        }
        
        // Show ServiceTerritory Entities
        if(this.objectApiName === "WorkOrder" || this.objectApiName === "ServiceAppointment"
            || this.objectApiName === "ServiceResource" || this.objectApiName === "ServiceTerritoryMember"
        ) {
            this.getServiceTerritoryRecordLocalisation();
        }

        // Show FSL Sector
        if(this.objectApiName === "FSL__Polygon__c" || this.objectApiName === "ServiceTerritory" || this.objectApiName === "ServiceTerritoryMember") {               
            this.getFSLMapPolygon();
        }

        // Get related record
        if(this.objectApiName === "Order") {
            this.getRelatedRecordLocAndInfos("Account", "AccountId", "Name,KparKReference__c,rue__c,codePostal__c,ville__c","account.png");
            this.getRelatedRecordLocAndInfos("Chantier__c", "chantier__c", "Name,rue__c,codePostal__c,ville__c","chantier.png");
        }
    }
    
    /* ========== EVENT METHODS ========== */

    handleRefreshClick(event) {
        this.showLoadingSpinner = true;

        // Check if the map is the rendered
        if(this.mapObject && this.mapObject.leafletInitialized) {
            // Delete all markers
            this.mapObject.deleteAll();
            // Execute localisation process
            this.showLocalisations();
        }

        this.showLoadingSpinner = false;
    }

    handleForceLocalisationClick(event) {
        this.showLoadingSpinner = true;

        // Call APEX
        forceRecordGeolocalisation({ objectName: this.objectApiName, recordId: this.recordId })
        .then(result => {
            // Display a message
            this.showNotification("Géolocalisation", "Le processus de géolocalisation est en cours de traitement. Cela peut prendre du temps\nVous pouvez actualiser la carte en cliquant sur le second bouton.", 'success');
        })
        .catch(error => {
            this.processErrorMessage(error);
        });

        this.showLoadingSpinner = false;
    }

    /* ========== JS METHODS ========== */

    /**
     * Get the localisation of the record and call "addMarker" of the leafletMap component to add it.
     */
    getRecordLocalisation() {
        this.showLoadingSpinner = true;

        // Check if the map is the rendered
        if(this.mapObject && this.mapObject.leafletInitialized) {
            // Contruct additionnal fields
            let additionnalFields = this.processAdditionnalFields();
            // Call APEX
            getRecordLocAndInfos({ objectName: this.objectApiName, recordId: this.recordId, fields: additionnalFields })
            .then(result => {
                if (result) {                    
                    // Update latitude/longitude
                    this.latitude = result.latitude;
                    this.longitude = result.longitude;
                    let record = result.record;
                    if (this.latitude) {  // If there is a localisation
                        this.error = undefined;                    
                        // Call child function to add marker
                        this.marker = this.mapObject.addMarker(this.objectApiName, this.latitude, this.longitude);
                        this.center = true;
                        // Create Tooltip for the record
                        this.createTooltipForRecord(this.marker, record, this.popupTitleField, this.popupFields);
                    } else if(record.PostalCode && record.City) { // Geocode address
                        this.error = undefined;       
                        let address = record.Street + ' ' + record.PostalCode + ' ' + record.City;
                        //let point = this.geocodeAddress(address);
                        // Call child function to add marker
                        //this.marker = this.mapObject.addMarker(this.objectApiName, this.latitude, this.longitude);
                        // Create Tooltip for the record
                        //this.createTooltipForRecord(this.marker, record, this.popupTitleField, this.popupFields);
                    }
                }
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        } else {
            this.showLoadingSpinner = false;
        }
    }
    
    /**
     * Get the localisation of the parent record and call "addMarker" of the leafletMap component to add it.
     */
    getParentRecordLocalisation() {
        this.showLoadingSpinner = true;

        // Check if the map is the rendered
        if(this.mapObject && this.mapObject.leafletInitialized) {
            // Contruct additionnal fields
            let additionnalFields = this.processAdditionnalFields();
            // Call APEX
            getParentRecordLocAndInfos({ objectName: this.objectApiName, recordId: this.recordId, fields: additionnalFields })
            .then(result => {
                if (result) {                    
                    // Update latitude/longitude
                    let latitude = result.latitude;
                    let longitude = result.longitude;
                    let record = result.record;
                    if (latitude) {  // If there is a localisation
                        this.error = undefined;
                        // Call child function to add marker
                        let parentMarker = this.mapObject.addMarkerWithIcon('Parent', latitude, longitude, 'search_produit.png', false);
                        // Create tooltip for the record
                        this.createTooltipForRecord(parentMarker, record, this.popupTitleField, this.popupFields);
                    }
                }
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        } else {
            this.showLoadingSpinner = false;
        }
    }

    /**
     * Get the localisation of related record and call "addMarker" of the leafletMap component to add it.
     */
    getRelatedRecordLocAndInfos(relObjectName, relObjectField, fields, mapIcon) {
        this.showLoadingSpinner = true;

        // Check if the map is the rendered
        if(this.mapObject && this.mapObject.leafletInitialized) {
            // Call APEX
            getRelatedRecordLocAndInfos({ objectName: this.objectApiName, recordId: this.recordId, 
                                            relatedObjectName: relObjectName, relatedRecordField: relObjectField, fields: fields 
            })
            .then(result => {
                if (result) {                    
                    // Update latitude/longitude
                    let latitude = result.latitude;
                    let longitude = result.longitude;
                    let record = result.record;
                    if (latitude) {  // If there is a localisation
                        this.error = undefined;
                        // Call child function to add marker
                        let relatedMarker = this.mapObject.addMarkerWithIcon('Related'+relObjectName, latitude, longitude, mapIcon, false);
                        // Create Tooltip for the record
                        this.createTooltipForRecord(relatedMarker, record, 'Name', 'rue__c,codePostal__c,ville__c');
                    }
                }
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        } else {
            this.showLoadingSpinner = false;
        }
    }

    /**
     * Get the localisation of the entities records and call "addMarkerWithIcon" of the leafletMap component to add it.
     */
    getEntitiesRecordLocalisation() {
        this.showLoadingSpinner = true;

        // Check if the map is the rendered
        if(this.mapObject && this.mapObject.leafletInitialized) {
            // Contruct additionnal fields
            let additionnalFields = 'Name,KparKReference__c,rue__c,codePostal__c,ville__c';
            // Call APEX
            getEntitiesLocAndInfos({ objectName: this.objectApiName, 
                recordId: this.recordId, 
                salesEntityField: this.salesEntityField, 
                serviceEntityField: this.serviceEntityField, 
                fields: additionnalFields
            })
            .then(result => {
                if (result) {                   
                    // Loop on each entity record
                    for (let i = 0; i < result.length; i++){  
                        // Update latitude/longitude
                        let latitude = result[i].latitude;
                        let longitude = result[i].longitude;
                        let record = result[i].record;
                        if (latitude) {  // If there is a localisation
                            this.error = undefined; 
                            
                            // Call child function to add marker
                            let autoCenter = !(this.center);
                            let entityMarker = this.mapObject.addMarkerWithIcon('Entity', latitude, longitude, 'depot.png', autoCenter);
                            // Create Tooltip for the record
                            this.createTooltipForRecord(entityMarker, record, 'Name', 'KparKReference__c,rue__c,codePostal__c,ville__c');
                        }
                    } 
                }
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        } else {
            this.showLoadingSpinner = false;
        }
    }

    /**
     * Get the localisation of the service territory record and call "addMarkerWithIcon" of the leafletMap component to add it.
     */
    getServiceTerritoryRecordLocalisation() {
        this.showLoadingSpinner = true;

        // Check if the map is the rendered
        if(this.mapObject && this.mapObject.leafletInitialized) {
            // Contruct additionnal fields
            let additionnalFields = 'Name, Street, PostalCode, City';
            // Call APEX
            getServiceTerritoryRecordLocAndInfos({ objectName: this.objectApiName, 
                recordId: this.recordId, 
                fields: additionnalFields })
            .then(result => {
                if (result) {       
                    // Loop on each data
                    for (let i = 0; i < result.length; i++){ 
                        // Update latitude/longitude
                        let latitude = result[i].latitude;
                        let longitude = result[i].longitude;
                        let record = result[i].record;
                        if (latitude) {  // If there is a localisation
                            this.error = undefined;                    
                            // Call child function to add marker
                            let autoCenter = !(this.center);
                            let entityMarker = this.mapObject.addMarkerWithIcon('ServiceTerritory', latitude, longitude, 'depot.png', autoCenter);
                            // Create Tooltip for the record
                            this.createTooltipForRecord(entityMarker, record, 'Name', 'Street,PostalCode,City');
                        }
                    }
                }
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        } else {
            this.showLoadingSpinner = false;
        }
    }

    /**
     * Get the sector of the FSL Polygon record and call "addSectorPolygon" of the leafletMap component to add it.
     */
    getFSLMapPolygon() {
        this.showLoadingSpinner = true;

        // Check if the map is the rendered
        if(this.mapObject && this.mapObject.leafletInitialized) {
            // Call APEX
            getFSLMapPolygonInfos({ objectName: this.objectApiName, recordId: this.recordId })
            .then(result => {
                if (result) {       
                    // Loop on each sectors
                    for (let i = 0; i < result.length; i++){ 
                        let coords = result[i].latLongCoordinates;
                        let color = result[i].color;
                        if (coords) {  // If there is a localisation
                            this.error = undefined;                    
                            // Call child function to add sectors
                            let autoCenter = (this.objectApiName === "FSL__Polygon__c") ? true : false;
                            this.mapObject.addSectorPolygon(coords, color, true, autoCenter);
                        }
                    }
                }
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        } else {
            this.showLoadingSpinner = false;
        }
    }

    /**
     * Construct the additional fields variable.
     */
    processAdditionnalFields() {
        let result = '';
        // Check if popup fields are defined
        if(this.popupTitleField) {
            result += this.popupTitleField;
        }
        if(this.popupFields) { 
            result += ', ' + this.popupFields; 
        }
        return result;
    }

    /**
     * Get information of the record for tooltip.
     */
    createTooltipForRecord(marker, record, titleField, fields) {
        this.showLoadingSpinner = true;

        // Check if popup fields are defined
        if(titleField) {
            // Create the content of the tooltip       
            let dotPresentation = '<div id="dotPresentation">'
                                    +'<div class="dotPresentationDetail">'
                                    +'  <div class="dotPresentatioName" style="font-weight: bold !important;">'
                                    +      record[titleField] 
                                    +'  </div>'
            if(fields) {
                // For each fields, add these in the tooltip
                dotPresentation += '    <div class="dotPresentatioFields">';
                fields.split(',').forEach(function(field){
                    let fieldTrimed = field.trim();
                    if(record[fieldTrimed]) { // Check the value
                        dotPresentation +=     record[fieldTrimed] + '<br />';
                    }
                });
                dotPresentation += '    </div>';
            }
            dotPresentation +='</div></div>';
            // Define tooltip options
            let tooltipOptions = {
                'maxWidth': '500',
                'className' : 'custom-popup'
            };                    
            // Add the popup on the marker
            this.mapObject.addPopupOnMarker(marker, dotPresentation, tooltipOptions);
        } 
        this.showLoadingSpinner = false;
    }
    
    /**
     * Function to geocode address to get latitude/longitude
     * @param {string} address - Address to geocode.
     * @return pointCoords Latitude/longitude.
     */
    geocodeAddress(address) {
        let pointCoords = this.mapObject.geocodeAddress(address, function(result) {
            if(result && result.length != 0) {
                var coords = result[0].center;
                return coords;
            }
        });

        return pointCoords;
    }

    /*
     * Get the error message in different object.
     */
    processErrorMessage(error, showToast = true) {
        let message = 'Unknown error';
        if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (typeof error === 'string') {
            message = error;
        } else if (typeof error.message === 'string') {
            message = error.message;
        } else if (typeof error.body.message === 'string') {
            message = error.body.message;
        }
        this.error = message;
        if(showToast) {
            this.showNotification('Erreur', message, 'error');
        }
        console.log(message);
        this.showLoadingSpinner = false;
    }
    
    /**
     * Reset the error message.
     */
    resetErrorMessage() {
        this.error = "";
    }

    /**
     * Show a notification (Toast).
     */
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

}