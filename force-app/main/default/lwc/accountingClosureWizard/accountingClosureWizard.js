/* eslint-disable no-console */
import { LightningElement, api, track, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Apex class methods
import getDepotsAccounts from '@salesforce/apex/LWC_AccountingClosureWizard.getDepotsAccounts';
import closeRecords from '@salesforce/apex/LWC_AccountingClosureWizard.closeRecords';
import retrieveRecordsToClose from '@salesforce/apex/LWC_AccountingClosureWizard.retrieveRecordsToClose';
import getPreviousBusinessDayDate from '@salesforce/apex/LWC_AccountingClosureWizard.getPreviousBusinessDayDate';

import getProviderAccounts from '@salesforce/apex/LWC_AccountingClosureWizard.getProviderAccounts';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

// Constants (Path, Fields displayed for each action/step)
const PATH_STEPS = [
    { label: 'Sélection de la date et des dépôts à clôturer', value: 'step-1', display: true },
    { label: 'Récapitulatif et confirmation', value: 'step-2', display: true },
    { label: 'Résultat des clôtures', value: 'step-3', display: true }
];
const ACCOUNTS_COLUMNS = [
    { label: "Nom", fieldName: 'Name' },
    { label: "Etape", fieldName: 'stageName__c' },
    { label: "Date de fin de validité", fieldName: 'endDate__c', type: 'date-local' }
];

const ERROR_COLUMNS = [
    { label: 'Type', fieldName: 'recordType' },
    { label: 'Nom', fieldName: 'recordName'},
    { label: 'Message d\'erreur', fieldName: 'errorMessage'}
];

export default class AccountingClosureWizard extends NavigationMixin(LightningElement) {

    // Setupped collections
    @track accountColumns = ACCOUNTS_COLUMNS;
    @track errorColumns = ERROR_COLUMNS;

    // Data collections
    @track accountData = [];

    @track accountProviderData = [];

    // Wizard Status
    @track currentStep = "step-1";
    @track steps = PATH_STEPS;
    @track showStep1Form = false;
    @track showStep2Form = false;
    @track showNextButton = true;
    @track showPreviousButton = false;
    @track showSubmitButton = true;
    @track numberOfInvoices = 0;
    @track totalHTInvoice = 0;
    @track numberOfCreditMemos = 0;
    @track totalHTCreditMemo = 0;
    @track numberOfAccountingPieces = 0;
    @track totalTTCAccountingPiece = 0;
    @track numberOfAccountingEntries = 0;
    @track totalTTCAccountingEntry = 0;
    @track numberOfOrderItems = 0;
    @track totalHTOrderItem = 0;
    @track numberOfAssignedResources = 0;
    @track totalHTAssignedResource = 0;
    @track numberOfClosedInvoices = 0;
    @track numberOfClosedCreditMemos = 0;
    @track numberOfClosedAccountingPieces = 0;
    @track numberOfClosedAccountingEntries = 0;
    @track numberOfClosedAssignedResources = 0;
    @track numberOfClosedOrderItems = 0;
    @track numberOfFailedInvoices = 0;
    @track numberOfFailedCreditMemos = 0;
    @track numberOfFailedAccountingPieces = 0;
    @track numberOfFailedAccountingEntries = 0;
    @track numberOfFailedAssignedResources = 0;
    @track numberOfFailedOrderItems = 0;
    @track selectedAccNameList = "";
    @track invoiceIdList = [];
    @track creditMemoIdList = [];
    @track accPieceIdList = [];
    @track accEntryIdList = [];
    @track orderItemIdList = [];
    @track assignedResourceIdList = [];

    @track showSpecificRecordTypeOptions = false;
    @track showInvoiceRecap = false;
    @track showCreditMemoRecap = false;
    @track showAccEntryRecap = false;
    @track showAccPieceRecap = false;
    @track showAssignedResourceRecap = false;
    @track showOrderItemRecap = false;
    @track errorList = [];
    @track errorListInvoice = [];
    @track errorListCreditMemo = [];
    @track errorListAccEntry = [];
    @track errorListAccPiece = [];
    @track errorListAssignedResource = [];
    @track errorListOrderItem = [];
    @track recordNameByIdMap = [];
    @track showErrorList = false;
    @track selectedErrorTypeToShow = "all";
    @track showErrorAll = true;
    @track showErrorInvoice = false;
    @track showErrorCreditMemo = false;
    @track showErrorAccEntry = false;
    @track showErrorAccPiece = false;
    @track showErrorAssignedResource = false;
    @track showErrorOrderItem = false;
    @track errorTypesToShow = [];
    @track showAccountsProvider = true;
    @track selectedAccProviderNameList = "";
    @track showAccountsProviderTable = false;

    // Event data
    @track showLoadingSpinner = false;
    @track error;

    // Non reactive variables
    selectedRecords = [];
    accountSelected = "";
    closingDate;
    recordTypesToCloseSelected = "all";
    specificRecordTypesSelected = [];
    specifyAccountProviderOptionsSelected = "all";

    accountsProviderSelected = []; 
     
    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        // Init body
        this.updateWizardBody();
        this.showLoadingSpinner = true;
    }

    /* ========== WIRED METHODS ========== */

    /**
     * Retrieving valid depots
     */
    @wire(getDepotsAccounts, {})
    accounts(accountList) {
        if (accountList.data) {
            this.accountData = accountList.data;
        } else if (accountList.error) {
            this.processErrorMessage(result.error);
            this.accountData = undefined;
        }
        this.showLoadingSpinner = false;
    }

    /**
     * Retrieving valid providers
     */
    @wire(getProviderAccounts, {})
    accountsProvider(accountProviderList) {
        if (accountProviderList.data) {
            this.accountProviderData = accountProviderList.data;
        } else if (accountProviderList.error) {
            this.processErrorMessage(result.error);
            this.accountProviderData = undefined;
        }
        this.showLoadingSpinner = false;
    }

    /**
     * Retrieving previous business Day date
     */
    @wire(getPreviousBusinessDayDate, {})
    date(dateValue) {
        if (dateValue.data) {
            this.closingDate = dateValue.data;
        } else if (dateValue.error) {
            this.processErrorMessage(result.error);
            this.closingDate = undefined;
        }
        this.showLoadingSpinner = false;
    }

    /* ========== EVENT METHODS ========== */

    /**
     * Handle a change on the "Depot" table
     * @param {object} event - Object of the Event.
     */
    handleSelectedAccountChange(event) {
        this.resetErrorMessage();
        // Get row selected
        const selectedRows = event.detail.selectedRows;
        // Init the array of accounts
        this.selectedAccNameList = "";
        this.selectedRecords = [];
        for(let row of selectedRows){  
            // Add depot selected in the array      
            this.selectedRecords.push(row.Id);
            if(this.selectedAccNameList == ""){
                this.selectedAccNameList+=row.Name;
            } else {
                this.selectedAccNameList+=', '+row.Name;
            }
        }
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
                let currIndex = this.steps.findIndex(x => x.value === currentStage); // Get the index in the array of the step
                // If the step is display, display it else jump in the next step
                if(this.steps[currIndex+1].display === true) {
                    currentStage = this.steps[currIndex+1].value;
                } else {
                    currentStage = this.steps[currIndex+2].value;
                }
                this.currentStep = currentStage;
            }
            //reset recap visibility
            this.showInvoiceRecap = false;
            this.showCreditMemoRecap = false;
            this.showAccEntryRecap = false;
            this.showAccPieceRecap = false;
            this.showAssignedResourceRecap = false;
            this.showOrderItemRecap = false;

            //Handle recap visibility if specific type selected
            if(this.recordTypesToCloseSelected == 'all' || this.specificRecordTypesSelected.includes('Invoice')){
                this.showInvoiceRecap = true;
            }
            if(this.recordTypesToCloseSelected == 'all' || this.specificRecordTypesSelected.includes('CreditMemo')){
                this.showCreditMemoRecap = true;
            }
            if(this.recordTypesToCloseSelected == 'all' || this.specificRecordTypesSelected.includes('AccountingEntry')){
                this.showAccEntryRecap = true;
            }
            if(this.recordTypesToCloseSelected == 'all' || this.specificRecordTypesSelected.includes('AccountingPiece')){
                this.showAccPieceRecap = true;
            }
            if(this.recordTypesToCloseSelected == 'all' || this.specificRecordTypesSelected.includes('AssignedResource')){
                this.showAssignedResourceRecap = true;
            }
            if(this.recordTypesToCloseSelected == 'all' || this.specificRecordTypesSelected.includes('OrderItem')){
                this.showOrderItemRecap = true;
            }
            // Get all infos of the associated records
            this.retrieveRecordsToClose();
            // Update the form to show the next step
            this.updateWizardBody();  
        }
    }

    /**
     * Display the previous step of the wizard.
     * Executed when the user clicks on the "Précédent" button of the wizard.
     */
    handlePrevious() {
        this.resetErrorMessage();

        // Get the previous step in the array
        let currentStage = this.currentStep;
        // If is not the first step
        if(currentStage === 'step-3') {
            this.currentStep = 'step-1';
        } else if(currentStage !== this.steps[0].value) {
            let currIndex = this.steps.findIndex(x => x.value === currentStage); // Get the index in the array of the step
            // If the step is display, display it else jump in the previous step
            if(this.steps[currIndex-1].display === true) {
                currentStage = this.steps[currIndex-1].value;
            } else {
                currentStage = this.steps[currIndex-2].value;
            }
            this.currentStep = currentStage;
        } 
        // Update the form to show the previous step
        this.updateWizardBody();
    }   

    /**
     * Handle a change on the "Date de clôture" field
     * @param {object} event - Object of the Event.
     */	
    handleClosingDateChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.closingDate = event.target.value;     
    }

    /**
     * Handle a change on the "Éléments à clôturer" field
     * @param {object} event - Object of the Event.
     */	
    handleSpecificRecordTypesChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.specificRecordTypesSelected = event.target.value;
        if(this.specificRecordTypesSelected.indexOf("OrderItem") > -1){
            this.showAccountsProvider = true;
        }
        else{
            this.showAccountsProvider = false;
            this.accountsProviderSelected = [];
            this.specifyAccountProviderOptionsSelected = 'all';
            this.showAccountsProviderTable = false;
        }             
    }

    /**
     * Handle a change on the "Éléments à clôturer" field
     * @param {object} event - Object of the Event.
     */	
    handleRecordTypeToCloseChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.recordTypesToCloseSelected = event.target.value;
        if(this.recordTypesToCloseSelected != 'all'){
            this.showSpecificRecordTypeOptions = true;
            this.showAccountsProvider = false;
        }
        else {
            this.showSpecificRecordTypeOptions = false;
            this.specificRecordTypesSelected = [];
            this.showAccountsProvider = true;
            this.specifyAccountProviderOptionsSelected = 'all';
            this.showAccountsProviderTable = false;
            this.accountsProviderSelected = [];
        }
    }

    handleErrorTypesToShowChange(event){
        //reset Error visibility
        this.showErrorAll = false;
        this.showErrorInvoice = false;
        this.showErrorCreditMemo = false;
        this.showErrorAccEntry = false;
        this.showErrorAccPiece = false;
        this.showErrorAssignedResource = false;
        this.showErrorOrderItem = false;

        //Change Error List visibility according to errorTypeToShow selected
        this.selectedErrorTypeToShow = event.target.value;
        switch (this.selectedErrorTypeToShow){
            case 'all' : 
                this.showErrorAll = true;
                break;
            case 'Invoice' :
                this.showErrorInvoice = true;
                break;
            case 'CreditMemo' :
                this.showErrorCreditMemo = true;
                break;
            case 'AccEntry' :
                this.showErrorAccEntry = true;
                break;
            case 'AccPiece' :
                this.showErrorAccPiece = true;
                break;
            case 'AssignedResource' :
                this.showErrorAssignedResource = true;
                break;
            case 'OrderItem' :
                this.showErrorOrderItem = true;
                break;
        }
    }

    /**
     * Handle a change on the "Comptes fournisseurs" table
     * @param {object} event - Object of the Event.
     */
    handleSelectedAccountProviderChange(event) {
        this.resetErrorMessage();
        // Get row selected
        const selectedRows = event.detail.selectedRows;
        // Init the array of accounts
        this.selectedAccProviderNameList = "";
        this.accountsProviderSelected = [];
        for(let row of selectedRows){  
            // Add depot selected in the array      
            this.accountsProviderSelected.push(row.Id);
            if(this.selectedAccProviderNameList == ""){
                this.selectedAccProviderNameList+=row.Name;
            } else {
                this.selectedAccProviderNameList+=', '+row.Name;
            }
        }
    }

    /**
     * Handle a change on the specifyAccountProvider table
     * @param {object} event - Object of the Event.
     */
    handleSpecifyAccountProviderChange(event) {
        this.resetErrorMessage();
        // Define fields
        this.specifyAccountProviderOptionsSelected = event.target.value;
        // Define fields
        if(this.specifyAccountProviderOptionsSelected != 'all'){
            this.showAccountsProviderTable = true;
        }
        else {
            this.showAccountsProviderTable = false;
            this.accountsProviderSelected = [];
        }
    }

    /* ========== JS METHODS ========== */
    
    /**
     * Function executed when the user click on the Previous/Next button to update the form.
     */
    updateWizardBody(){
        this.showStep1Form = false;
        this.showStep2Form = false;
        this.showStep3Form = false;
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
                this.showNextButton = false;
                this.showSubmitButton = true;
                break;
            case 'step-3':
                this.showStep3Form = true;
                this.showNextButton = false;
                this.showSubmitButton = false;
                break;
        }
    }

    /**
     * Function to get the number and amount for the records that will be closed
     */
    retrieveRecordsToClose(){
        this.showLoadingSpinner = true;
        this.resetErrorMessage(); 

        retrieveRecordsToClose({accountId: this.selectedRecords[0], closingDate: this.closingDate, specificRecordTypes : this.specificRecordTypesSelected, accountsProviderId : this.accountsProviderSelected})
        .then(result => {
            this.closingDate = this.closingDate;
            this.numberOfInvoices = result.numberOfInvoices;
            this.totalHTInvoice = result.totalHTInvoice;
            this.numberOfCreditMemos = result.numberOfCreditMemos;
            this.totalHTCreditMemo = result.totalHTCreditMemo;
            this.numberOfAccountingPieces = result.numberOfAccountingPieces;
            this.totalTTCAccountingPiece = result.totalTTCAccountingPiece;
            this.numberOfAccountingEntries = result.numberOfAccountingEntries;
            this.totalTTCAccountingEntry = result.totalTTCAccountingEntry;
            this.numberOfOrderItems = result.numberOfOrderItems;
            this.totalHTOrderItem = result.totalHTOrderItem;
            this.numberOfAssignedResources = result.numberOfAssignedResources;
            this.totalHTAssignedResource = result.totalHTAssignedResource;
            this.invoiceIdList = result.invoiceIdList;
            this.creditMemoIdList = result.creditMemoIdList;
            this.accPieceIdList = result.accPieceIdList;
            this.accEntryIdList = result.accEntryIdList;
            this.orderItemIdList = result.orderItemIdList;
            this.assignedResourceIdList = result.assignedResourceIdList;
            this.showLoadingSpinner = false;
            this.recordNameByIdMap = result.recordNameByIdMap;
            console.log('this.assignedResourceIdList : '+this.assignedResourceIdList);
            console.log('this.recordNameByIdMap : '+this.recordNameByIdMap);
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
    }

    /**
     * Function to close all the retrieved records
     */
    closeRecords(){
        this.showLoadingSpinner = true;
        this.resetErrorMessage(); 

        closeRecords({closingDate: this.closingDate, invoiceIdList: this.invoiceIdList, creditMemoIdList: this.creditMemoIdList,
            accPieceIdList: this.accPieceIdList, accEntryIdList: this.accEntryIdList, orderItemIdList: this.orderItemIdList, assignedResourceIdList: this.assignedResourceIdList, recordNameByIdMap : this.recordNameByIdMap})
        .then(result => {
            this.numberOfClosedInvoices = result.numberOfClosedInvoices;
            this.numberOfClosedCreditMemos = result.numberOfClosedCreditMemos;
            this.numberOfClosedAccountingPieces = result.numberOfClosedAccountingPieces;
            this.numberOfClosedAccountingEntries = result.numberOfClosedAccountingEntries;
            this.numberOfClosedAssignedResources = result.numberOfClosedAssignedResources;
            this.numberOfClosedOrderItems = result.numberOfClosedOrderItems;
            this.numberOfFailedInvoices = result.numberOfFailedInvoices;
            this.numberOfFailedCreditMemos = result.numberOfFailedCreditMemos;
            this.numberOfFailedAccountingPieces = result.numberOfFailedAccountingPieces;
            this.numberOfFailedAccountingEntries = result.numberOfFailedAccountingEntries;
            this.numberOfFailedAssignedResources = result.numberOfFailedAssignedResources;
            this.numberOfFailedOrderItems = result.numberOfFailedOrderItems;

            this.errorList = result.errorList;
            console.log('this.errorList : '+this.errorList);

            if(this.errorList.length > 0){
                //Reset ErrorList visbility
                this.showErrorList = true;
                this.errorTypesToShow = [{ label: 'Tous les types', value: 'all' }];
                this.selectedErrorTypeToShow = "all";
                this.showErrorAll = true;
                this.showErrorInvoice = false;
                this.showErrorCreditMemo = false;
                this.showErrorAccEntry = false;
                this.showErrorAccPiece = false;
                this.showErrorAssignedResource = false;
                this.showErrorOrderItem = false;
                this.errorListInvoice = [];
                this.errorListCreditMemo = [];
                this.errorListAccEntry = [];
                this.errorListAccPiece = [];
                this.errorListAssignedResource = [];
                this.errorListOrderItem = [];

                if(result.numberOfFailedInvoices > 0){
                    this.errorListInvoice = this.errorList.filter(r => r.recordType === "Facture");
                    this.errorTypesToShow.push({ label: 'Factures', value: 'Invoice' });
                }
                if(result.numberOfFailedCreditMemos > 0){
                    this.errorListCreditMemo = this.errorList.filter(r => r.recordType === "Avoir");
                    this.errorTypesToShow.push({ label: 'Avoirs', value: 'CreditMemo' });
                }
                if(result.numberOfFailedAccountingEntries > 0){
                    this.errorListAccEntry = this.errorList.filter(r => r.recordType === "Ecriture Comptable");
                    this.errorTypesToShow.push({ label: 'Ecriture Comptable', value: 'AccEntry' });
                }
                if(result.numberOfFailedAccountingPieces > 0){
                    this.errorListAccPiece = this.errorList.filter(r => r.recordType === "Pièce Comptable");
                    this.errorTypesToShow.push({ label: 'Pièce Comptable', value: 'AccPiece' });
                }
                if(result.numberOfFailedAssignedResources > 0){
                    this.errorListAssignedResource = this.errorList.filter(r => r.recordType === "Facture de service");
                    this.errorTypesToShow.push({ label: 'Facture de service', value: 'AssignedResource' });
                }
                if(result.numberOfFailedOrderItems > 0){
                    this.errorListOrderItem = this.errorList.filter(r => r.recordType === "Commande fournisseur");
                    this.errorTypesToShow.push({ label: 'Commande fournisseur', value: 'OrderItem' });
                }
            }
            else{
                this.showErrorList = false;
            }
            this.showLoadingSpinner = false;
            this.currentStep = 'step-3';
            this.updateWizardBody();
            // Show success messsage
            this.showNotification('Clôture terminée', "Les objets de comptabilité ont été clôturés avec succès", 'success');
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
    }

    /* ========== UTILITY METHODS ========== */  

    hasAccountsData() {
        return this.accountData.length > 0;
    }

    hasAccountsProviderData() {
        return this.accountProviderData.length > 0;
    }

    /**
     * Function to check all errors before changing step.
     */
    checkForErrors() {
        let result = true;
        // check if on step 1 there is a depot and closing date selected
        if(this.currentStep === 'step-1') {
            if (this.selectedRecords.length === 0) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner un dépôt.", false);
            } 
            if (this.closingDate == undefined) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner une date de clôture.", false);
            } 
            if (this.closingDate > this.todaysDate) {
                result = false;
                this.processErrorMessage("Vous ne pouvez pas sélectionner une date de clôture supérieure à la date du jour.", false);
            }
            if (this.showSpecificRecordTypeOptions && this.specificRecordTypesSelected.length === 0) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner un type d'élement à clôturer.", false);
            }
            if (this.showAccountsProviderTable && this.accountsProviderSelected.length === 0) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner un compte fournisseur.", false);
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

    get todaysDate() {
        return new Date().toISOString().slice(0, 10);
    }

    get recordTypesToCloseOptions() {
        return [
            { label : 'Tous les élements', value : 'all'},
            { label : 'Seulement les élements spécifiés', value : 'specificType'}
        ]
    }

    get specificRecordTypesOptions() {
        return [
            { label: 'Factures', value: 'Invoice' },
            { label: 'Avoirs', value: 'CreditMemo' },
            { label: 'Écritures comptables', value: 'AccountingEntry' },
            { label: 'Pièces comptables', value: 'AccountingPiece' },
            { label: 'Factures de service', value: 'AssignedResource' },
            { label: 'Commandes fournisseurs', value: 'OrderItem' }
        ];
    }

    get specifyAccountProviderOptions() {
        return [
            { label : 'Tous les comptes fournisseurs', value : 'all'},
            { label : 'Seulement les comptes spécifiés', value : 'specificAccount'}
        ]
    }

    /*get errorTypesToShow(){
        return [
            { label: 'Tous les types', value: 'all' },
            { label: 'Facture', value: 'Invoice' },
            { label: 'Avoir', value: 'CreditMemo' }
        ];
    }*/
}