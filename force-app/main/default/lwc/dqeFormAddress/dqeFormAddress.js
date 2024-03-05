/* eslint-disable no-console */
import { LightningElement, api, track, wire} from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import modifyRecordInformation from '@salesforce/apex/LWC_DQEFormAddress.modifyRecordInformation';

const ACCOUNT_FIELDS = ['Account.Id', 'Account.rue__c', 'Account.codePostal__c', 'Account.ville__c', 'Account.pays__c', 'Account.complementAdresse__c',
                        'Account.etage__c','Account.departement__c', 'Account.Localisation__Latitude__s', 'Account.Localisation__Longitude__s'];
const CHANTIER_FIELDS = ['Chantier__c.Id', 'Chantier__c.rue__c', 'Chantier__c.codePostal__c', 'Chantier__c.ville__c', 'Chantier__c.pays__c', 'Chantier__c.complementAdresse__c',
                        'Chantier__c.etage__c','Chantier__c.departement__c', 'Chantier__c.Localisation__Latitude__s', 'Chantier__c.Localisation__Longitude__s'];
const COLLABORATOR_FIELDS = ['Collaborator__c.Id', 'Collaborator__c.street__c', 'Collaborator__c.postalCode__c', 'Collaborator__c.city__c', 'Collaborator__c.country__c',
                        'Collaborator__c.state__c', 'Collaborator__c.localisation__Latitude__s', 'Collaborator__c.localisation__Longitude__s', 'Collaborator__c.addressComplement__c'];
