import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import renderDocumentPDF from '@salesforce/apex/LWC_GlobalPipelineGeneratePDF.renderDocumentPDF';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class GlobalPipelineGeneratePDF extends NavigationMixin(LightningElement) {
    // Event data
    @track showLoadingSpinner = false;
    @track error;

    // non-reactive variables
    serviceEntityId;
    serviceEntityName;
    generationDate;
    orderStatusSelected = [];
    orderGroupStatusSelected;
    docFormat;

    // List of order group status available
    get orderGroupStatus() {
        return [
            { label: '-- Tous les statuts --', value: 'all' },
            { label: 'Non métrés', value: 'Non métrés' },
            { label: 'Non commandés', value: 'Non commandés' },
            { label: 'Non confirmés', value: 'Non confirmés' },
            { label: 'Non livrés', value: 'Non livrés' },
            { label: 'Non installés', value: 'Non installés' }
        ];
    }

    // List of order status available
    get orderStatus() {
        return [
            { label: 'Non métrable', value: 'Non métrable' },
            { label: 'Non métré non programmé', value: 'Non métré non programmé' },
            { label: 'Non métré programmé', value: 'Non métré programmé' },
            { label: 'Non commandable', value: 'Non commandable' },
            { label: 'Non commandé', value: 'Non commandé' },
            { label: 'Non confirmé', value: 'Non confirmé' },
            { label: 'Non livré non préparé', value: 'Non livré non préparé' },
            { label: 'Non livré non programmé', value: 'Non livré non programmé' },
            { label: 'Non livré programmé', value: 'Non livré programmé' },
            { label: 'Non installable', value: 'Non installable' },
            { label: 'Non installé non préparé', value: 'Non installé non préparé' },
            { label: 'Non installé non programmé', value: 'Non installé non programmé' },
            { label: 'Non installé programmé', value: 'Non installé programmé' }
        ];
    }

    // List of document format available
    get docFormatList() {
        return [
            { label: 'PDF', value: 'pdf' },
            { label: 'Excel', value: 'xlsx' }
        ];
    }

    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
    }

    connectedCallback() {
        // Init of the status available
        /*for (const status of this.orderStatus) {
            this.orderStatusSelected.push(status.value);
        }*/
        this.orderStatusSelected.push('Non métrable'); // Seulement non métrable
        // Init body
        this.orderGroupStatusSelected = 'all';
        this.docFormat = 'pdf';        
        this.generationDate = this.todaysDate;
    }

    /* ========== JS METHODS ========== */
    
    /**
     * Function to execute the Merkure API to generate the PDF.
     */
     generatePDF(){
        this.showLoadingSpinner = true;
        // Call APEX method to execute the API
        renderDocumentPDF({serviceEntityId : this.serviceEntityId, generationDate : this.generationDate,
                            orderStatus : this.orderStatusSelected, docFormat : this.docFormat})
        .then(resultId => {
            if (resultId) {   
                // Show success messsage
                this.showNotification('Pipeline', "Le document a été généré et sauvegardé avec succès", 'success');
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
     * Function to check all errors before each next step and before the creating of the Work Order.
     */
    checkForErrors() {
        let result = true;
        // Check if input fields are OK
        const allValid = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
        }, true);            
        if (!allValid) {             
            result = false;
        }
        // Check special rules
        if(this.isNullOrWhitespace(this.serviceEntityId)) {
            this.processErrorMessage('L\'information "Dépôt" est obligatoire !', false);
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

    /**
     * Function to close the quick action.
     */
    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }

    /**
     * Function to check if the value is null.
     */
    isNullOrWhitespace( input ) {
        return  !input || input.toString().replace(/\s/g, '').length < 1;
    }

    /* ========== EVENT METHODS ========== */

    handleSave() {
        // Reset the error
        this.resetErrorMessage();
        // Check value of the input
        if(this.checkForErrors()) {
            this.generatePDF();
        }
    }

    /**
     * Handle a change on the "Date de génération" field 
     * @param {object} event - Object of the Event.
     */	
     handleGenerateDateChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.generationDate = event.target.value;     
    }

    /**
     * Handle a change on the "Dépôt" field 
     * @param {object} event - Object of the Event.
     */
     handleServiceEntityLookupChange(event) {
        // Reset the error
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.serviceEntityId = selection[0].id;
            this.serviceEntityName = selection[0].title;
        } else {
            this.serviceEntityId = "";
            this.serviceEntityName = "";
        }
    }

    /**
     * Handle a change on the "Statuts" field 
     * @param {object} event - Object of the Event.
     */
    handleOrderStatusChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Update the variable
        this.orderStatusSelected = event.detail.value;
    }

    /**
     * Handle a change on the "Format du document" button 
     * @param {object} event - Object of the Event.
     */
    handleDocFormatChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Update the variable
        this.docFormat = event.detail.value;
    }

    /**
     * Handle a change on the "Groupe de Statuts" field 
     * @param {object} event - Object of the Event.
     */
    handleOrderGroupStatusChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Update the variable
        this.orderGroupStatusSelected = event.detail.value;
    }

    /* ========== GETTER METHODS ========== */

    get todaysDate() {
        return new Date().toISOString().slice(0, 10);
    }
}