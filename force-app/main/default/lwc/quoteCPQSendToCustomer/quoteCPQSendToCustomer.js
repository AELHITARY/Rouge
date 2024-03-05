import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import sendQuoteCPQToCustomer from '@salesforce/apex/LWC_SendCPQQuote.sendPDF';

const FIELDS = ['SBQQ__Quote__c.SBQQ__Account__r.email__c'];

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class QuoteCPQSendToCustomer extends LightningElement {
    @api recordId;
    @track quoteCPQ;
    @track customerEmail;
    @track showLoadingSpinner = false;

    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        // Init body
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
            this.quoteCPQ = data;
            console.log(JSON.stringify(this.quoteCPQ));
            this.customerEmail = this.quoteCPQ.fields.SBQQ__Account__r.value.fields.email__c.value;
            // Spinner            
            this.showLoadingSpinner = false;
        }
    }

    /* ========== EVENT METHODS ========== */

    handleSave() {
        // Reset the error
        this.resetErrorMessage();
        // Process
        this.sendPDF();
    }
    
    /* ========== JS METHODS ========== */
    
    /**
     * Function to send the email.
     */
    sendPDF(){
        this.showLoadingSpinner = true;
        // Call APEX method to execute the API
        sendQuoteCPQToCustomer({recordId : this.recordId})
        .then(result => {
            if (result) {   
                // Show success messsage
                this.showNotification('Devis PDF', "Le PDF a été envoyé au client", 'success');
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
     * Function to close the quick action.
     */
    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }

    /* ========== UTILITY METHODS ========== */   

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