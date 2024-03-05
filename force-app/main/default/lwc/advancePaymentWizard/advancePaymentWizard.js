import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

// Apex class methods
import getCustomerOrders from '@salesforce/apex/LWC_AdvancePaymentWizard.getCustomerOrders';
import getInvoices from '@salesforce/apex/LWC_AdvancePaymentWizard.getInvoices';
import getDefaultPaymentMethod from '@salesforce/apex/LWC_AdvancePaymentWizard.getDefaultPaymentMethod';
import getPaymentMethodInfos from '@salesforce/apex/LWC_AdvancePaymentWizard.getPaymentMethodInfos';
import createAccountingPieces from '@salesforce/apex/LWC_AdvancePaymentWizard.createAccountingPieces';
import updateDatatableOrders from '@salesforce/apex/LWC_AdvancePaymentWizard.updateDatatableOrders';
import updateDatatableInvoices from '@salesforce/apex/LWC_AdvancePaymentWizard.updateDatatableInvoices';
import getBankAccount from '@salesforce/apex/LWC_AdvancePaymentWizard.getBankAccount';
import getBankAccountName from '@salesforce/apex/LWC_AdvancePaymentWizard.getBankAccountName';
import getVisibilityVerification from '@salesforce/apex/LWC_AdvancePaymentWizard.getVisibilityVerification'

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

//Record fields
const ACCOUNT_FIELDS = ['Account.Name','Account.KparKReference__c'];

