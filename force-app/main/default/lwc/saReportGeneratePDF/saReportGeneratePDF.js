import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

import renderDocumentPDF from '@salesforce/apex/LWC_SAReportGeneratePDF.renderSADocumentPDF';

const FIELDS = ['ServiceAppointment.AppointmentNumber'];

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
 
export default class SaReportGeneratePDF extends NavigationMixin(LightningElement) {
    @api recordId;
    @track saRecord;
    @track saNumber;
    @track documentName;
    @track showLoadingSpinner = false;
    @track showForm = false;

    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        // Init body
        this.showForm = false;
        this.showLoadingSpinner = true;
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(result) {
        // Hold on to the provisioned value so we can refresh it later.
        this.record = result; // track the provisioned value
        const { data, error } = result; // destructure the provisioned value
        if (error) {
            this.processErrorMessage(error);
        } else if (data) {
            // Set the record
            this.saRecord = data;
            this.saNumber = this.saRecord.fields.AppointmentNumber.value;
            // Define the doc name
            this.defineDocumentName();            
            this.showLoadingSpinner = false;
        }
    }

    /* ========== EVENT METHODS ========== */

    handleSave() {
        // Reset the error
        this.resetErrorMessage();
        // Check value of the input
        if(this.checkFields()) {
            this.generatePDF();
        }
    }

    /**
     * Handle a change on the "Document Name" field
     * @param {object} event - Object of the Event.
     */	
     handleDocumentNameChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.documentName = event.target.value;     
    }
    
    /* ========== JS METHODS ========== */
    
    /**
     * Function to execute the Merkure API to generate the PDF or display the existing document.
     */
    generatePDF(){
        this.showLoadingSpinner = true;
        // Call APEX method to execute the API
        renderDocumentPDF({recordId : this.recordId, filename : this.documentName})
        .then(resultId => {
            if (resultId) {   
                // Show success messsage
                this.showNotification('PV PDF', "Le PDF a été généré et sauvegardé avec succès", 'success');
                // Open PDF Preview
                this.viewPdf(resultId);
                // Close the quick action
                this.closeQuickAction();
            }
            this.showLoadingSpinner = false;
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
    }

    /**
     * Function to view the standard preview page to display the PDF.
     * @param {string} cDocumentId - Id of the ContentDocument.
     */
    viewPdf(cDocumentId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state : {
                recordIds: cDocumentId 
            }
        });
    }

    /**
     * Function to close the quick action.
     */
    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }

    /**
     * Function to define the PDF document name.
     */
     defineDocumentName(){
        const dateToUse = new Date().toLocaleDateString('fr').split('/').reverse().join('/'); // Use the format yyyy/MM/dd;
        // Document Name
        this.documentName = 'PV ' + this.saNumber + ' ' + dateToUse;
    }

    /* ========== UTILITY METHODS ========== */   
    
    /**
     * Function to check all errors before the save action.
     */
    checkFields() {
        // Check if input fields are OK
        let result;
        const allValid = [...this.template.querySelectorAll('lightning-input')]
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
        console.error(error);
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