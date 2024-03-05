import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

import createQuoteAmendment from '@salesforce/apex/LWC_OrderAmendmentQuote.createQuoteAmendment';
import checkOrderItems from '@salesforce/apex/LWC_OrderAmendmentQuote.checkOrderItems';

const ORDER_FIELDS = ['Order.OrderNumber'];
const QUOTE_FIELDS = ['Quote.QuoteNumber', 'Quote.customerOrder__c', 'Quote.customerOrder__r.OrderNumber', 'Quote.customerOrder__r.isLocked__c', 'Quote.customerOrder__r.Status'];

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
 
export default class OrderAmendmentQuote extends NavigationMixin(LightningElement) {
    // Current object api name
    @api objectApiName;
    // Current record's id
    @api recordId;
    // Current record
    @track record;
    @track orderId;
    @track quoteName;
    @track fieldArray = [];
    @track isError = false;
    
    // Event data
    @track showLoadingSpinner = false;
    @track error;

    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        // Init body
        this.showLoadingSpinner = true;
        this.isError = false;
    }

    connectedCallback(){
        if(this.objectApiName === 'Order') {
            this.fieldArray = ORDER_FIELDS;
        } else {
            this.fieldArray = QUOTE_FIELDS;
        }
    }

    /* ========== WIRED METHODS ========== */

    /**
     * Retrieving the data of the record (Order or Quote).
     * More information : {@link https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.reference_wire_adapters_record_ui|getRecord on Salesforce Developers}
     * @param {string} recordId - Id of the record.
     * @param {string} optionalFields - List of fields .
     */
    @wire(getRecord, { recordId: '$recordId', optionalFields: '$fieldArray'})
    wiredRecord(result) {
        // Hold on to the provisioned value so we can refresh it later.
        this.record = result; // track the provisioned value
        const { data, error } = result; // destructure the provisioned value
        if (error) {
            this.processErrorMessage(error);
        } else if (data) {
            // Set the record
            this.record = data;
            const today  = new Date();
            this.quoteName = 'Avenant sur Commande-';
            // Define name depends on Order or Quote
            if(this.objectApiName === 'Order') {                
                this.quoteName = this.quoteName + this.record.fields.OrderNumber.value +'-'+ today.toLocaleDateString("fr-FR");
                this.orderId = this.recordId;
            } else {
                this.quoteName = this.quoteName + this.record.fields.customerOrder__r.value.fields.OrderNumber.value +'-'+ today.toLocaleDateString("fr-FR");
                this.orderId = this.record.fields.customerOrder__c.value;
                // If no order or order is locked/refused
                if(this.orderId === undefined) {
                    this.processErrorMessage("Le devis ne possède pas de commande client!");
                    this.isError = true;
                }
                if(this.record.fields.customerOrder__r.value.fields.Status.value === "Cancelled" || this.record.fields.customerOrder__r.value.fields.isLocked__c.value === true) {
                    this.processErrorMessage("La commande client ne doit pas être annulée ou suspendue!");
                    this.isError = true;
                }
            }
            this.checkOrderItems();
        }
    }

    /* ========== EVENT METHODS ========== */

    handleSave() {
        // Reset the error
        this.resetErrorMessage();
        // Check value of the input
        if(this.checkFields()) {
            this.generateAmendment();
        }
    }
    
    /* ========== JS METHODS ========== */
    
    /**
     * Function to check OrderItems.
     */
     checkOrderItems(){
        this.showLoadingSpinner = true;
        // Call APEX method 
        checkOrderItems({orderId : this.orderId})
        .then(result => {
            if (result) {   
                // Display error if orderitems are without qli
                this.processErrorMessage("Des lignes de commandes ne sont pas liés à des lignes de devis."+
                                    "\nMerci d'utiliser l'assistant 'Reprise Histo.' de la commande client");
                this.isError = true;
            }
            this.showLoadingSpinner = false;
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
    }

    /**
     * Function to create the amendment.
     */
    generateAmendment(){
        this.showLoadingSpinner = true;
        // Call APEX method to execute amendment process
        createQuoteAmendment({orderId : this.orderId, quoteName : this.quoteName})
        .then(resultId => {
            if (resultId) {   
                // Show success messsage
                this.showNotification('Avenant', "L'avenant a été créé avec succès", 'success');
                // Open record details page
                this.viewRecord(resultId);
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
     * Function to view the standard page of the record.
     * @param {string} recId - Id of the record.
     */
    viewRecord(recId) {
        // View the detail of the record.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                actionName: 'view'
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