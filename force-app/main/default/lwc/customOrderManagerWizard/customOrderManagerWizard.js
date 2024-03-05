/* eslint-disable no-console */
import { LightningElement, api, track, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';

// Apex class methods
import getCancellingReasons from '@salesforce/apex/LWC_CustomOrderManagerWizard.getCancellingReasons';
import getOrder from '@salesforce/apex/LWC_CustomOrderManagerWizard.getOrder';
import getOrderItems from '@salesforce/apex/LWC_CustomOrderManagerWizard.getOrderItems';
import getProviderOrders from '@salesforce/apex/LWC_CustomOrderManagerWizard.getProviderOrders';
import updateOrderItems from '@salesforce/apex/LWC_CustomOrderManagerWizard.updateOrderItems';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

// Constants Path
const PATH_STEPS = [
    { label: 'Sélection de la commande', value: 'step-1', display: true },
    { label: 'Action', value: 'step-2', display: true },	
    { label: 'Sélection des lignes de commande', value: 'step-3', display: true },
    { label: 'Saisie globale', value: 'step-4', display: true },	
    { label: 'Saisie des informations', value: 'step-5', display: true }
];

// Constants for Order and actions list
const ORDER_FIELDS = ['Order.Id', 'Order.Name', 'Order.RecordType.DeveloperName', 'Order.Status', 
                        'Order.transmissionDate__c', 'Order.estimatedShippingCost__c', 'Order.shippingCost__c'];
const STATUS = { GIVEN: "Transmitted", CONFIRMED: "Confirmed", MANUFACTURING: "Manufacturing", 
                       MANUFACTURED: "Manufactured", DELIVERING: "Delivering", DELIVERED: "Delivered", BILLED: "Billed"};
const ACTIONS = { CONFIRM: "Confirmation", MANUFACTURE: "Fabrication", FORCASTED_DELIVER: "Livraison prévisionnelle", 
                       SHIP: "Expédition", DELIVER: "Livraison", BILL: "Facturation", PAYMENT: "Paiement", CANCEL: "Annulation"};
const ACTIONS_MAP = [
    { label: ACTIONS.CONFIRM, value: ACTIONS.CONFIRM },
    //{ label: ACTIONS.MANUFACTURE, value: ACTIONS.MANUFACTURE },
    { label: ACTIONS.FORCASTED_DELIVER, value: ACTIONS.FORCASTED_DELIVER },
    { label: ACTIONS.SHIP, value: ACTIONS.SHIP },
    { label: ACTIONS.DELIVER, value: ACTIONS.DELIVER },
    { label: ACTIONS.BILL, value: ACTIONS.BILL },
    //{ label: ACTIONS.PAYMENT, value: ACTIONS.PAYMENT },
    { label: ACTIONS.CANCEL, value: ACTIONS.CANCEL }
];

// Constants for fields displayed in datatable for each actions
const ORDERITEM_CONFIRMATION_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Dimensions", fieldName: 'dimensions__c'},
    { label: "Emplacement", fieldName: 'location__c'},
    { label: "Date de confirmation", fieldName: 'confirmationDate__c', type: 'date-local' },
    { label: "Date de livraison (prev)", fieldName: 'estimatedDeliveryDate__c', type: 'date-local' }
];
const ENTRIES_CONFIRMATION_COLUMNS = [
    { label: "Produit", fieldName: 'name__c'},
    { label: "Date de confirmation", fieldName: 'confirmationDate__c', type: 'date-local', editable: true  },
    { label: "Numéro de confirmation", fieldName: 'confirmationNumber__c'},
    { label: "Coût des produits (prévisionnel)", fieldName: 'estimatedProductCost__c', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: true  },
    //{ label: "Coût d'expédition (prévisionnel)", fieldName: 'estimatedShippingCost__c', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: true  },
    { label: "Date de livraison (prévisionnelle)", fieldName: 'estimatedDeliveryDate__c', type: 'date-local', editable: true  }
];
const ORDERITEM_MANUFACTURE_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Dimensions", fieldName: 'dimensions__c'},
    { label: "Emplacement", fieldName: 'location__c'},
    { label: "Début de fabrication", fieldName: 'manufacturingStart__c', type: 'date-local' },
    { label: "Fin de fabrication", fieldName: 'manufacturingEnd__c', type: 'date-local'}
];
const ENTRIES_MANUFACTURE_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Début de fabrication", fieldName: 'manufacturingStart__c', type: 'date-local', editable: true  },
    { label: "Fin de fabrication", fieldName: 'manufacturingEnd__c', type: 'date-local', editable: true }
];
const ORDERITEM_FORCASTED_DELIVER_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Dimensions", fieldName: 'dimensions__c'},
    { label: "Emplacement", fieldName: 'location__c'},
    { label: "Date de livraison (prev)", fieldName: 'estimatedDeliveryDate__c', type: 'date-local' }
];
const ENTRIES_FORCASTED_DELIVER_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Date de livraison (prévisionnelle)", fieldName: 'estimatedDeliveryDate__c', type: 'date-local', editable: true  },
    { label: "Coût des produits (prévisionnel)", fieldName: 'estimatedProductCost__c', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: true  }
    //{ label: "Coût d'expédition (prévisionnel)", fieldName: 'estimatedShippingCost__c', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: true  }
];
const ORDERITEM_SHIP_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Dimensions", fieldName: 'dimensions__c'},
    { label: "Emplacement", fieldName: 'location__c'},
    { label: "Date d'expédition", fieldName: 'shippingDate__c', type: 'date-local' }
];
const ENTRIES_SHIP_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Date d expédition", fieldName: 'shippingDate__c', type: 'date-local', editable: true  },
    { label: "Coût des produits (prévisionnel)", fieldName: 'estimatedProductCost__c', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: true  },
    //{ label: "Coût d'expédition (prévisionnel)", fieldName: 'estimatedShippingCost__c', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: true  },
    { label: "Date de livraison (prévisionnelle)", fieldName: 'estimatedDeliveryDate__c', type: 'date-local', editable: true }
];
const ORDERITEM_DELIVER_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Dimensions", fieldName: 'dimensions__c'},
    { label: "Emplacement", fieldName: 'location__c'},
    { label: "Date de livraison", fieldName: 'deliveryDate__c', type: 'date-local' }
];
const ENTRIES_DELIVER_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Numéro de BL", fieldName: 'deliveryNumber__c', editable: true},
    { label: "N° de ligne de BL", fieldName: 'deliveryLineNumber__c', type: 'number', editable: true},
    { label: "Date de livraison", fieldName: 'deliveryDate__c', type: 'date-local', editable: true  },
    { label: "Coût des produits (prévisionnel)", fieldName: 'estimatedProductCost__c', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: true  }
    //{ label: "Coût d'expédition (prévisionnel)", fieldName: 'estimatedShippingCost__c', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: true  }
];
const ORDERITEM_BILL_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Dimensions", fieldName: 'dimensions__c'},
    { label: "Emplacement", fieldName: 'location__c'},
    { label: "Date de facturation", fieldName: 'billingDate__c', type: 'date-local' }
];
const ENTRIES_BILL_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Date de facturation", fieldName: 'billingDate__c', type: 'date-local', editable: true  },
    { label: "Coût des produits (réel)", fieldName: 'productCost__c', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: true  },
    { label: "N° de facture", fieldName: 'invoiceNumber__c', editable: true},
    { label: "N° de ligne de facture", fieldName: 'invoiceLineNumber__c', type: 'number', editable: true}
    //{ label: "Coût d'expédition (réel)", fieldName: 'shippingCost__c', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: true  }
];
const ORDERITEM_PAYMENT_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Dimensions", fieldName: 'dimensions__c'},
    { label: "Emplacement", fieldName: 'location__c'},
    { label: "Date de réception	", fieldName: 'receivedDate__c', type: 'date-local' }
];
const ENTRIES_PAYMENT_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Date de facturation", fieldName: 'billingDate__c', type: 'date-local' },
    { label: "Date de réception	", fieldName: 'receivedDate__c', type: 'date-local', editable: true  },
    { label: "Coût des produits (réel)", fieldName: 'productCost__c', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: true  }
];
const ORDERITEM_CANCEL_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Dimensions", fieldName: 'dimensions__c'},
    { label: "Emplacement", fieldName: 'location__c'},
    { label: "Date d'annulation", fieldName: 'cancellationDate__c', type: 'date-local' }
];

