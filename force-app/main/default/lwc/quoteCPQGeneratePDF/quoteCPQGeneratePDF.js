import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

import renderQuoteDocumentPDF from '@salesforce/apex/LWC_QuoteCPQGeneratePDF.renderQuoteDocumentPDF';

const FIELDS = ['SBQQ__Quote__c.NDevis__c'];

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
 
export default class QuoteCPQGeneratePDF extends NavigationMixin(LightningElement) {
    @api recordId;
    @api documentType;
    @track quote;
    @track title;
    @track documentName;
    @track showLoadingSpinner = false;

    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        // Init body
        this.checkboxSaveDocument = false;
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
            this.quote = data;
            // Define all variables of the component
            this.defineVariables();
            // Spinner            
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
     * Function to define variables.
     */
     defineVariables(){
        const today  = new Date();
        // Define the document name and the title
        let prefDocName;
        if(this.documentType.toLowerCase().includes('dip')) {
            prefDocName = "DIP";
            this.title = "du DIP";
        } else if(this.documentType.toLowerCase().includes('contrat')) {
            prefDocName = "Contrat";
            this.title = "du contrat";
        } else if(this.documentType.toLowerCase().includes('tva')) {
            prefDocName = "Attestation TVA";
            this.title = "de l'attestation de TVA";
        }else if(this.documentType.toLowerCase().includes('devis sav')) {
            prefDocName = "Devis SAV";
            this.title = "du devis SAV"; 
        } else {
            prefDocName = 'Devis';
            this.title = "du devis";
        }
        this.documentName = prefDocName + ' ' + this.quote.fields.NDevis__c.value + ' - ' + today.toLocaleDateString("fr-FR");
    }
    
    /**
     * Function to execute the Merkure API to generate the PDF.
     * Asynchronous function because Callout
     */
    async generatePDF(){
        this.showLoadingSpinner = true;
        try {
            // Call APEX method to execute the API
            const resultId = await renderQuoteDocumentPDF({recordId : this.recordId, filename : this.documentName, docType : this.documentType});
            if (resultId && resultId === 'SizeLimit') {   
                // Show success messsage
                this.showNotification("PDF "+this.title, "Le processus de génération a pris trop de temps, une notification vous sera envoyée quand le fichier sera prêt", "success");
                // Close the quick action
                this.closeQuickAction();
            } else if (resultId) {   
                // Show success messsage
                this.showNotification("PDF "+this.title, "Le PDF a été généré et sauvegardé avec succès", "success");
                // Open PDF Preview
                this.viewPdf(resultId);
                // Close the quick action
                this.closeQuickAction();
            }
            this.showLoadingSpinner = false;
        } catch(error) {
            this.processErrorMessage(error);
        }
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