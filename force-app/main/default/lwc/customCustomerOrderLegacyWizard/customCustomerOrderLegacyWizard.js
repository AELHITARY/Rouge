/* eslint-disable no-console */
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

// Apex class methods
import getOrderItems from '@salesforce/apex/LWC_CustomCustomerOrderLegacyWizard.getOrderItems';
import getAllQuoteLines from '@salesforce/apex/LWC_CustomCustomerOrderLegacyWizard.getAllQuoteLines';
import updateOrderItems from '@salesforce/apex/LWC_CustomCustomerOrderLegacyWizard.updateOrderItems';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

//Record fields
const ORDER_FIELDS = ['Order.Id', 'Order.QuoteId'];

const PATH_STEPS = [
    { label: 'Sélection des lignes de devis', value: 'step-1', display: true },
    { label: 'Résumé', value: 'step-2', display: true }
];

export default class CustomCustomerOrderLegacyWizard extends LightningElement {
    // Current record's id
    @api recordId;
    // Current record
    @track record;
    
    //Wizard status
    @track activeWizard = true;
    @track showPreviousButton = false;
    @track showNextButton = true;
    @track currentStep = "step-1";
    @track steps = PATH_STEPS;  

    @track showStep1Form = true;
    @track showStep2Form = false;
    @track showSubmitButton = false;
    @track isPreviousState = false;

