import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import sendInvoiceToCustomer from '@salesforce/apex/LWC_InvoiceSendToCustomer.sendInvoiceToCustomer';
import getAdvanceInvoice from '@salesforce/apex/LWC_InvoiceSendToCustomer.getAdvanceInvoice';

//Record fields
const INVOICE_FIELDS = ['Invoice__c.billingAccount__r.email__c', 'Invoice__c.status__c'];
const ACCPIECE_FIELDS = ['AccountingPiece__c.Id'];

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class InvoiceSendToCustomer extends LightningElement {
    // Current object api name
    @api objectApiName;
    // Current record's id
    @api recordId;
    @api documentType;
    @track invoiceId;
    @track invoiceStatus;
    @track customerEmail;
    @track showLoadingSpinner = false;

    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        // Init body
        this.customerEmail = '';
        this.showLoadingSpinner = true;
    }

    connectedCallback(){
        if(this.objectApiName === "Invoice__c") {
            this.fieldArray = INVOICE_FIELDS;
        } else if(this.objectApiName === "AccountingPiece__c") {
            this.fieldArray = ACCPIECE_FIELDS;
        } else {
            this.showLoadingSpinner = false;
        }
    }

    /**
     * Retrieving the data of the record.
     * More information : {@link https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.reference_wire_adapters_record_ui|getRecord on Salesforce Developers}
     * @param {string} recordId - Id of the record.
     * @param {string} fields - List of fields .
     */
    @wire(getRecord, { recordId: '$recordId', optionalFields: '$fieldArray'})
    wiredRecord(result) {
        // Hold on to the provisioned value so we can refresh it later.
        this.record = result; // track the provisioned value
        const { data, error } = result; // destructure the provisioned value
        if (error) {
            this.processErrorMessage(error);
        } else if (data) {
            // Check if Invoice or AccountingPiece
            if(this.objectApiName === "Invoice__c") {
                this.invoiceId = this.recordId;
                this.customerEmail = data.fields.billingAccount__r.value.fields.email__c.value;
                this.invoiceStatus = data.fields.status__c.value;
                this.showLoadingSpinner = false;
                if(this.documentType === 'Facture' && this.invoiceStatus === 'Acquittée') {
                    this.documentType = 'Facture acquittée';
                }
            } else if(this.objectApiName === "AccountingPiece__c") {
                this.getAdvanceInvoice(); // Get AccountingPiece by doing a SOQL
            } 
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
        sendInvoiceToCustomer({recordId : this.recordId, docType : this.documentType})
        .then(result => {
            if (result) {   
                // Show success messsage
                this.showNotification('Facture PDF', "Le PDF a été envoyé au client", 'success');
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
     * Function to get the Advance Invoice by an Accounting piece.
     */
    getAdvanceInvoice(){
        this.showLoadingSpinner = true;
        // Call APEX method to execute the API
        getAdvanceInvoice({accPieceId : this.recordId})
        .then(result => {
            if (result) {   
                this.invoiceId = result.value;
                this.customerEmail = result.billingAccount__r.email__c;
            } else {
                this.processErrorMessage("Il n'existe pas de facture d'acompte!");
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