const CANCELLING_REASONS = [
    // list of all picklist options
    { label: 'Annulation client', value: 'Annulation client' },
    { label: 'Annulation K par K', value: 'Annulation K par K' },
    { label: 'Annulation fournisseur', value: 'Annulation fournisseur' },
    { label: 'Refus client', value: 'Refus client' },
    { label: 'Refus K par K', value: 'Refus K par K' },
    { label: 'Refus fournisseur', value: 'Refus fournisseur' }
];

const ENTRIES_CANCEL_COLUMNS = [
    { label: "Produit", fieldName: 'name__c' },
    { label: "Date d'annulation", fieldName: 'cancellationDate__c', type: 'date-local', editable: true  },
    {
        label: "Motif d'annulation", fieldName: 'cancellationReason__c', type: 'picklist', typeAttributes: {
            placeholder: '-- Aucun motif --', options: CANCELLING_REASONS
            , value: { fieldName: 'cancellationReason__c' } // default value for picklist
            , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
        }
    }
];



export default class CustomOrderManagerWizard extends NavigationMixin(LightningElement) {
    // Current object api name
    @api objectApiName;
    // Current record's id
    @api recordId;
    // Current record
    @track record;

    // Setupped collections
    @track orderItemsActionColumns = ORDERITEM_CONFIRMATION_COLUMNS;
    @track orderItemsInputColumns = ENTRIES_CONFIRMATION_COLUMNS;
    @track cancellingActionColumns = [];
    @track actionValues = ACTIONS_MAP;

    // Data collections
    @track providerOrdersData = [];
    @track orderItemsData = [];
    @track orderItemsActionData = [];
    orderItemsInputData = [];
    orderItemsInputData2 = [{name__c: 'Ligne à copier',confirmationDate__c: null, confirmationNumber__c: null,
                            shippingCost__c : null, estimatedShippingCost__c: null, productCost__c: null, estimatedProductCost__c: null,
                            cancellationDate__c : null, shippingDate__c: null, manufacturingStart__c: null, billingDate__c: null,
                            manufacturingEnd__c : null, deliveryDate__c: null, contractualDeliveryDate__c: null, estimatedDeliveryDate__c: null,
                            cancellationReason__c : null, receivedDate__c: null, invoiceNumber__c: null, invoiceLineNumber__c: null}];
    @track draftValues = [];
    @track draftValuesTest = [];
    @track draftValuesTest2 = [];
    @track selectedRows = [];
    @track tempData = [];

    // Selection variables
    @track selectedActionValue;
    @track selectedProviderValue;

    // Wizard Status
    @track activeWizard = true;
    @track currentStep = "step-1";
    @track steps = PATH_STEPS;
    @track showStep1Form = false;
    @track showStep2Form = false;
    @track showStep3Form = false;
    @track showStep4Form = false;
    @track showStep5Form = false;
    @track showCopyComponent = true;
    @track showNextButton = true;
    @track showPreviousButton = false;
    @track disableCustomerOrderChoice = false;
    @track showGlobalDataField = false;
    @track showCostPrevField = false; 
    @track showCostRealField = false; 
    @track showPaiementDateField = false;
    @track showInvoiceDateField = false;
    @track showDeliveryNumberField = false;
    @track showInvoiceNumberField = false;
    @track showDeliveryDatePrevField = false;
    @track showCostProductPrevField = false;
    @track showDeliveryDateField = false;
    @track showConfirmationDateField = false;
    @track showConfirmationNumberField = false;
    @track showEndFabricationDateField = false;
    @track showStartFabricationDateField = false;
    @track showCancelDateField = false; 
    @track showCancellingReasonField = false;