// Objects colums for datatables
const ORDER_COLUMNS = [
    { label: "N° de commande", fieldName: 'OrderNumber', sortable: true},
    { label: "Statut", fieldName: 'Status', cellAttributes: { alignment: 'center' }},
    { label: "Date d'activation", fieldName: 'ActivatedDate', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, cellAttributes: { alignment: 'center' } },
    { label: "Montant TTC", fieldName: 'amount__c', type: 'currency', cellAttributes: { alignment: 'center' }},
    { label: "Acompte à percevoir", fieldName: 'expectedAdvancePaymentAmount__c', type: 'currency', cellAttributes: { alignment: 'center' }}, 
    { label: "Acompte déjà perçu", fieldName: 'receivedAdvancePaymentAmount__c', type: 'currency', cellAttributes: { alignment: 'center' }},
    { label: "Montant à encaisser", fieldName: 'shippingCost__c', type: 'currency', cellAttributes: { alignment: 'center' }, editable: true}/* Utilisation de champ inutile pour stocker provisoirement le montant */
];
const ORDER_ORG_COLUMNS = [
    { label: "Compte", fieldName: 'billingName__c'},
    { label: "N° de commande", fieldName: 'OrderNumber', sortable: true, cellAttributes: { alignment: 'center' }},
    { label: "Statut", fieldName: 'Status', cellAttributes: { alignment: 'center' }, cellAttributes: { alignment: 'center' }},
    { label: "Date d'activation", fieldName: 'ActivatedDate', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, cellAttributes: { alignment: 'center' }, cellAttributes: { alignment: 'center' } },
    { label: "Montant TTC", fieldName: 'amount__c', type: 'currency', cellAttributes: { alignment: 'center' }},
    { label: "Acompte à percevoir", fieldName: 'expectedAdvancePaymentAmount__c', type: 'currency', cellAttributes: { alignment: 'center' }}, 
    { label: "Acompte déjà perçu", fieldName: 'receivedAdvancePaymentAmount__c', type: 'currency', cellAttributes: { alignment: 'center' }},
    { label: "Montant à encaisser", fieldName: 'shippingCost__c', type: 'currency', editable: true, cellAttributes: { alignment: 'center' }} /* Utilisation de champ inutile pour stocker provisoirement le montant */
];
const INVOICE_COLUMNS = [
    { label: "N° de commande", fieldName: 'customerOrderNumber__c'},
    { label: "N° de facture", fieldName: 'Name', sortable: true, cellAttributes: { alignment: 'center' }, cellAttributes: { alignment: 'center' }},
    { label: "Date de la facture", fieldName: 'invoiceDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, cellAttributes: { alignment: 'center' }, cellAttributes: { alignment: 'center' } },
    { label: "Montant TTC", fieldName: 'amount__c', type: 'currency', cellAttributes: { alignment: 'center' }},
    { label: "Montant à percevoir", fieldName: 'toPerceiveAmount__c', type: 'currency', cellAttributes: { alignment: 'center' }},
    { label: "Montant déjà perçu", fieldName: 'perceivedAmount__c', type: 'currency', cellAttributes: { alignment: 'center' }},
    { label: "Montant à encaisser", fieldName: 'priceReduction__c', type: 'currency', editable: true, cellAttributes: { alignment: 'center' }}
];

// Colonnes pour le résumé
const ORDER_COLUMNS_READONLY = [
    { label: "N° de commande", fieldName: 'OrderNumber', cellAttributes: { alignment: 'center' }},
    { label: "Date d'activation", fieldName: 'ActivatedDate', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, cellAttributes: { alignment: 'center' } },
    { label: "Montant TTC", fieldName: 'amount__c', type: 'currency', cellAttributes: { alignment: 'center' }},
    { label: "Acompte à percevoir", fieldName: 'expectedAdvancePaymentAmount__c', type: 'currency', cellAttributes: { alignment: 'center' }}, 
    { label: "Acompte deja perçu", fieldName: 'receivedAdvancePaymentAmount__c', type: 'currency', cellAttributes: { alignment: 'center' }},
    { label: "Montant à encaisser", fieldName: 'shippingCost__c', type: 'currency', cellAttributes: { alignment: 'center' }}  /* Utilisation de champ inutile pour stocker provisoirement le montant */
];
const ORDER_COLUMNS_ORG_READONLY = [
    { label: "Compte", fieldName: 'billingName__c'},
    { label: "N° de commande", fieldName: 'OrderNumber', cellAttributes: { alignment: 'center' }},
    { label: "Date d'activation", fieldName: 'ActivatedDate', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, cellAttributes: { alignment: 'center' } },
    { label: "Montant TTC", fieldName: 'amount__c', type: 'currency', cellAttributes: { alignment: 'center' }},
    { label: "Acompte à percevoir", fieldName: 'expectedAdvancePaymentAmount__c', type: 'currency', cellAttributes: { alignment: 'center' }}, 
    { label: "Acompte deja perçu", fieldName: 'receivedAdvancePaymentAmount__c', type: 'currency', cellAttributes: { alignment: 'center' }},
    { label: "Montant à encaisser", fieldName: 'shippingCost__c', type: 'currency', cellAttributes: { alignment: 'center' }} /* Utilisation de champ inutile pour stocker provisoirement le montant */
];
const INVOICE_COLUMNS_READONLY = [
    { label: "N° de commande", fieldName: 'customerOrderNumber__c'},
    { label: "N° de facture", fieldName: 'Name', cellAttributes: { alignment: 'center' }, cellAttributes: { alignment: 'center' }},
    { label: "Date de la facture", fieldName: 'invoiceDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric", cellAttributes: { alignment: 'center' } }, cellAttributes: { alignment: 'center' } },
    { label: "Montant à percevoir", fieldName: 'toPerceiveAmount__c', type: 'currency', cellAttributes: { alignment: 'center' }},
    { label: "Montant déjà perçu", fieldName: 'perceivedAmount__c', type: 'currency', cellAttributes: { alignment: 'center' }},
    { label: "Montant à encaisser", fieldName: 'priceReduction__c', type: 'currency', cellAttributes: { alignment: 'center' }}
];

const PATH_STEPS = [
    { label: 'Encaissement', value: 'step-1', display: true },
    { label: 'Acomptes', value: 'step-2', display: true },
    { label: 'Factures', value: 'step-3', display: true },
    { label: 'Validation', value: 'step-4', display: true }
];

export default class AdvancePaymentWizard extends LightningElement {
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
    @track isOrgFin = false;
 
    @track showStep1Form = true;
    @track showStep2Form = false;
    @track showStep3Form = false;
    @track showStep4Form = false;
    @track showSubmitButton = false;
    @track isPreviousState = false;
    @track reloadInvoiceItemData = false;
    @track totalAdvPaymentAmountSum = 0;
    @track totalInvoiceAdvPaymentAmountSum = 0;

    //Datatable
    @track invoicesData = [];
    @track customerOrderData = [];
    @track checkCustomerOrderData = [];
    @track draftValues = [];
    @track selectedAssets = [];

    // Event data
    @track showLoadingSpinner = false;
    @track error;

    // non-reactive variables
    pieceInputEntityId;
    pieceInputEntityName;
    pieceBankAccountId;
    pieceBankAccountName;
    pieceDate;
    pieceAccountingDate;
    pieceAmount;
    @track pieceAmountMin;
    @track pieceAmountMax;
    bankAccountError;
    @track piecePaymentMethodId;
    @track piecePaymentMethodName;
    pieceExternalBank;
    pieceExternalReference;
    @track requiredExternalBank;
    @track isRequired = false;
    activeSummarySections = ['pieceSummary'];
    selectedOrderRecords = [];
    selectedInvoiceRecords = [];
    selectedOrders = [];
    selectedInvoices = [];
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedByOrder = 'OrderNumber';
    sortedByInvoice = 'Name';
    showSaveWarning = true;

    //Other
    @track orderColumns = ORDER_COLUMNS;
    @track orderColumnsReadOnly = ORDER_COLUMNS_READONLY;
    @track invoiceColumns = INVOICE_COLUMNS;
    @track invoiceColumnsReadOnly = INVOICE_COLUMNS_READONLY;

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
        this.invoicesData = [];
        this.customerOrderData = [];
        this.selectedOrderRecords = [];
        this.selectedInvoiceRecords = [];   
        this.requiredExternalBank = false;
        this.pieceDate = this.todaysDate;
        this.pieceAmountMin = 0.01;
    }

    connectedCallback(){
        this.fieldArray = ACCOUNT_FIELDS;
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
            // Check if Financing Org
            if(this.record.fields.KparKReference__c.value) {
                this.isOrgFin = true;
                this.orderColumns = ORDER_ORG_COLUMNS;
                this.orderColumnsReadOnly = ORDER_COLUMNS_ORG_READONLY;
            }
            // Get default value for PaymentMethod
            this.getDefaultPaymentMethod();
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
                    this.getCustomerOrders();
                }
                this.showStep2Form = true;
                break;
            case 'step-3':
                if(!this.isPreviousState) {
                    this.getInvoices();
                }
                this.showStep3Form = true;
                break;
            case 'step-4':
                this.showStep4Form = true;
                this.showSubmitButton = true;
                this.showNextButton = false;
                if(this.isNullOrWhitespace(this.pieceBankAccountName)) {
                    this.getBankAccountName();
                }
                this.calculateCosts();
                break;
        }
    }

    /**
     * Function to call "getCustomerOrders" APEX method.
     */
    getCustomerOrders(){
        try {
            // Call only if no orders
            if(this.customerOrderData.length === 0 ) {
                this.showLoadingSpinner = true;
                console.log('ordre 1 :');

                // Call APEX method to get orders
                getCustomerOrders({ recordId: this.recordId, isOrgFin: this.isOrgFin, bankAccountId: this.pieceBankAccountId, pieceDate: this.pieceDate  })
                .then(result => {
                    // Filter the result to include only positive values 
                const filteredResult = result.filter(order => order.shippingCost__c > 0 );
                console.log('pieceAmount 1 :'+this.pieceAmount); 
                    // If orders, we set the table
                    if (result.length !== 0 || result.length === 0 ) {
                        this.customerOrderData = filteredResult;   
                        this.error = undefined;
                        console.log('ordre 2 :');
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
     * Function to calculate order and invoice costs
     */
    calculateCosts(){
        let sumAdvPaymentAmountSum = 0;
        let sumInvoiceAdvPaymentAmountSum = 0;

        this.selectedOrders= [];
        for (const line of this.customerOrderData) {
            if(this.selectedOrderRecords.includes(line.Id)){
                this.selectedOrders.push(line);
            }
        }
        if(this.selectedOrders.length > 0) {
            for(const order of this.selectedOrders) {
                sumAdvPaymentAmountSum += order.shippingCost__c;
            }
        }
        this.selectedInvoices= [];
        for (const line of this.invoicesData) {
            if(this.selectedInvoiceRecords.includes(line.Id)){
                this.selectedInvoices.push(line);
            }
        }        
        if(this.selectedInvoices.length > 0) {
            for(const invoice of this.selectedInvoices) {
            sumInvoiceAdvPaymentAmountSum += invoice.priceReduction__c; // changer avec le mantant à encaisser
            }
        }
        this.totalAdvPaymentAmountSum = sumAdvPaymentAmountSum;
        this.totalInvoiceAdvPaymentAmountSum = sumInvoiceAdvPaymentAmountSum;        
    }

    /**
     * Function to call "getInvoices" APEX method.
     */
    getInvoices() {
        try {
            // Call only if no invoices
            if(this.invoicesData.length === 0 ) {
                this.showLoadingSpinner = true;
                console.log('done 1 :');

                // Call APEX method to get invoices
                getInvoices({ recordId: this.recordId, isOrgFin: this.isOrgFin, bankAccountId: this.pieceBankAccountId, pieceDate: this.pieceDate})
                .then(result => {
                    // Filter the result to include only positive values 
                const filteredResultinvoice = result.filter(invoice => invoice.priceReduction__c > 0 );
                console.log('pieceAmount :'+this.pieceAmount);
                    // If invoices, we set the table
                    if (result.length !== 0 || result.length === 0) {
                        console.log('done 2 :');
                        this.invoicesData = filteredResultinvoice;   
                        this.error = undefined;
                    }
                    this.showLoadingSpinner = false;
                })
                .catch(error => {
                    this.processErrorMessage(error);
                });
            }
        } catch(error) {
            this.processErrorMessage(error.message);
            this.invoicesData = undefined;
        }
    }

    /**
     * Function to call "getDefaultPaymentMethod" APEX method.
     */
     getDefaultPaymentMethod() {
        try {
            this.showLoadingSpinner = true;
            // Call APEX method to get the default value of the payment method
            getDefaultPaymentMethod({ isOrgFin: this.isOrgFin })
            .then(result => {
                if (result.length !== 0) {
                    this.piecePaymentMethodId = result.Id;   
                    this.piecePaymentMethodName = result.Name;   
                    this.requiredExternalBank = result.requiredExternalBankAccount__c;
                    this.pieceAmountMin = result.minPayableAmount__c;   
                    this.pieceAmountMax = result.maxPayableAmount__c;   
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
     * Function to call "getPaymentMethodInfos" APEX method.
     */
     getPaymentMethodInfos() {
        try {
            this.showLoadingSpinner = true;
            // Call APEX method to get the value of the payment method
            getPaymentMethodInfos({ recordId: this.piecePaymentMethodId })
            .then(result => {
                if (result) { 
                    this.requiredExternalBank = result.requiredExternalBankAccount__c; // to define if "Référence externe" and "Banque externe" are required
                    this.pieceAmountMin = result.minPayableAmount__c;   
                    this.pieceAmountMax = result.maxPayableAmount__c;
                    this.error = undefined;
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
     * Function to call "createAccountingPieces" APEX method.
     */
    createAccountingPieces(){
        this.checkForErrors();
        try{
            createAccountingPieces({recordId: this.recordId, inputEntityId: this.pieceInputEntityId, isOrgFin: this.isOrgFin, bankAccountId: this.pieceBankAccountId, 
                                    pieceDate: this.pieceDate, accountingDate: this.pieceAccountingDate, amount: this.pieceAmount,
                                    paymentMethodId: this.piecePaymentMethodId, externalBank: this.pieceExternalBank, externalReference: this.pieceExternalReference,
                                    customerOrdersData: this.selectedOrders, invoicesData: this.selectedInvoices}).
            then(result => {
                if (result) {
                    this.showNotification('Encaissement', "Les pièces comptables ont bien été créées.", 'success');
                    // Close the quick action
                    this.closeQuickAction();
                }
                else{
                    this.showNotification('Erreur', "Echec lors de la création des pièces comptables.", 'error');
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
     * Execute the process to update the Orders on the datatable.
     * @param {object} draftValues - Values defined in the datatable for each orders.
     */
    updateDatatableOrders(draftValues) {
        this.showLoadingSpinner = true;
        this.checkCustomerOrderData = [];
        // Call APEX action to update the Orders List
        updateDatatableOrders({ 
            newValues: draftValues, ordersData : this.customerOrderData
        })
        .then(result => {
            if(result) {
                this.checkCustomerOrderData = result;
                //const isCorrect = this.checkForErrors();
                this.customerOrderData = result;
                this.draftValues = [];                
                this.showNotification('Enregistrement réussi !', '', 'success');
                this.showSaveWarning = false;
            } else {                
                this.showNotification('Erreur', "Les modifications n'ont pas pu être enregistrées.", 'error');
            }
            this.showLoadingSpinner = false;
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
    }

    /**
     * Execute the process to update the Invoices on the datatable.
     * @param {object} draftValues - Values defined in the datatable for each invoices.
     */
    updateDatatableInvoices(draftValues) {
        this.showLoadingSpinner = true;
        // Call APEX action to update the Invoices List
        updateDatatableInvoices({ 
            newValues: draftValues, invoicesData : this.invoicesData
        })
        .then(result => {
            if(result) {
                this.invoicesData = result;
                this.draftValues = [];                
                this.showNotification('Enregistrement réussi !', '', 'success');
                this.showSaveWarning = false;
            } else {                
                this.showNotification('Erreur', "Les modifications n'ont pas pu être enregistrées.", 'error');
            }
            this.showLoadingSpinner = false;
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
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
            console.log('pieceBankAccountName'+this.pieceBankAccountName);
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
        getBankAccount({ 
            inputEntityId: this.pieceInputEntityId, pieceDate : this.pieceDate
        })
        .then(result => {
            if(result != null && result !== 'MoreThanOne') {
                this.pieceBankAccountId = result;
                this.bankAccountError = 'OK';
            } else if(result === 'MoreThanOne') {
                this.bankAccountError = result;
            } else {
                this.bankAccountError = null;
            }
            this.showLoadingSpinner = false;
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
        if(this.currentStep === 'step-2' || this.currentStep === 'step-3') {
            if(this.priceChanged == true) {
                //this.showNotification('Erreur',"Vous n'avez pas enregistré vos modifications !!", 'error');
                this.processErrorMessage("Vous n'avez pas enregistré vos modifications !!", false);
                result = false;
            }
        }
        
        if(this.currentStep === 'step-1') {
            if(this.isNullOrWhitespace(this.pieceBankAccountId)) {
                //this.getBankAccount();
            }            
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
            else if(this.pieceAmount <= 0) {
                this.processErrorMessage("Le montant doit être supérieur à 0 !", false);
                result = false;
            }
            else if(this.requiredExternalBank && (this.isNullOrWhitespace(this.pieceExternalBank) || this.isNullOrWhitespace(this.pieceExternalReference))) {
                this.processErrorMessage('Les informations "Banque externe" et "Référence externe" sont obligatoires !', false);
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
            else if((this.bankAccountError == "MoreThanOne" || this.bankAccountError == null)  || (this.pieceAccountingDate != null && (this.pieceBankAccountId == null || this.pieceBankAccountId == ""))) {
                console.log('bankAccountError : '+this.bankAccountError);
                this.processErrorMessage('L\'information "Compte bancaire" est obligatoire !', false);
                result = false; 
            }
            else if (this.pieceBankAccountId != null && this.banckVisibility == false) {                        
                this.processErrorMessage('Le compte bancaire sélectionné n\'est pas visible par l\'entité à la date de la pièce', false);                
                result = false;
            } 
        }

        // check if on step 2 (Order)
        if(this.currentStep === 'step-2') {
            if (this.checkCustomerOrderData.length === 0) {
                //result = false;
                //this.processErrorMessage("Il n'y a aucune commandes !", false);
            } else {
                // For each order
                for(const order of this.checkCustomerOrderData){
                    // Validation rule
                    if(/*!this.isNullOrWhitespace(order.shippingCost__c) &&*/ order.shippingCost__c <= 0){
                        this.processErrorMessage("Commande "+order.OrderNumber+", l'acompte perçu doit être supérieur à 0 !", false);
                        result = false;
                    }
                    if(/*!this.isNullOrWhitespace(order.shippingCost__c) &&*/ order.shippingCost__c > order.shippingCost__c){
                        this.processErrorMessage("Commande "+order.OrderNumber+", l'acompte perçu ne peut pas dépasser l'acompte à percevoir !", false);
                        result = false;
                    }                    
                }                             
            }
		}

        // check if on step 3 (invoices)
        if(this.currentStep === 'step-3') {
            if (this.invoicesData.length === 0) {
                //result = false;
                //this.processErrorMessage("Il n'y a aucune factures !", false);
            } else {
                // For each invoice
                for(const inv of this.invoicesData){
                    // Validation rule
                    if(!this.isNullOrWhitespace(inv.priceReduction__c) && inv.priceReduction__c < 0){
                        this.processErrorMessage("Facture "+inv.Name+", le montant perçu doit être supérieur à 0 !", false);
                        result = false;
                    }
                    if(!this.isNullOrWhitespace(inv.priceReduction__c) && inv.priceReduction__c > inv.toPerceiveAmount__c){
                        this.processErrorMessage("Facture "+inv.Name+", le montant perçu ne peut pas dépasser le montant à percevoir !", false);
                        result = false;
                    }               
                }
            }
		}

        // check if on step 2/3/4
        if(this.currentStep === 'step-4' || this.currentStep === 'step-3' || this.currentStep === 'step-2') {
            if(this.totalAdvPaymentAmountSum + this.totalInvoiceAdvPaymentAmountSum > this.pieceAmount) {
                this.processErrorMessage("Le montant de l'encaissement composite doit être supérieur à la somme des montants perçus sur les acomptes et factures", false);
                result = false;
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
        this.showSaveWarning = true;
        console.log('selectedRowsOrder : '+this.isPreviousState);  
    }

    /**
     * Display the next step of the wizard.
     * Executed when the user clicks on the "Suivant" button of the wizard.
     */
    handleNext() {                        
        this.calculateCosts();
        console.log('currentstep : '+this.currentStep);
        this.resetErrorMessage();
        this.showSaveWarning = true;
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
            this.showSaveWarning = true;            
        }
    }

    /**
     * Get the order selected in the datatable
     * @param {object} event - Event object of the "onrowselection" of the datatable.
     */
     handleSelectedOrdersChange(event) {
        this.resetErrorMessage();
        // Get row selected
        const selectedRows = event.detail.selectedRows;
        // Init the array of orders
        this.selectedOrderRecords = [];        
        // Add order selected in the array
        for(const obj of selectedRows){       
            this.selectedOrderRecords.push(obj.Id);
        } 
        console.log('selectedRowsOrder : '+selectedRows);
        if(selectedRows !== null ) {
            this.calculateCosts();
            console.log('totalAdvPaymentAmountSum ',+this.totalAdvPaymentAmountSum);
            console.log('totalInvoiceAdvPaymentAmountSum ',+this.totalInvoiceAdvPaymentAmountSum);
        }              
    }

    /**
     * Get the invoice selected in the datatable
     * @param {object} event - Event object of the "onrowselection" of the datatable.
     */
     handleSelectedInvoicesChange(event) {
        this.resetErrorMessage();
        // Get row selected
        const selectedRows = event.detail.selectedRows;
        // Init the array of invoices
        this.selectedInvoiceRecords = [];        
        // Add invoice selected in the array
        for(const obj of selectedRows){          
            this.selectedInvoiceRecords.push(obj.Id);
        }        
        this.reloadInvoiceItemData = true; // Reload OrderItem Data
        console.log('selectedRowsInvoice : '+selectedRows);
        console.log('this.selectedInvoiceRecords : '+this.selectedInvoiceRecords);

        /*this.selectedInvoices= [];
        for (const line of this.invoicesData) {
            if(this.selectedInvoiceRecords.includes(line.Id)){
                this.selectedInvoices.push(line);
            }
        }*/
        console.log('this.selectedInvoices : '+this.selectedInvoices);
        console.log('this.invoicesData : '+this.invoicesData);
        if(selectedRows !== null ) {
            this.calculateCosts();
            console.log('totalAdvPaymentAmountSum inv',+this.totalAdvPaymentAmountSum);
            console.log('totalInvoiceAdvPaymentAmountSum inv',+this.totalInvoiceAdvPaymentAmountSum);
        }  
    }

    /**
     * Create the accounting pieces when the users click on "Valider"
     */
    handleCreateAccountingPieces(){
        this.resetErrorMessage();
        this.showLoadingSpinner = true;
        // Check errors, continue if no errors
        if(this.checkForErrors()) {
            this.createAccountingPieces();
        }
    }

    /**
     * Get the values defined in the datatable for each orders
     * @param {object} event - Event object of the "onsave" of the datatable.
     */
    handleOrdersSave(event) {        
        this.resetErrorMessage();
        this.updateDatatableOrders(event.detail.draftValues);        
        this.priceChanged = false;
    }
     

    /**
     * Get the values defined in the datatable for each invoices
     * @param {object} event - Event object of the "onsave" of the datatable.
     */
    handleInvoicesSave(event) {
        this.resetErrorMessage();
        this.updateDatatableInvoices(event.detail.draftValues);
        this.priceChanged = false;
    }

    /**
     * Handle a change on the "Date de la piece" field for the "Encaissement" step
     * @param {object} event - Object of the Event.
     */	
    handlePieceDateChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.pieceDate = event.target.value;
        this.getVisibilityVerification();    
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
        if (this.pieceAccountingDate !== null) {
            this.isRequired = true;
        }
        else{
            this.isRequired = false;
        }     
    }

    /**
     * Handle a change on the "Montant" field for the "Encaissement" step
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
     * Handle a change on the "Banque externe" field for the "Encaissement" step
     * @param {object} event - Object of the Event.
     */	
    handlePieceExternalBankChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.pieceExternalBank = event.target.value;     
    }

    /**
     * Handle a change on the "Référence externe" field for the "Encaissement" step
     * @param {object} event - Object of the Event.
     */	
    handlePieceExternalReferenceChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.pieceExternalReference = event.target.value;     
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
            this.getVisibilityVerification();
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
            this.getVisibilityVerification();
        } else {
            this.pieceBankAccountId = "";
            this.pieceBankAccountName = "";
            this.getBankAccount();
        }
    }

    /**
     * Handle a change on the "Mode de règlement" field for the "Encaissement" step
     * @param {object} event - Object of the Event.
     */
    handlePaymentMethodLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.piecePaymentMethodId = selection[0].id;
            this.piecePaymentMethodName = selection[0].title;
            this.getPaymentMethodInfos();
        } else {
            this.piecePaymentMethodId = "";
            this.piecePaymentMethodName = "";
            this.requiredExternalBank = false;
        }
    }

    /**
     * Handle the sort action on the order's datatable
     * @param {object} event - Object of the Event.
     */
    handleSortOrder(event) {
        console.log(event.detail);
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.customerOrderData];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.customerOrderData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedByOrder = sortedBy;
    }

    /**
     * Handle the sort action on the invoice's datatable
     * @param {object} event - Object of the Event.
     */
    handleSortInvoice(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.invoicesData];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.invoicesData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedByInvoice = sortedBy;
    }

    /* ========== GETTER METHODS ========== */

    get hasOrders() {
        let result = true;
        if (Object.keys(this.customerOrderData).length === 0 && !this.showLoadingSpinner) {
            result = false;
        } 
        return result;
    }

    get hasInvoices() {
        let result = true;
        if (Object.keys(this.invoicesData).length === 0 && !this.showLoadingSpinner) {
            result = false;
        } 
        return result;
    }

    get todaysDate() {
        return new Date().toISOString().slice(0, 10);
    }

    /**
     * Function to call "visibilityVerification" APEX method.
     */    
    getVisibilityVerification(){
        
        try{
            getVisibilityVerification({inputEntityId: this.pieceInputEntityId, bankAccountId: this.pieceBankAccountId, pieceDate: this.pieceDate}).
            then(result => {
                this.banckVisibility= result;
                console.log('log : '+this.banckVisibility);
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        }
        catch(error) {
            this.processErrorMessage(error.message);
        }
    }

    handleDraftValueChange(event){
        this.priceChanged = true;
        console.log('darft change ' +this.priceChanged);
        
    }
    handleCancel(event){
        this.priceChanged = false;
    }
}