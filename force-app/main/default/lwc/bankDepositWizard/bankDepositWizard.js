import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

// Apex class methods
import getAccountingPieces from '@salesforce/apex/LWC_BankDepositWizard.getAccountingPieces';
import updateAccountingPieces from '@salesforce/apex/LWC_BankDepositWizard.updateAccountingPieces';
import getBankAccount from '@salesforce/apex/LWC_BankDepositWizard.getBankAccount';
import getBankAccountName from '@salesforce/apex/LWC_BankDepositWizard.getBankAccountName';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

// Permission
import hasPermission from '@salesforce/customPermission/KPK_Comptabilite_Remise_en_banque';

//Record fields
const ACCOUNT_FIELDS = ['Account.Id','Account.Name','Account.KparKReference__c'];
const REF_FIELDS = ['Referencial__c.Id','Referencial__c.Name'];

// Objects colums for datatables
const PIECE_COLUMNS = [
    { label: "N° de la pièce", fieldName: 'Name', sortable: true},
    { label: "Montant", fieldName: 'amount__c', type: 'currency'},
    { label: "Mode de règlement", fieldName: 'PaymentMethodName'}, /* Utilisation de champ inutile pour stocker provisoirement le nom du mode de reglement */
    { label: "Date de la pièce", fieldName: 'pieceDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" } },
    { label: "N° remise en banque", fieldName: 'bankRemittanceNumber__c'},
    { label: "Date d'échéance", fieldName: 'dueDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" } },
    { label: "Banque externe", fieldName: 'externalBank__c'},
    { label: "Référence externe", fieldName: 'externalReference__c'},
    { label: "Nom du compte client", fieldName: 'AccountName'} /* Utilisation de champ inutile pour stocker provisoirement le nom du client */
];

const PATH_STEPS = [
    { label: 'Banque', value: 'step-1', display: true },
    { label: 'Encaissement', value: 'step-2', display: true },
    { label: 'Validation', value: 'step-3', display: true }
];

export default class BankDepositWizard extends NavigationMixin(LightningElement) {
    // Current object api name
    @api objectApiName;
    // Current record's id
    @api recordId;
    // Current record
    @track record;
    
    //Wizard status
    @track activeWizard = false;
    @track showPreviousButton = false;
    @track showNextButton = true;
    @track currentStep = "step-1";
    @track steps = PATH_STEPS;  

    @track showStep1Form = true;
    @track showStep2Form = false;
    @track showStep3Form = false;
    @track showSubmitButton = false;
    @track isPreviousState = false;
    @track nbPieces = 0;
    @track totalAmountPieces = 0;
    @track applyEntityFilter = true;
    @track applyDueDateFilter = true;

    //Datatable
    @track accountingPiecesData = [];

    // Event data
    @track showLoadingSpinner = false;
    @track error;

    // non-reactive variables
    pieceInputEntityId;
    pieceInputEntityName;
    pieceBankAccountId;
    pieceBankAccountName;
    pieceAccountingDate;
    bankRemittanceNumber;
    bankAccountError;
    selectedPieceRecords = [];
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedByPiece = 'Name';

    //Other
    @track pieceColumns = PIECE_COLUMNS;

    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        // Init body
        //this.showLoadingSpinner = true;
        this.activeWizard = false;
        this.updateWizardBody();
        this.accountingPiecesData = [];
        this.selectedPieceRecords = [];
        this.applyEntityFilter = true;
        this.applyDueDateFilter = true;
        this.pieceAccountingDate = this.todaysDate;
    }

    connectedCallback(){
        if(this.objectApiName === "Account") {
            this.fieldArray = ACCOUNT_FIELDS;
        } else if(this.objectApiName === "Referencial__c") {
            this.fieldArray = REF_FIELDS;
        } else {
            this.showLoadingSpinner = false;
            this.activeWizard = this.hasAccessToWizard;
        }
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
            // Check if Entity or BankAccount
            if(this.objectApiName === "Account" && this.record.fields.KparKReference__c.value) {
                this.pieceInputEntityId = this.recordId;
                this.pieceInputEntityName = this.record.fields.Name.value;
                this.getBankAccount();
            } else 
            if(this.objectApiName === "Referencial__c") {
                this.pieceBankAccountId = this.recordId;
                this.pieceBankAccountName = this.record.fields.Name.value;
                this.bankAccountError = 'OK';
                this.showLoadingSpinner = false;
                this.activeWizard = true;
            } else {
                this.showLoadingSpinner = false;
                this.activeWizard = true;
            }
        }
    }

    /* ========== JS METHODS ========== */

    /**
     * Function executed when the user click on the Previous/Next button to update the form.
     */
    updateWizardBody() {
        this.showStep1Form = false;
        this.showStep2Form = false;
        this.showStep2aForm = false;
        this.showStep3Form = false;
        this.showStep4Form = false;
        this.showPreviousButton = true;
        this.showNextButton = true;
        this.showSubmitButton = false;
        switch (this.currentStep) {
            case 'step-1':
                this.showStep1Form = true;
                this.showPreviousButton = false;
                break;
            case 'step-2':
                if(!this.isPreviousState) {
                    this.getAccountingPieces();
                }
                this.showStep2Form = true;
                break;
            case 'step-3':
                this.showStep4Form = true;
                this.showSubmitButton = true;
                this.showNextButton = false;
                if(this.isNullOrWhitespace(this.pieceBankAccountName)) {
                    this.getBankAccountName();
                }
                break;
        }
    }

    /**
     * Function to call "getAccountingPieces" APEX method.
     */
    getAccountingPieces(){
        console.log("getAccountingPieces ");
        try {
            this.showLoadingSpinner = true;
            this.accountingPiecesData = [];
            // Call APEX method to get pieces
            getAccountingPieces({ inputEntityId: this.pieceInputEntityId, bankAccountId: this.pieceBankAccountId, 
                                    accountingDate: this.pieceAccountingDate, applyDueDateFilter: this.applyDueDateFilter, applyEntityFilter: this.applyEntityFilter })
            .then(result => {
                // If pieces, we set the table
                console.log("result "+JSON.stringify(result));
                console.log("result.length "+result.length);
                if (result.length !== 0) {
                    this.accountingPiecesData = result;  
                    // Define temp columns with real values
                    this.accountingPiecesData = this.accountingPiecesData.map(row=>{
                        let accName="";
                        let paymentMethName="";
                        if(row.account__c) {
                            accName=row.account__r.Name;
                        }
                        if(row.paymentMethod__c) {
                            paymentMethName=row.paymentMethod__r.Name;
                        }
                        return{...row, AccountName: accName, PaymentMethodName: paymentMethName}
                    })
                    this.error = undefined;
                    this.showStep3Form = true; // Display STEP 3 if pieces exist
                } else {                    
                    this.showStep3Form = false; // Hide STEP 3 if no pieces
                }
                this.showLoadingSpinner = false;               
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        } catch(error) {
            this.processErrorMessage(error.message);
        }
    }

    /**
     * Function to call "updateAccountingPieces" APEX method.
     */
    updateAccountingPieces(){
        this.checkForErrors();
        try{
            updateAccountingPieces({selectedPieceRecordsId: this.selectedPieceRecords, inputEntityId: this.pieceInputEntityId, 
                                    bankAccountId: this.pieceBankAccountId, accountingDate: this.pieceAccountingDate, bankRemittanceNumber: this.bankRemittanceNumber}).
            then(result => {
                if (result) {
                    this.showNotification('Remise en banque', "Les pièces comptables ont bien été mises à jour.", 'success');
                    // Open PDF Preview
                    this.viewPdf(result);
                    // Close the quick action
                    this.closeQuickAction();
                    // Go back to step 1
                    this.initRAZ();
                }
                else{
                    this.showNotification('Erreur', "Echec lors de la mise à jour des pièces comptables.", 'error');
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
     * Function to RAZ variables
     */
    initRAZ() {
        this.currentStep = "step-1";
        this.accountingPiecesData = [];
        this.selectedPieceRecords = [];
        this.applyEntityFilter = true;
        this.applyDueDateFilter = true;
        this.getAccountingPieces();
        this.updateWizardBody();
    }

    /**
     * Function to call "getBankAccountName" APEX method.
     */
    getBankAccountName() {
        getBankAccountName({ 
            bankAccountId: this.pieceBankAccountId
        })
        .then(result => {
            this.pieceBankAccountName = result;
            this.activeWizard = true;
            this.showLoadingSpinner = false;
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
    }

    /**
     * Function to call "getBankAccount" APEX method.
     */
     getBankAccount(){
        this.bankAccountError = null;
        getBankAccount({ inputEntityId: this.pieceInputEntityId })
        .then(result => {
            if(result != null && result !== 'MoreThanOne') {
                this.pieceBankAccountId = result;
                this.bankAccountError = 'OK';
                this.getBankAccountName();
            } else if(result === 'MoreThanOne') {
                this.bankAccountError = result;
                this.showLoadingSpinner = false;
                this.activeWizard = true;
            } else {
                this.bankAccountError = null;
                this.showLoadingSpinner = false;
                this.activeWizard = true;
            }
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
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
            // Check special rules
            else if(this.isNullOrWhitespace(this.pieceInputEntityId)) {
                this.processErrorMessage('L\'information "Entité de saisie" est obligatoire !', false);
                result = false;
            } 
            else if(this.bankAccountError === 'MoreThanOne' || this.bankAccountError == null) {
                this.processErrorMessage('L\'information "Compte bancaire" est obligatoire !', false);
                result = false;
            } 
        }

        // check if on step 2 (Encaissement)
        if(this.currentStep === 'step-2') {
            if (this.selectedPieceRecords.length === 0) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner au minimum une pièce comptable.", false);
            } 
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

    /**
     * Function to sort list by a field. Used on datatable
     */
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
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
     * Create the accounting pieces when the users click on "Valider"
     */
    handleUpdateAccountingPieces(){
        this.resetErrorMessage();
        this.showLoadingSpinner = true;
        // Check errors, continue if no errors
        if(this.checkForErrors()) {
            this.updateAccountingPieces();
        }
    }

    /**
     * Get the pieces selected in the datatable
     * @param {object} event - Event object of the "onrowselection" of the datatable.
     */
     handleSelectedPiecesChange(event) {
        this.resetErrorMessage();
        // Get row selected
        const selectedRows = event.detail.selectedRows;
        // Init the array of pieces
        let nbPieces = 0;
        let totalAmountPieces = 0;
        this.selectedPieceRecords = [];        
        // Add pieces selected in the array
        for(const piece of selectedRows){      
            this.selectedPieceRecords.push(piece.Id);
            // Calculate number of pieces and amount
            nbPieces++;
            if(piece.amount__c) {
                totalAmountPieces = totalAmountPieces + piece.amount__c;
            }
        }      
        this.nbPieces = nbPieces;
        this.totalAmountPieces = totalAmountPieces;  
    }

    /**
     * Update the variable to apply or not the due date filter
     * @param {object} event - Event object of the input field.
     */
    handleDueDateFilterChange(event) {
        this.applyDueDateFilter = event.target.checked;
        // Update pieces datatable
        this.getAccountingPieces();
    }

    /**
     * Update the variable to apply or not the entity filter
     * @param {object} event - Event object of the input field.
     */
     handleEntityFilterChange(event) {
        this.applyEntityFilter = event.target.checked;
        // Update pieces datatable
        this.getAccountingPieces();
    }

    /**
     * Handle a change on the "Date comptable" field for the "Encaissement" step
     * @param {object} event - Object of the Event.
     */	
    handlePieceAccountingDateChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.pieceAccountingDate = event.target.value;     
    }

    /**
     * Handle a change on the "Date comptable" field for the "Encaissement" step
     * @param {object} event - Object of the Event.
     */
    handleChangeBankRemittanceNumber(event) {
        this.bankRemittanceNumber = event.detail.value;
    }

    /**
     * Handle a change on the "Entité de saisie" field for the "Encaissement" step
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
        if(this.isNullOrWhitespace(this.pieceBankAccountId)) {
            this.getBankAccount();
        }
    }

    /**
     * Handle a change on the "Compte bancaire" field for the "Encaissement" step
     * @param {object} event - Object of the Event.
     */
    handleBankAccountLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.pieceBankAccountId = selection[0].id;
            this.pieceBankAccountName = selection[0].title;
            this.bankAccountError = 'OK';
        } else {
            this.pieceBankAccountId = "";
            this.pieceBankAccountName = "";
            this.getBankAccount();
        }
    }

    /**
     * Handle the sort action on the pieces's datatable
     * @param {object} event - Object of the Event.
     */
    handleSortPieces(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.accountingPiecesData];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.accountingPiecesData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedByPiece = sortedBy;
    }

    /* ========== GETTER METHODS ========== */

    get hasPieces() {
        let result = true;
        if (Object.keys(this.accountingPiecesData).length === 0 && !this.showLoadingSpinner) {
            result = false;
        } 
        return result;
    }

    get todaysDate() {
        return new Date().toISOString().slice(0, 10);
    }

    get hasAccessToWizard() {
        return hasPermission;
    }
}