import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

// Apex class methods
import createRefundRequestPiece from '@salesforce/apex/LWC_RefundRequestWizard.createRefundRequestPiece';
import getDefaultPaymentMethod from '@salesforce/apex/LWC_RefundRequestWizard.getDefaultPaymentMethod';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

//Record fields
const CREDITMEMO_FIELDS = ['CreditMemo__c.Id','CreditMemo__c.Name','CreditMemo__c.refundReason__c', 'CreditMemo__c.refundReason__r.Name',
                            'CreditMemo__c.customerOrder__c', 'CreditMemo__c.customerOrder__r.serviceEntity__c', 'CreditMemo__c.customerOrder__r.serviceEntity__r.Name', 
                            'CreditMemo__c.creditMemoDate__c', 'CreditMemo__c.amount__c'];

export default class RefundRequestWizard extends NavigationMixin(LightningElement) {
    // Current object api name
    @api objectApiName;
    // Current record's id
    @api recordId;
    // Current record
    @track record;
    
    //Wizard status
    @track activeWizard = false;

    // Event data
    @track showLoadingSpinner = false;
    @track error;

    // Variables
    @track pieceInputEntityId;
    @track pieceInputEntityName;
    @track piecePaymentMethodId;
    @track piecePaymentMethodName;
    @track pieceRefundReasonId;
    @track pieceRefundReasonName;
    pieceDate;
    creditMemoDate;
    creditMemoAmountMin;
    
    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        // Init body
        this.showLoadingSpinner = true;
        this.activeWizard = false;
        this.pieceDate = this.todaysDate;
    }

    connectedCallback(){
        this.fieldArray = CREDITMEMO_FIELDS;
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
        if(error) {
            this.processErrorMessage(error);
        } else if (data) {
            // Set the record
            this.record = data;
            // Input Entity
            if(this.record.fields.customerOrder__c.value) {
                this.pieceInputEntityId = this.record.fields.customerOrder__r.value.fields.serviceEntity__c.value;
                this.pieceInputEntityName = this.record.fields.customerOrder__r.value.fields.serviceEntity__r.value.fields.Name.value;
            }
            // Refund Reason
            this.pieceRefundReasonId = this.record.fields.refundReason__c.value;
            if(this.pieceRefundReasonId) {
                this.pieceRefundReasonName = this.record.fields.refundReason__r.value.fields.Name.value;
            }
            // Other datas
            this.creditMemoDate = this.record.fields.creditMemoDate__c.value;
            this.pieceAmount = -1*this.record.fields.amount__c.value;
            this.creditMemoAmountMin = this.pieceAmount;
            this.getDefaultPaymentMethod();
        }
    }

    /* ========== JS METHODS ========== */

    /**
     * Function to call "createRefundRequestPiece" APEX method.
     */
    createRefundRequestPiece(){
        try{
            if(this.checkForErrors()) {
                this.showLoadingSpinner = true;
                createRefundRequestPiece({creditMemoId: this.recordId, inputEntityId: this.pieceInputEntityId, 
                                            refundReasonId: this.pieceRefundReasonId, paymentMethodId: this.piecePaymentMethodId,
                                            pieceDate: this.pieceDate, pieceAmount: this.pieceAmount}).
                then(result => {
                    if (result) {
                        this.showNotification('Demande de remboursement', "La demande de remboursement a bien été créé.", 'success');
                        // Open PDF Preview
                        this.viewPdf(result);
                        // Close the quick action
                        this.closeQuickAction();
                    }
                    else{
                        this.showNotification('Erreur', "Echec lors de la création de la pièce comptable.", 'error');
                    }
                    this.showLoadingSpinner = false;
                })
                .catch(error => {
                    this.processErrorMessage(error);
                });
            }
        }
        catch(error) {
            this.processErrorMessage(error.message);
        }
    }
    
    /**
     * Function to call "getDefaultPaymentMethod" APEX method.
     */
    getDefaultPaymentMethod() {
        try {
            this.showLoadingSpinner = true;
            // Call APEX method to get the default value of the payment method
            getDefaultPaymentMethod()
            .then(result => {
                if (result) {
                    this.piecePaymentMethodId = result.Id;   
                    this.piecePaymentMethodName = result.Name;    
                    this.error = undefined;
                }
                this.showLoadingSpinner = false;
                this.activeWizard = true;
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        } catch(error) {
            this.processErrorMessage(error.message);
            this.piecePaymentMethodId = undefined;
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
        else if(this.pieceAmount >= 0) {
            this.processErrorMessage("Le montant doit être compris entre "+this.creditMemoAmountMin+" et 0 (exclus) !", false);
            result = false;
        }
        else if(this.isNullOrWhitespace(this.piecePaymentMethodId)) {
            this.processErrorMessage('L\'information "Mode de règlement" est obligatoire !', false);
            result = false;
        }
        else if(this.isNullOrWhitespace(this.pieceInputEntityId)) {
            this.processErrorMessage('L\'information "Entité de saisie" est obligatoire !', false);
            result = false;
        } 
        else if(this.isNullOrWhitespace(this.pieceRefundReasonId)) {
            this.processErrorMessage('L\'information "Motif de remboursement" est obligatoire !', false);
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
     * Create the accounting piece when the users click on "Valider"
     */
    handleCreateRefundRequestPiece(){
        this.resetErrorMessage();
        // Check errors, continue if no errors
        if(this.checkForErrors()) {
            this.createRefundRequestPiece();
        }
    }

    /**
     * Handle a change on the "Date de demande" field 
     * @param {object} event - Object of the Event.
     */	
     handlePieceDateChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.pieceDate = event.target.value;     
    }

    /**
     * Handle a change on the "Entité de saisie" field 
     * @param {object} event - Object of the Event.
     */
    handleInputEntityLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.pieceInputEntityId = selection[0].id;
            this.pieceInputEntityName = selection[0].title;
        } else {
            this.pieceInputEntityId = "";
            this.pieceInputEntityName = "";
        }
    }

    /**
     * Handle a change on the "Montant à rembourser" field 
     * @param {object} event - Object of the Event.
     */	
    handlePieceAmountChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.pieceAmount = event.target.value; 
        this.pieceAmount=parseFloat(this.pieceAmount);
    }

    /**
     * Handle a change on the "Motif de remboursement" field 
     * @param {object} event - Object of the Event.
     */
    handleRefundReasonLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.pieceRefundReasonId = selection[0].id;
            this.pieceRefundReasonName = selection[0].title;
        } else {
            this.pieceRefundReasonId = "";
            this.pieceRefundReasonName = "";
        }
    }

    /**
     * Handle a change on the "Mode de règlement" field 
     * @param {object} event - Object of the Event.
     */
    handlePaymentMethodLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.piecePaymentMethodId = selection[0].id;
            this.piecePaymentMethodName = selection[0].title;
        } else {
            this.piecePaymentMethodId = "";
            this.piecePaymentMethodName = "";
        }
    }

    /* ========== GETTER METHODS ========== */

    get todaysDate() {
        return new Date().toISOString().slice(0, 10);
    }
}