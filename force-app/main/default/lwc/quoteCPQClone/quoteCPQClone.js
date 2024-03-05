import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import cloneQuote from '@salesforce/apex/LWC_QuoteCPQClone.cloneQuote';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class QuoteCPQClone extends NavigationMixin(LightningElement) {
    @api recordId;
    @track showLoadingSpinner = false;

    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        // Init body
        this.showLoadingSpinner = false;
    }

    /* ========== EVENT METHODS ========== */

    handleSave() {
        // Reset the error
        this.resetErrorMessage();
        // Process
        this.cloneQuoteCPQ();
    }
    
    /* ========== JS METHODS ========== */
    
    /**
     * Function to clone the quote.
     */
    cloneQuoteCPQ(){
        this.showLoadingSpinner = true;
        // Call APEX method to execute the API
        cloneQuote({recordId : this.recordId})
        .then(resultId => {
            if (resultId) {   
                // Show success messsage
                this.showNotification('Clonage devis', "Le devis a été cloné avec succès", 'success');
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