const ENTITYVERS_FIELDS = ['EntityVersion__c.Id', 'EntityVersion__c.street__c', 'EntityVersion__c.postalCode__c', 'EntityVersion__c.city__c', 'EntityVersion__c.country__c',
                        'EntityVersion__c.geolocalisation__Latitude__s', 'EntityVersion__c.geolocalisation__Longitude__s', 'EntityVersion__c.addressSupplement__c'];

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class DQEFormAddress extends LightningElement {
    // Current object api name
    @api objectApiName;
    // Current record's id
    @api recordId; 
    // Current record
    @track record;

    @track street;
    @track postalcode;
    @track state;
    @track city;
    @track complementAddress;
    @track etage;
    @track country;
    @track longitude;
    @track latitude;

    // Event data
    @track displayComplementAddress;
    @track displayEtage;
    @track fieldArray;
    @track showLoadingSpinner = false;
    @track error;
    
    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        // Init body
        this.showLoadingSpinner = false;
        this.displayComplementAddress = false;
        this.displayNPAI = false;
        this.fieldArray = [];
		this.country = "FRANCE";
    }

    /**
     * Methode execute when the Lightning is loaded
     */
    connectedCallback() {
        //this.loadRecordObject();
        if(this.objectApiName === 'Account') {
            this.fieldArray = ACCOUNT_FIELDS;
            this.displayComplementAddress = true;
            this.displayEtage = true;
        } else if(this.objectApiName === 'Chantier__c') {
            this.fieldArray = CHANTIER_FIELDS;
            this.displayComplementAddress = true;
            this.displayEtage = true;            
        } else if(this.objectApiName === 'Collaborator__c') {
            this.fieldArray = COLLABORATOR_FIELDS;
            this.displayComplementAddress = true;
        } else if(this.objectApiName === 'EntityVersion__c') {
            this.fieldArray = ENTITYVERS_FIELDS;
            this.displayComplementAddress = true;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fieldArray' })
    wiredRecord(result) {
        // Hold on to the provisioned value so we can refresh it later.
        this.record = result; // track the provisioned value
        const { data, error } = result; // destructure the provisioned value
        if (error) {
            this.processErrorMessage(error);
        } else if (data) {
            // Set the record
            this.record = data;
            if(this.objectApiName === 'Account' || this.objectApiName === 'Chantier__c') {
                this.street = this.record.fields.rue__c.value;
                this.postalcode = this.record.fields.codePostal__c.value;
                this.state = this.record.fields.departement__c.value;
                this.city = this.record.fields.ville__c.value;
                this.complementAddress = this.record.fields.complementAdresse__c.value;
                this.etage = this.record.fields.etage__c.value;
                if(this.record.fields.pays__c.value != "") {
                    this.country = this.record.fields.pays__c.value;
                }
                this.latitude = this.record.fields.Localisation__Latitude__s.value;
                this.longitude = this.record.fields.Localisation__Longitude__s.value;
            }            
            if(this.objectApiName === 'Collaborator__c') {
                this.street = this.record.fields.street__c.value;
                this.postalcode = this.record.fields.postalCode__c.value;
                this.state = this.record.fields.state__c.value;
                this.city = this.record.fields.city__c.value;
                this.complementAddress = this.record.fields.addressComplement__c.value;
                if(this.record.fields.country__c.value != "") {
                    this.country = this.record.fields.country__c.value;
                }
                this.latitude = this.record.fields.localisation__Latitude__s.value;
                this.longitude = this.record.fields.localisation__Longitude__s.value;
            }
            if(this.objectApiName === 'EntityVersion__c') {
                this.street = this.record.fields.street__c.value;
                this.postalcode = this.record.fields.postalCode__c.value;
                this.city = this.record.fields.city__c.value;
                this.complementAddress = this.record.fields.addressSupplement__c.value;
                if(this.record.fields.country__c.value != "") {
                    this.country = this.record.fields.country__c.value;
                }
                this.latitude = this.record.fields.geolocalisation__Latitude__s.value;
                this.longitude = this.record.fields.geolocalisation__Longitude__s.value;
                
            }
            // Spinner            
            this.showLoadingSpinner = false;
        }
    }
    
    /* ========== EVENT METHODS ========== */

    /**
     * Function executed when a user click on "Enregistrer" button.
     * @param {object} event - Object of the Event.
     */	
    handleSave(event){
        // Reset the error
        this.resetErrorMessage();
        // Check fields and save if it's OK
        if(this.checkAddressFields()) {
            this.showLoadingSpinner = true;
            // Correct longitude/latitude if empty
            if(this.longitude == "") {
                this.longitude = null;
            }
            if(this.latitude == "") {
                this.latitude = null;
            }
            // Call APEX to save data
            modifyRecordInformation({objectAPIName : this.objectApiName, recordId : this.recordId, street : this.street, 
                                        zip : this.postalcode, state : this.state, city : this.city, country : this.country,
                                        longitude : this.longitude, latitude : this.latitude,
                                        complementAddress : this.complementAddress, etage : this.etage})
            .then(result => {
                this.showNotification("Modification de l'adresse", "L'adresse a été modifié avec succès", 'success');
                // Create the recordInput object
                const fields = {};
                fields["Id"] = this.recordId;
                const recordInput = { fields };
                // Refresh Detail Page
                updateRecord(recordInput);
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        }
    }

    /**
     * Function executed when a user select an address by the autcompletion component.
     * @param {object} event - Object of the Event.
     */	
    handleItemSelectedEvent(event){
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.city = event.detail.city;
        this.street = event.detail.street;
        this.postalcode = event.detail.zip;
        this.state = event.detail.state;
        this.country = event.detail.country;
        this.longitude = event.detail.longitude;
        this.latitude = event.detail.latitude;
    }

    /**
     * Function executed when a user changes an address input.
     * @param {object} event - Object of the Event.
     */	
    handleInputAddressChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.city = event.detail.city;
        this.street = event.detail.street;
        this.postalcode = event.detail.postalCode;
        this.state = event.detail.province;
        this.country = event.detail.country;
    }

    /**
     * Function executed when a user changes the complement address.
     * @param {object} event - Object of the Event.
     */	
    handleComplementAddressChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.complementAddress = event.target.value;     
    }

    /**
     * Function executed when a user changes the etage.
     * @param {object} event - Object of the Event.
     */	
    handleEtageChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.etage = event.target.value;     
    }
    
    /* ========== UTILITY METHODS ========== */    

    /**
     * Function to check all errors before the save action.
     */
    checkAddressFields() {
        // Check if input fields are OK
        let result;
        const allValid = [...this.template.querySelectorAll('lightning-input-address')]
        .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
        }, true);
        
        if (allValid) {                      
            result = true;
        } else {
            result = false;
        }
        return result;
    }

    /**
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