    @track productCostReal;
    @track prudctCostPrev;
    @track startFabricationDate;
    @track invoiceDate;
    @track endFabricationDate;
    @track deliveryDate;
    @track deliveryDatePrev;
    @track deliveryNumber;
    @track invoiceNumber;
    @track paiementDate;
    @track cancelDate;
    @track cancellingReason;
    @track confirmationDate;
    @track confirmationNumber;
    @track expeditionCostPrev;
    @track expeditionCostReal;

    // Field to copy
    /*@track copyConfirmDate;
    @track copyProductCost;
    @track copyExpCost;
    @track copyDeliveredDate;*/

    // Event data
    @track showLoadingSpinner = false;
    @track error;
    
    // Picklists
    @track providerOrderPicklistValues = [];
    @track cancellingReasonsPicklistValues = CANCELLING_REASONS;

    // Non reactive variables    
    activeSaisieSections = ['orderGlobalData', 'lineGlobalData'];
    selectedRecords = [];
     
    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();

        // Init body
        this.showLoadingSpinner = true;
        this.updateWizardBody();
    }

    /* ========== WIRED METHODS ========== */

    @wire(getRecord, { recordId: '$recordId', fields: ORDER_FIELDS })
    orders(result) {
        // Hold on to the provisioned value so we can refresh it later.
        this.record = result; // track the provisioned value
        const { data, error } = result; // destructure the provisioned value
        if (data) {
            // Display action or the list or providers order
            this.initFirstStep();
        } else if (error) {
            this.processErrorMessage(error);
        }
    }

    /**
     * Retrieving cancelling reasons
     */
    /*@wire(getCancellingReasons, { sOrderId: '$recordId'})
    cancellingReasons(resultCR) {
        if (resultCR.data) {
            let optionsCR = [];
            for(let key in resultCR.data){
                this.cancellingReasonsPicklistValues.push({value: resultCR.data[key].Name, label : resultCR.data[key].Name}); 
                //optionsCR.push({value:resultCR.data[key].Id, label:resultCR.data[key].Name});
            }
            this.cancellingReasonsLoaded = true;
            this.cancellingActionColumns = [
                { label: "Produit", fieldName: 'name__c' },
                { label: "Date d'annulation", fieldName: 'cancellationDate__c', type: 'date-local', editable: true  },
                //{ label: "Motif d'annulation", fieldName: 'cancellationReason__c', editable: true }
                {
                    label: "Motif d'annulation", fieldName: 'cancellationReason__c', type: 'picklist', typeAttributes: {
                        placeholder: '-- Aucun motif --', options: optionsCR // list of all picklist options
                        , value: { fieldName: 'cancellationReason__c' } // default value for picklist
                        , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
                    }
                }
            ];
        } else if (resultCR.error) {
            this.processErrorMessage(resultCR.error);
        }
    }*/

    /* ========== EVENT METHODS ========== */
    
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
        this.updateWizardBody();
    }

    /**
     * Handle the selected action value.
     * Executed when the user change the provider on step 1.
     */
    handleProviderChange(event) {
        this.selectedProviderValue = event.target.value;
        // If an order is selected     
        if(this.selectedProviderValue) {   
            // Get Order Details
            this.getOrderDetails();   
            // Get OrderItems Details
            this.getOrderItemsDetails(this.selectedProviderValue);
        }
    }

    /**
     * Handle the selected action value.
     * Executed when the user change the action on step 1.
     */
    handleActionChange(event) {
        if(event.detail === undefined){
            this.selectedActionValue = event;
        } else {
            this.selectedActionValue = event.detail.value;
        }
        this.orderItemsActionData = this.orderItemsData;
        this.orderItemsInputData = [];
        this.orderItemsActionColumns = [];
        this.orderItemsInputColumns = [];
        this.selectedRecords = [];
        // For each action : Setup step-3 columns, setup step-4 colums, and pre-select correct lines depending on field values
        switch (this.selectedActionValue) {
            case ACTIONS.CONFIRM:
                for (const line of this.orderItemsData) {
                    if(line.deliveryDate__c == null  && line.estimatedDeliveryDate__c == null){
                        this.selectedRecords.push(line.Id);
                        this.orderItemsInputData.push(line);
                    }
                }
                this.orderItemsActionColumns = ORDERITEM_CONFIRMATION_COLUMNS;
                this.orderItemsInputColumns = ENTRIES_CONFIRMATION_COLUMNS;
                break;
            case ACTIONS.MANUFACTURE:
                for (const line of this.orderItemsData) {
                    if(line.manufacturingEnd__c == null){
                        this.selectedRecords.push(line.Id);
                        this.orderItemsInputData.push(line);
                    }
                }
                this.orderItemsActionColumns = ORDERITEM_MANUFACTURE_COLUMNS;
                this.orderItemsInputColumns = ENTRIES_MANUFACTURE_COLUMNS;
                break;
            case ACTIONS.FORCASTED_DELIVER:
                for (const line of this.orderItemsData) {
                    if(line.deliveryDate__c == null  && line.estimatedDeliveryDate__c == null){
                        this.selectedRecords.push(line.Id);
                        this.orderItemsInputData.push(line);
                    }
                }
                this.orderItemsActionColumns = ORDERITEM_FORCASTED_DELIVER_COLUMNS;
                this.orderItemsInputColumns = ENTRIES_FORCASTED_DELIVER_COLUMNS;
                break;
            case ACTIONS.SHIP:
                for (const line of this.orderItemsData) {
                    if(line.shippingDate__c == null){
                        this.selectedRecords.push(line.Id);
                        this.orderItemsInputData.push(line);
                    }
                }
                this.orderItemsActionColumns = ORDERITEM_SHIP_COLUMNS;
                this.orderItemsInputColumns = ENTRIES_SHIP_COLUMNS;
                break;
            case ACTIONS.DELIVER:
                for (const line of this.orderItemsData) {
                    if(line.deliveryDate__c == null){
                        this.selectedRecords.push(line.Id);
                        this.orderItemsInputData.push(line);
                    }
                }
                this.orderItemsActionColumns = ORDERITEM_DELIVER_COLUMNS;
                this.orderItemsInputColumns = ENTRIES_DELIVER_COLUMNS;
                break;
            case ACTIONS.BILL:
                for (const line of this.orderItemsData) {
                    if(line.billingDate__c == null){
                        this.selectedRecords.push(line.Id);
                        this.orderItemsInputData.push(line);
                    }
                }
                this.orderItemsActionColumns = ORDERITEM_BILL_COLUMNS;
                this.orderItemsInputColumns = ENTRIES_BILL_COLUMNS;
                break;
            case ACTIONS.PAYMENT:
                for (const line of this.orderItemsData) {
                    if(line.receivedDate__c == null){
                        this.selectedRecords.push(line.Id);
                        this.orderItemsInputData.push(line);
                    }
                }
                this.orderItemsActionColumns = ORDERITEM_PAYMENT_COLUMNS;
                this.orderItemsInputColumns = ENTRIES_PAYMENT_COLUMNS;
                break;
            case ACTIONS.CANCEL:
                this.orderItemsActionColumns = ORDERITEM_CANCEL_COLUMNS;
                this.orderItemsInputColumns = ENTRIES_CANCEL_COLUMNS;
                break;
            default:
                this.orderItemsInputData = this.orderItemsData;
                this.orderItemsActionColumns = ORDERITEM_CONFIRMATION_COLUMNS;
                this.orderItemsInputColumns = ENTRIES_CONFIRMATION_COLUMNS;
                break;
        }
        console.log('this.orderItemsData : '+this.orderItemsData);
    }

    /**
     * Get the order items selected in the datatable
     * @param {object} event - Event object of the "onrowselection" of the datatable.
     */
    handleSelectedOrderItemsChange(event) {
        this.resetErrorMessage();
        // Get row selected
        const selectedRows = event.detail.selectedRows;
        // Init the array of OrderItem
        this.selectedRecords = [];   
        this.orderItemsInputData = event.detail.selectedRows;     
        // Add OrderItem selected in the array
        for(const row of selectedRows){         
            this.selectedRecords.push(row.Id);
        }
    }

    /**
     * Refresh the data in the datatable after update.
     * Executed when the user clicks on the "Copier pour tous" button of the wizard.
     */
    handleRefresh(draftValues) {
        this.tempData = this.orderItemsInputData;
        this.orderItemsInputData = [];
        for(const oi of this.tempData){
            for(const line of draftValues) {
                // Update fields values
                if(oi.Id === line.Id){
                    oi.confirmationDate__c = (line.confirmationDate__c != null) ? line.confirmationDate__c : oi.confirmationDate__c;
                    oi.shippingCost__c = (line.shippingCost__c != null) ? line.shippingCost__c : oi.shippingCost__c;
                    oi.shippingCost__c = (line.shippingCost__c != null) ? line.shippingCost__c : oi.shippingCost__c;
                    oi.estimatedShippingCost__c = (line.estimatedShippingCost__c != null) ? line.estimatedShippingCost__c : oi.estimatedShippingCost__c;
                    oi.productCost__c = (line.productCost__c != null) ? line.productCost__c : oi.productCost__c;
                    oi.productCost__c = (line.productCost__c != null) ? line.productCost__c : oi.productCost__c;
                    oi.estimatedProductCost__c = (line.estimatedProductCost__c != null) ? line.estimatedProductCost__c : oi.estimatedProductCost__c;
                    oi.cancellationDate__c = (line.cancellationDate__c != null) ? line.cancellationDate__c : oi.cancellationDate__c;
                    oi.shippingDate__c = (line.shippingDate__c != null) ? line.shippingDate__c : oi.shippingDate__c;
                    oi.manufacturingStart__c = (line.manufacturingStart__c != null) ? line.manufacturingStart__c : oi.manufacturingStart__c;
                    oi.billingDate__c = (line.billingDate__c != null) ? line.billingDate__c : oi.billingDate__c;
                    oi.manufacturingEnd__c = (line.manufacturingEnd__c != null) ? line.manufacturingEnd__c : oi.manufacturingEnd__c;
                    oi.deliveryDate__c = (line.deliveryDate__c != null) ? line.deliveryDate__c : oi.deliveryDate__c;
                    oi.contractualDeliveryDate__c = (line.contractualDeliveryDate__c != null) ? line.contractualDeliveryDate__c : oi.contractualDeliveryDate__c;
                    oi.estimatedDeliveryDate__c = (line.estimatedDeliveryDate__c != null) ? line.estimatedDeliveryDate__c : oi.estimatedDeliveryDate__c;
                    oi.cancellationReason__c = (line.cancellationReason__c != null) ? line.cancellationReason__c : oi.cancellationReason__c;
                    oi.receivedDate__c = (line.receivedDate__c != null) ? line.receivedDate__c : oi.receivedDate__c;
                    oi.cancellationDate__c = (line.cancellationDate__c != null) ? line.cancellationDate__c : oi.cancellationDate__c;
                    oi.deliveryNumber__c = (line.deliveryNumber__c != null) ? line.deliveryNumber__c : oi.deliveryNumber__c;
                    oi.deliveryLineNumber__c = (line.deliveryLineNumber__c != null) ? line.deliveryLineNumber__c : oi.deliveryLineNumber__c;
                    oi.invoiceNumber__c = (line.invoiceNumber__c != null) ? line.invoiceNumber__c : oi.invoiceNumber__c;
                    oi.invoiceLineNumber__c = (line.invoiceLineNumber__c != null) ? line.invoiceLineNumber__c : oi.invoiceLineNumber__c;
                    oi.confirmationNumber__c = (line.confirmationNumber__c != null) ? line.confirmationNumber__c : oi.confirmationNumber__c;
                    console.log("oi.cancellationReason__c "+oi.cancellationReason__c);
                }
            }
            this.orderItemsInputData.push(oi);
        }
        this.tempData = [];
    }    

    /**
     * Get the values defined in the datatable for each order items
     * @param {object} event - Event object of the "onsave" of the datatable.
     */
    handleOrderItemsSave(event) {
        this.resetErrorMessage();
        let result = true;
        this.draftValues =  event.detail.draftValues;
        result = this.checkForErrors();
            // Call APEX action to update the OrderItem
            if(result === true) {
                this.updateOrderItems(event.detail.draftValues);
        }
    }

    /* ========== GETTER METHODS ========== */

    get hasProviderOrders() {
        let result = true;
        if (Object.keys(this.providerOrdersData).length === 0) {
            result = false;
        } 
        return result;
    }

    /* ========== JS METHODS ========== */
    
    /**
     * Function executed when the user click on the Previous/Next button to update the form.
     */
    updateWizardBody(){
        this.showStep1Form = false;
        this.showStep2Form = false;
        this.showStep3Form = false;
        this.showStep4Form = false;
        this.showStep5Form = false;
        this.showPreviousButton = true;
        this.showNextButton = true;
        switch (this.currentStep) {
            case 'step-1':
                this.showStep1Form = true;
                this.showPreviousButton = false;
                break;
            case 'step-2':
                if(this.disableCustomerOrderChoice) {
                    this.showPreviousButton = false;
                }
                this.showStep2Form = true;
                break;
            case 'step-3':
                
                this.handleActionChange(this.selectedActionValue);
                this.showStep3Form = true;
                break;
            case 'step-4':
                this.showStep4Form = true;
                this.automaticShowField();
                break;
            case 'step-5':
                this.showStep5Form = true;
                this.showNextButton = false;
                this.handleCopy();
                break;
        }
    }

    /**
     * Function executed when the component get the order informations to display the first step.
     */
    initFirstStep(refresh = false) {
        // CUSTOMER ORDER
        if(this.record.data.fields.RecordType.value.fields.DeveloperName.value === 'CustomerOrder') {
            this.getProviderOrdersList();
            // Go to the step 1 (selection of providers order)
            this.currentStep = 'step-1';
            this.updateWizardBody();
        // PROVIDER ORDER
        } else if (this.record.data.fields.RecordType.value.fields.DeveloperName.value === 'ProviderOrder') {
            // Select current order as the selected order in step-1, skip/disable step-1
            if(this.record.data.fields.transmissionDate__c.value == null || this.record.data.fields.transmissionDate__c.value === undefined) {           
                this.activeWizard = false;
            } else {
                this.activeWizard = true;
            }
            this.selectedProviderValue = this.recordId;
            this.disableCustomerOrderChoice = true;
            this.getOrderItemsDetails(this.recordId);
            // Define the default values in the step 4
            this.expeditionCostPrev = this.record.data.fields.estimatedShippingCost__c.value;
            this.expeditionCostReal = this.record.data.fields.shippingCost__c.value;
            // If refresh
            if(refresh) {
                // Use the value to refresh getOrder() function.
                refreshApex(this.record);
            } else {
                this.selectedActionValue=this.actionValues[0].value;
                this.automaticActionSelection(this.record.data.fields.Status.value);

            }
            // Go to the step 2 (action)
            this.currentStep = 'step-2';
            this.updateWizardBody();
        }            
        this.showLoadingSpinner = false;
    }

    /**
     * Retrieving the order choosed in the picklist
     */
    getOrderDetails() {
        // Call APEX action to get Order information
        getOrder({ 
            orderId: this.selectedProviderValue
        })
        .then(result => {
            if(result) {
                // Define the default action in the step 2
                this.automaticActionSelection(result.Status);
                // Define the default values in the step 4
                this.expeditionCostPrev = result.estimatedShippingCost__c;
                this.expeditionCostReal = result.shippingCost__c;
                this.error = undefined;
            } else {                
                this.processErrorMessage(result.error);
            }
            this.showLoadingSpinner = false;
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
    }

    /**
     * Retrieving the provider orders of the customer order
     */
    getProviderOrdersList() {
        this.providerOrderPicklistValues = [];
        // Call APEX action to get every provider order from the customer order (parent)
        getProviderOrders({ 
            orderId: this.recordId
        })
        .then(result => {
            if (result) {
                this.providerOrdersData = result;
                // Provider Orders picklist creation to display on step-1
                //this.providerOrderPicklistValues.push({label:"-- Aucune sélection --", value:""});            
                // eslint-disable-next-line guard-for-in
                for(const key in result){
                    if(this.selectedProviderValue == null){
                        this.selectedProviderValue = key;
                        this.getOrderDetails(); // Get Order Details of the first Order
                        this.getOrderItemsDetails(this.selectedProviderValue); // Get data information from the fist Order
                    }
                    this.providerOrderPicklistValues.push({label:result[key], value:key}); 
                }
                this.error = undefined;
            } else if (result.error) {
                this.processErrorMessage(result.error);
            }
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
    }   
    
    /**
     * Retrieving the orderItems using wire service
     * @param {string} pOrderId - Id of the order.
     */
    getOrderItemsDetails(pOrderId) {
        // Call APEX action to update the WorkOrder
        getOrderItems({ 
            orderId: pOrderId
        })
        .then(result => {
            if(result) {
                this.orderItemsData = result;
                this.orderItemsActionData = result;
                this.error = undefined;
            } else {                
                this.processErrorMessage(result.error);
                this.orderItemsData = undefined;
            }
            this.showLoadingSpinner = false;
        })
        .catch(error => {
            this.processErrorMessage(error);
            this.orderItemsData = undefined;
        });
    }    

    /**
     * Handle the selected action value.
     * Executed when the user change the action on step 1.
     * @param {string} status - Status of the order.
     */
    automaticActionSelection(status) {
        for(const action of this.actionValues) {        
            if(action.value === ACTIONS.CONFIRM && status === STATUS.GIVEN){
                this.selectedActionValue = action.value;
            } else if(action.value === ACTIONS.FORCASTED_DELIVER && status === STATUS.CONFIRMED){
                this.selectedActionValue = action.value;
            } else if(action.value === ACTIONS.FORCASTED_DELIVER && status === STATUS.MANUFACTURING){
                this.selectedActionValue = action.value; 
            } else if(action.value === ACTIONS.SHIP && status === STATUS.MANUFACTURED){
                this.selectedActionValue = action.value; 
            } else if(action.value === ACTIONS.DELIVER && status === STATUS.DELIVERING){
                this.selectedActionValue = action.value; 
            } else if(action.value === ACTIONS.BILL && status === STATUS.DELIVERED){
                this.selectedActionValue = action.value;
            } else if(action.value === ACTIONS.PAYMENT && status === STATUS.BILLED){
                this.selectedActionValue = action.value; 
            } 
        }
        if(this.selectedActionValue != null && this.selectedActionValue !== undefined) {
            this.handleActionChange(this.selectedActionValue);
        }
    }

    /**
     * Handle the selected action value.
     * Executed when the user arrive on the step2.
     */
     automaticShowField() { 
            console.log('automaticShowField - selectedActionValue : '+this.selectedActionValue);         
            if(this.selectedActionValue === ACTIONS.CONFIRM){
                this.showGlobalDataField = true;
                this.showCostPrevField = true; 
                this.showCostProductPrevField = false;
                this.showDeliveryDatePrevField = true;
                this.showConfirmationDateField = true;
                this.showConfirmationNumberField = true;
                this.showDeliveryDateField = false;
                this.showCostRealField = false;
                this.showPaiementDateField = false;
                this.showStartFabricationDateField = false;
                this.showEndFabricationDateField = false;
                this.showDeliveryNumberField = false;
                this.showInvoiceNumberField = false;
                this.showCancelDateField = false;
                this.showCancellingReasonField = false;
            } else if(this.selectedActionValue === ACTIONS.FORCASTED_DELIVER){
                this.showGlobalDataField = true;
                this.showCostPrevField = true;  
                this.showCostProductPrevField = false;
                this.showDeliveryDatePrevField = true;
                this.showConfirmationDateField = false;
                this.showConfirmationNumberField = false;
                this.showDeliveryDateField = false;
                this.showCostRealField = false;
                this.showPaiementDateField = false;
                this.showStartFabricationDateField = false;
                this.showEndFabricationDateField = false;
                this.showDeliveryNumberField = false;
                this.showInvoiceNumberField = false;
                this.showCancelDateField = false;
                this.showCancellingReasonField = false;
            } else if(this.selectedActionValue === ACTIONS.MANUFACTURE){
                this.showStartFabricationDateField = true;
                this.showEndFabricationDateField = true;
                this.showDeliveryDateField = false;
                this.showCostRealField = false;
                this.showPaiementDateField = false;
                this.showConfirmationDateField = false;
                this.showConfirmationNumberField = false;
                this.showCostPrevField = false; 
                this.showCostProductPrevField = false;
                this.showDeliveryDatePrevField = false;
                this.showGlobalDataField = false;
                this.showDeliveryNumberField = false;
                this.showInvoiceNumberField = false;
                this.showCancelDateField = false;
                this.showCancellingReasonField = false;
            } else if(this.selectedActionValue === ACTIONS.SHIP){
                this.showGlobalDataField = true;
                this.showCostPrevField = true; 
                this.showCostProductPrevField = true;
                this.showDeliveryDatePrevField = true;
                this.showDeliveryDateField = true;
                this.showCostRealField = false;
                this.showConfirmationDateField = false;
                this.showConfirmationNumberField = false;
                this.showPaiementDateField = false;
                this.showStartFabricationDateField = false;
                this.showEndFabricationDateField = false;
                this.showDeliveryNumberField = false;
                this.showInvoiceNumberField = false;
                this.showCancelDateField = false;
                this.showCancellingReasonField = false;
            } else if(this.selectedActionValue === ACTIONS.DELIVER){
                this.showGlobalDataField = true;
                this.showCostPrevField = true; 
                this.showCostProductPrevField = false;
                this.showDeliveryDatePrevField = false;
                this.showDeliveryNumberField = true;
                this.showDeliveryDateField = true;
                this.showConfirmationDateField = false;
                this.showConfirmationNumberField = false;
                this.showCostRealField = false;
                this.showPaiementDateField = false;
                this.showStartFabricationDateField = false;
                this.showEndFabricationDateField = false;
                this.showInvoiceNumberField = false;
                this.showCancelDateField = false;
                this.showCancellingReasonField = false;
            } else if(this.selectedActionValue === ACTIONS.BILL){
                this.showGlobalDataField = true;
                this.showCostRealField = false;
                this.showInvoiceDateField = true;
                this.showDeliveryDateField = false;
                this.showPaiementDateField = false;
                this.showCostPrevField = false; 
                this.showCostProductPrevField = false;
                this.showDeliveryDatePrevField = false;
                this.showConfirmationDateField = false;
                this.showConfirmationNumberField = false;
                this.showStartFabricationDateField = false;
                this.showEndFabricationDateField = false;
                this.showDeliveryNumberField = false;
                this.showInvoiceNumberField = true;
                this.showCancelDateField = false;
                this.showCancellingReasonField = false;
            } else if(this.selectedActionValue === ACTIONS.PAYMENT){
                this.showGlobalDataField = true;
                this.showCostRealField = true;
                this.showInvoiceDateField = true;
                this.showPaiementDateField = true;
                this.showDeliveryDateField = false;
                this.showCostPrevField = false; 
                this.showCostProductPrevField = false;
                this.showConfirmationDateField = false;
                this.showConfirmationNumberField = false;
                this.showDeliveryDatePrevField = false;
                this.showStartFabricationDateField = false;
                this.showEndFabricationDateField = false;
                this.showDeliveryNumberField = false;
                this.showInvoiceNumberField = false;
                this.showCancelDateField = false;
                this.showCancellingReasonField = false;
            } else if(this.selectedActionValue === ACTIONS.CANCEL){
                this.showGlobalDataField = false;
                this.showCancelDateField = true;
                this.showCancellingReasonField = true;
                this.showCostRealField = false;
                this.showInvoiceDateField = false;
                this.showPaiementDateField = false;
                this.showDeliveryDateField = false;
                this.showCostPrevField = false; 
                this.showCostProductPrevField = false;
                this.showConfirmationDateField = false;
                this.showConfirmationNumberField = false;
                this.showDeliveryDatePrevField = false;
                this.showStartFabricationDateField = false;
                this.showEndFabricationDateField = false;
                this.showDeliveryNumberField = false;
                this.showInvoiceNumberField = false;
            } 
    }

    /**
     * Execute the process to update the Order Items.
     * @param {object} draftValues - Values defined in the datatable for each order items.
     */
    updateOrderItems(draftValues) {
        this.showLoadingSpinner = true;
        // Update draft value
        draftValues.forEach(el => {
            this.orderItemsInputData.forEach(element => {
                console.log("element.Id "+element.Id);
                console.log("el.Id "+el.Id);
                if (element.Id === el.Id) {
                    el.cancellationReason__c = element.cancellationReason__c;
                    console.log("element.cancellationReason__c "+element.cancellationReason__c);
                }
            });
            console.log("el.cancellationReason__c "+el.cancellationReason__c);
        });
        // If this.orderTotalCost is empty then is null
        if(this.expeditionCostPrev === "") {
            this.expeditionCostPrev = null;
        }
        if(this.expeditionCostReal === "") {
            this.expeditionCostReal = null;
        }
        // Call APEX action to update the OrderItems
        updateOrderItems({ 
            newValues: draftValues,
            expeditionCostPrev : this.expeditionCostPrev,
            expeditionCostReal : this.expeditionCostReal,
            orderId : this.recordId,            
            showCostPrevField : this.showCostPrevField,
            showCostRealField : this.showCostRealField,
            selectedActionValue : this.selectedActionValue
        })
        .then(result => {
            if(result) {
                this.showNotification('Lignes de commandes modifiées', "Les lignes de commandes ont bien été enregistrées.", 'success');
                // Display fresh data in the datatable
                this.handleRefresh(draftValues);
                // Clear all draft values
                this.draftValues = [];
                this.draftValuesTest = [];
                // Display action or the list or providers order
                //this.initFirstStep(true);
                // Close the quick action
                this.closeQuickAction();
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
     * Function to close the quick action.
     */
    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }

    /**
     * Function to check all errors before changing step.
     */
    checkForErrors() {
        let result = true;
        // check if on step 1 there is a selected customer order 
        if(this.currentStep === 'step-1') {
            if (!this.selectedProviderValue) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner une commande.", false);
            } 
        // check if on step 2 there is a selected action	
        } else if(this.currentStep === 'step-2') {	
            if (!this.selectedActionValue) {	
                result = false;	
                this.processErrorMessage("Vous devez sélectionner une action à effectuer.", false);	
            } 
        // check if on step 3 there is a selected provider order 	
        } else if(this.currentStep === 'step-3') {	
            if (this.orderItemsInputData.length === 0) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner au minimum une ligne.", false);
            }
        // check if on step 4, datas are valid
        } else if(this.currentStep === 'step-4') {	
            // Check if input fields are OK
            const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
            }, true);
            
            if (!allValid) {             
                result = false;
            }            
        // check if on step 5, datas are valid
        } else if(this.currentStep === 'step-5' && this.selectedActionValue == ACTIONS.BILL) {
            for(const draftValue of this.draftValues) {
                if ((this.isNullOrWhitespace(draftValue.invoiceLineNumber__c) && !this.isNullOrWhitespace(draftValue.invoiceNumber__c)) || 
                (!this.isNullOrWhitespace(draftValue.invoiceLineNumber__c) && this.isNullOrWhitespace(draftValue.invoiceNumber__c))) {
                    result = false;
                    this.processErrorMessage("Les champs « N° de facture » et « N° ligne de facture » sont liés : si l'un est saisi, l'autre doit l'être aussi", false);
                }
                if(this.isNullOrWhitespace(draftValue.productCost__c)){
                    result = false;
                    this.processErrorMessage("Le coût des produits (réel) doit être renseigné", false);
                } 
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
     * Function to check if the value is null.
     */
     isNullOrWhitespace( input ) {
        return  !input || input.toString().replace(/\s/g, '').length < 1;
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

    /* ========== EVENT METHODS ========== */

    //listener handler to get the context and data
    //updates datatable
    handleDatatablePicklistChanged(event) {
        event.stopPropagation();
        const dataRecieved = event.detail.data;
        this.orderItemsInputData.forEach(element => {
            console.log('element.Id : '+element.Id);
            console.log('dataRecieved.value : '+dataRecieved.value);
            console.log('dataRecieved.context : '+dataRecieved.context);
            if (element.Id === dataRecieved.context) {
                element.cancellationReason__c = dataRecieved.value;
                console.log('SUCCESS : '+dataRecieved.context);
            }
        });
    }

    /**
     * Copy the fields in all OrderItem.
     * Executed when the user clicks on the "Save" button of the wizard.
     */
    handleCopy() {
        this.resetErrorMessage();
        // Copy the OrderItem to copy to all the OrderItem
        this.draftValuesTest = this.orderItemsInputData;
        
        for(const line of this.draftValuesTest) {
            if(this.productCostReal != null){
                line.productCost__c = this.productCostReal;
            }
            if(this.productCostPrev != null){
                line.estimatedProductCost__c = this.productCostPrev;
            }
            if(this.confirmationDate != null){
                line.confirmationDate__c = this.confirmationDate;
            }
            if(this.confirmationNumber != null){
                line.confirmationNumber__c = this.confirmationNumber;
            }
            if(this.startFabricationDate != null){
                line.manufacturingStart__c = this.startFabricationDate;
            }
            if(this.invoiceDate != null){
                line.billingDate__c = this.invoiceDate;
            }
            if(this.endFabricationDate != null){
                line.manufacturingEnd__c = this.endFabricationDate;
            }
            if(this.deliveryDate != null){
                line.deliveryDate__c = this.deliveryDate;
            }
            if(this.deliveryDatePrev != null){
                line.estimatedDeliveryDate__c = this.deliveryDatePrev;
            }
            if(this.deliveryNumber != null){
                line.deliveryNumber__c = this.deliveryNumber;
            }
            if(this.invoiceNumber != null){
                line.invoiceNumber__c = this.invoiceNumber;
            }
            if(this.paiementDate != null){
                line.receivedDate__c = this.paiementDate;
            }
            if(this.cancelDate != null){
                line.cancellationDate__c = this.cancelDate;
            }
            if(this.cancellingReason != null){
                line.cancellationReason__c = this.cancellingReason;
            }
        }
        
        this.orderItemsInputData2 = [{name__c: 'Ligne à copier', confirmationDate__c: null, confirmationNumber__c: null,
                                shippingCost__c : null, estimatedShippingCost__c: null, productCost__c: null, estimatedProductCost__c: null,
                                cancellationDate__c : null, shippingDate__c: null, manufacturingStart__c: null, billingDate__c: null, deliveryNumber__c: null,
                                manufacturingEnd__c : null, deliveryDate__c: null, contractualDeliveryDate__c: null, estimatedDeliveryDate__c: null,
                                cancellationReason__c : null, receivedDate__c: null}];
        this.draftValuesTest2 = [];
        this.showCopyComponent = false;
    }

    getSelectedRows(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    /**
     * Set the value of the provider for all product picklist
     * @param {object} event - Event object of the "onchange".
     */
    handleChangeValueConfirmDate(event) {
        this.copyConfirmDate = event.detail.value;
    }
    
    /**
     * Set the value of the provider for all product picklist
     * @param {object} event - Event object of the "onchange".
     */
    handleChangeValueProductCost(event) {
        this.copyProductCost = event.detail.value;
    }
    
    /**
     * Set the value of the provider for all product picklist
     * @param {object} event - Event object of the "onchange".
     */
    handleChangeValueExpCost(event) {
        this.copyExpCost = event.detail.value;
    }
    
    /**
     * Set the value of the provider for all product picklist
     * @param {object} event - Event object of the "onchange".
     */
    handleChangeValueDeliveredDate(event) {
        this.copyDeliveredDate = event.detail.value;
    }

    /**
     * Set the value of expedition cost prev in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangeCostPrev(event) {
        this.expeditionCostPrev = event.detail.value;
    }

    /**
     * Set the value of expedition cost real in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangeCostReal(event) {
        this.expeditionCostReal = event.detail.value;
    }

    /**
     * Set the value of expedition cost real in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangeStartFabricationDate(event) {
        this.startFabricationDate = event.detail.value;
    }

    /**
     * Set the value of confirmation date in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangeConfirmationDate(event) {
        this.confirmationDate = event.detail.value;
    }

    /**
     * Set the value of confirmation date in the datatable
     * @param {object} event - Event object of the "onchange".
     */
    handleChangeConfirmationNumber(event) {
        this.confirmationNumber = event.detail.value;
    }

    /**
     * Set the value of expedition cost real in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangeEndFabricationDate(event) {
        this.endFabricationDate = event.detail.value;
    }
    
    /**
     * Set the value of expedition cost real in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangeDeliveryDate(event) {
        this.deliveryDate = event.detail.value;
    }
    
    /**
     * Set the value of expedition cost real in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangeProductCostPrev(event) {
        this.productCostPrev = event.detail.value;
    }

    /**
     * Set the value of expedition cost real in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangeDeliveryDatePrev(event) {
        this.deliveryDatePrev = event.detail.value;
    }

    /**
     * Set the value of expedition cost real in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangeDeliveryNumber(event) {
        this.deliveryNumber = event.detail.value;
    }

    /**
     * Set the value of expedition cost real in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangeInvoiceDate(event) {
        this.invoiceDate = event.detail.value;
    }

    /**
     * Set the value of expedition cost real in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangeInvoiceNumber(event) {
        this.invoiceNumber = event.detail.value;
    }

    /**
     * Set the value of expedition paiement date in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangePaiementDate(event) {
        this.paiementDate = event.detail.value;
    }

    /**
     * Set the value of expedition cancel date in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangeCancelDate(event) {
        this.cancelDate = event.detail.value;
    }

    /**
     * Set the value of cancel reason in the datatable
     * @param {object} event - Event object of the "onchange".
     */
    handleChangeCancellingReason(event) {
        this.cancellingReason = event.detail.value;
    }

    /**
     * Set the value of expedition cost real in the datatable
     * @param {object} event - Event object of the "onchange".
     */
     handleChangeProductCostReal(event) {
        this.productCostReal = event.detail.value;
    }

    removeDraftValues() {
        for(const line of this.draftValuesTest) {
            line.confirmationDate__c = null;
            line.confirmationNumber__c = null;
            line.shippingCost__c = null;
            line.shippingCost__c = null;
            line.estimatedShippingCost__c = null;
            line.productCost__c = null;
            line.productCost__c = null;
            line.estimatedProductCost__c = null;
            line.cancellationDate__c = null;
            line.shippingDate__c = null;
            line.manufacturingStart__c = null;
            line.billingDate__c = null;
            line.deliveryNumber = null;
            line.manufacturingEnd__c = null;
            line.deliveryDate__c = null;
            line.contractualDeliveryDate__c = null;
            line.estimatedDeliveryDate__c = null;
            line.cancellationReason__c = null;
            line.receivedDate__c = null;
            line.deliveryNumber__c = null;
            line.invoiceNumber__c = null;
            line.invoiceNumber__c = null;
            line.cancellationDate__c = null;
        }
        this.draftValuesTest = [];
    }
}