    // Datatable
    @track orderItemRecords = [];
    @track allQuoteLinesData = [];

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
        //this.showLoadingSpinner = true;
        //this.activeWizard = false;
        this.updateWizardBody();
        this.orderItemRecords = [];
        this.allQuoteLinesData = [];
    }

    connectedCallback(){
        this.fieldArray = ORDER_FIELDS;
    }

    /* ========== WIRED METHODS ========== */

    /**
     * Retrieving the data of the record.
     * More information : {@link https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.reference_wire_adapters_record_ui|getRecord on Salesforce Developers}
     * @param {string} recordId - Id of the record.
     * @param {string} fields - List of fields .
     */
    @wire(getRecord, { recordId: '$recordId', optionalFields: '$fieldArray'})
    wiredRecord({ error, data }) {
        if (error) {
            this.processErrorMessage(error);
        } else if (data) {
            // Set the record
            this.record = data;
        }
    }

    /**
     * Retrieving the products using wire service
     * @param {string} recordId - Id of the order.
     */
    @wire(getOrderItems, { recordId: '$recordId'})
    products(result) {
        if (result.data) {
            // Init the array of products
            this.orderItemRecords = [];     
            if(result.data.length !== 0) {
                this.orderItemRecords = JSON.parse(JSON.stringify(result.data));
                // Active the wizard
                this.activeWizard = true;
                // Get other informations
                this.getAllQuoteLines();
            } else {
                this.activeWizard = false;
                this.showLoadingSpinner = false;
            }
            this.error = undefined;
        } else if (result.error) {
            this.processErrorMessage(result.error);
            this.productsData = undefined;
        }
    }

    /* ========== JS METHODS ========== */

    /**
     * Function executed when the user click on the Previous/Next button to update the form.
     */
    updateWizardBody() {
        this.showStep1Form = false;
        this.showStep2Form = false;
        this.showPreviousButton = true;
        this.showNextButton = true;
        this.showSubmitButton = false;
        switch (this.currentStep) {
            case 'step-1':
                this.showStep1Form = true;
                this.showPreviousButton = false;
                break;
            case 'step-2':
                this.showStep2Form = true;
                this.showSubmitButton = true;
                this.showNextButton = false;
                break;
        }
    }

    /**
     * Retrieving the list of QuoteLineItems using wire service
     */
    getAllQuoteLines() {
        try {
            this.showLoadingSpinner = true;
            // Init
            this.allQuoteLinesData = [];
            // Call APEX method to get quote lines
            if(this.orderItemRecords) {
                getAllQuoteLines({ recordId: this.recordId})
                .then(result => {
                    // If quote lines, we set the table
                    if (result.length !== 0) {
                        this.allQuoteLinesData = JSON.parse(JSON.stringify(result)); 
                    }
                    this.showLoadingSpinner = false;
                })
                .catch(error => {
                    this.processErrorMessage(error);
                });
            }
        } catch(error) {
            this.processErrorMessage(error.message);
        }
    }

    /**
     * Function to call "updateOrderItems" APEX method.
     */
    updateOrderItems(){
        try{
            // Create MAP of OrderItem/QLI
            const parameters = {};
            for(const line of this.orderItemRecords) {
                parameters[line.id] = line.qliId;
            }
            // Call APEX
            updateOrderItems({recordId: this.recordId, orderItemsRec: parameters}).
            then(result => {
                if (result) {
                    this.showNotification('Lignes de commandes modifiées', "Les lignes de commandes ont bien été modifiées.", 'success');
                    // Close the quick action
                    this.closeQuickAction();
                }
                else{
                    this.showNotification('Erreur', "Les modifications n'ont pas pu être enregistrées.", 'error');
                }
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        }
        catch(error) {
            this.processErrorMessage(error.message);
        }
    }
    
    /**
     * Function to check all errors before each next step and before the creating of the Work Order.
     */
    checkForErrors() {
        let result = true;
        if(this.currentStep === 'step-1') {
            // Check if input fields are OK
            const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
            }, true);            
            if (!allValid) {             
                result = false;
            }

            /*if (this.selectedProviders.length === 0 && this.selectedProvidersWithUnknown.length === 0) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner un fournisseur au minimum pour un produit", false);
            } */
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
            variant: variant
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
    
    /**
     * Display the previous step of the wizard.
     * Executed when the user clicks on the "Précédent" button of the wizard.
     */
     handlePrevious() {
        this.resetErrorMessage();

        // Get the previous step in the array
        let currentStage = this.currentStep;
        // If is not the first step
        if(currentStage !== this.steps[0].value) {
            const currIndex = this.steps.findIndex(x => x.value === currentStage); // Get the index in the array of the step
            // If the step is display, display it else jump in the previous step
            if(this.steps[currIndex-1].display === true) {
                currentStage = this.steps[currIndex-1].value;
            } else {
                currentStage = this.steps[currIndex-2].value;
            }
            this.currentStep = currentStage;
        } 
        // Update the form to show the previous step
        this.isPreviousState = true;
        this.updateWizardBody();
    }

    /**
     * Display the next step of the wizard.
     * Executed when the user clicks on the "Suivant" button of the wizard.
     */
    handleNext() {
        this.resetErrorMessage();

        // if errors on step on input fields, then no display next page
        if(this.checkForErrors()) {        
            // Get the next step in the array
            let currentStage = this.currentStep;      
            // Define the next step
            const arrayLength = this.steps.length;
            // If is not the last step
            if(currentStage !== this.steps[arrayLength-1].value) {
                const currIndex = this.steps.findIndex(x => x.value === currentStage); // Get the index in the array of the step
                // If the step is display, display it else jump in the next step
                if(this.steps[currIndex+1].display === true) {
                    currentStage = this.steps[currIndex+1].value;
                } else {
                    currentStage = this.steps[currIndex+2].value;
                }
                this.currentStep = currentStage;
            } 
            // Update the form to show the next step
            this.isPreviousState = false;
            this.updateWizardBody();
        }
    }

    /**
     * Set the value of the quoteline picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
    handleChangeQuoteLineValue(event) {
        for(const line of this.orderItemRecords) {
            if(line.id === event.target.name) {
                line.qliId = event.target.value;
                line.qliName = event.target.options.find(opt => opt.value === event.detail.value).label;
            }
        }
    }

    /**
     * Create the orderItems when the users click on "Valider"
     */
    handleUpdateOrderItems(){
        this.resetErrorMessage();
        this.showLoadingSpinner = true;
        // Check errors, continue if no errors
        if(this.checkForErrors()) {
            this.updateOrderItems();
        }
    }
        
}