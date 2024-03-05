import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import resetCustomerPassword from '@salesforce/apex/LWC_ResetCustomerPassword.resetCustomerPassword';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
 
export default class ResetCustomerPassword extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
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

    handleReset() {
        // Reset the error
        this.resetErrorMessage();
        // Reset
        this.resetPassword();
    }
    
    /* ========== JS METHODS ========== */
    
    /**
     * Function to execute the Merkure API to generate the PDF.
     */
    resetPassword(){
        this.showLoadingSpinner = true;
        // Call APEX method 
        resetCustomerPassword({recordId : this.recordId, objectName : this.objectApiName})
        .then(result => {
            if (result) {   
                // Show success messsage
                this.showNotification("Réinitialisation du mot de passe", result, 'success');
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