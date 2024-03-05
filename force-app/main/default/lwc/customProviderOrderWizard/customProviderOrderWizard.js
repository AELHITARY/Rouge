/* eslint-disable no-console */
import { LightningElement, api, track, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord  } from 'lightning/uiRecordApi';

// Apex class methods
import getProducts from '@salesforce/apex/LWC_CustomProviderOrderWizard.getProducts';
import getUnknownProduct from '@salesforce/apex/LWC_CustomProviderOrderWizard.getUnknownProduct';
import getProviderOrderRecordType from '@salesforce/apex/LWC_CustomProviderOrderWizard.getProviderOrderRecordType';
import getProviders from '@salesforce/apex/LWC_CustomProviderOrderWizard.getProviders';
import getSelectedProductProviders from '@salesforce/apex/LWC_CustomProviderOrderWizard.getSelectedProductProviders';
import createOrders from '@salesforce/apex/LWC_CustomProviderOrderWizard.createOrders';
import getAllProviders from '@salesforce/apex/LWC_CustomProviderOrderWizard.getAllProviders';
import getAllProvidersUnknown from '@salesforce/apex/LWC_CustomProviderOrderWizard.getAllProvidersUnknown';
import getNcpResponsability from '@salesforce/apex/LWC_CustomProviderOrderWizard.getNcpResponsability';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import TRANSMISSIONCHANNEL_FIELD from '@salesforce/schema/Order.transmissionChannel__c';
import RESPONSABILITY_FIELD from '@salesforce/schema/Case.responsability__c';
import ORDERTYPE_FIELD from '@salesforce/schema/Order.Type';
import ORDER_OBJECT from '@salesforce/schema/Order';
import CASE_OBJECT from '@salesforce/schema/Case';

const ORDER_FIELDS = ['Order.ShipToContactId', 'Order.Status', 'Order.EffectiveDate', 'Order.Type',
                            'Order.financingMethod__c', 'Order.source__c'];

const CASE_FIELDS = ['Case.customerOrder__c', 'Case.AssetId', 'Case.requiredOrder__c'];

const PATH_STEPS = [
    { label: 'Commande', value: 'step-1', display: true },
    { label: 'Fournisseur par produit', value: 'step-2', display: true },
    { label: 'Résumé des commandes fournisseur', value: 'step-3', display: true }
];

export default class CustomProviderOrderWizard extends NavigationMixin(LightningElement) {
    // Current object api name
    @api objectApiName;
    // Current record's id
    @api recordId;
    // Current record
    @track record;
    // Current object metadata info
    @track objectInfo;  
    @track fieldArray = [];

    // Wizard Status
    @track activeWizard = false;
    @track currentStep = "step-1";
    @track steps = PATH_STEPS;
    @track showStep1Form = false;
    @track showResposibilityField = true;
    @track showStep2Form = false;
    @track showStep3Form = false;
    @track showNextButton = true;
    @track showPreviousButton = false;
    @track showSubmitButton = false;
    @track showTableUnknown = false;
    @track init = true;

    // Datatable
    @track productsData = [];
    @track unknownProductData = [];
    @track providersData = [];
    @track productProvidersData = [];
    @track allProvidersData = [];
    @track allProvidersUnknownData = [];

    // Event data
    @track showLoadingSpinner = false;
    @track error;
    @track copyIdProvider;
    @track isAlreadyCopied = false;
    @track copyLabelProvider;
    @track transmissionDate;
    @track transmissionReason;
    @track orderType;
    responsability;
    @track confirmationDate;
    @track refProvider;
    @track productCostPrevAll;
    @track unknownLineCount = 0;
    @track unknownLineCountTemp = 0;
    @track deliveryDatePrevAll;
    @track transmissionChannelPicklistValues;
    @track unknownProductId;
    @track orderId;
    providerOrderRT = '';

    // Non reactive variables
    activeSaisieSections = ['orderGlobalData', 'lineGlobalData', 'lineUnknownProductData'];
    productRecords = [];
    selectedProductRecords = [];
    selectedProviders = [];
    selectedProvidersWithUnknown = [];
    refreshTable;
    isAfterSalesService = false;
    
    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();

        // Init body
        this.showLoadingSpinner = true;
        this.activeWizard = false;
        this.updateWizardBody();
        // Init values
        this.transmissionDate = new Date().toISOString();
        this.transmissionReason = 'Extranet';
        this.isAfterSalesService = false;
    }

    connectedCallback(){
        console.log('objectApiName : '+this.objectApiName);
        console.log('RecordId : '+this.recordId);
        if(this.objectApiName === 'Order') {
            this.fieldArray = ORDER_FIELDS;
        } else if(this.objectApiName === 'Case') {
            this.fieldArray = CASE_FIELDS;
        }
    }

    /* ========== WIRED METHODS ========== */

    /**
     * Retrieving the data of the record (Order or Case).
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
             this.testdata = this.record.fields.Type.value;
             // Define value for constraints
             if(this.objectApiName === 'Order') {                                
                if(this.record.fields.Type.value === 'Commande SAV') {
                    this.isAfterSalesService = true;
                }
                this.orderType = 'Commande marchandise';
                this.orderId = this.recordId;
                if(this.orderType === 'Commande marchandise' || this.orderType === 'Commande de stock'){                    
                    this.showResposibilityField = false;
                    this.init = false;
                }
             } else if(this.objectApiName === 'Case') {
                this.isAfterSalesService = true;
                this.getNcpResponsability();                
                if(this.record.fields.requiredOrder__c.value == 'Recommande') {
                    this.orderType = 'Recommande marchandise'; 
                } else if(this.record.fields.requiredOrder__c.value == 'Commande') {
                    this.orderType = 'Commande marchandise';
                } else {
                    
                }
                this.orderId = this.record.fields.customerOrder__c.value;                
                
             } 
         }
     }

    /**
     * Retrieving the object information of order.
     * @param {string} objectApiName - API Name of the object.
     */
     @wire(getObjectInfo,  { objectApiName: ORDER_OBJECT })
     orderObjectInfo;

     /**
     * Retrieving the object information of case.
     * @param {string} objectApiName - API Name of the object.
     */
      @wire(getObjectInfo,  { objectApiName: CASE_OBJECT })
      caseObjectInfo;

    /**
     * Retrieving the products using wire service
     * @param {string} recordId - Id of the order.
     */
    @wire(getProducts, { recordId: '$recordId'})
    products(result) {
        this.refreshTable = result;
        if (result.data) {
            // Init the array of products
            this.selectedProductRecords = [];   
            this.productRecords = [];
            if(result.data.length !== 0 || this.objectApiName === 'Case') {
                this.productsData = result.data;
                // Init product 
                for (const line of result.data) {
                    this.productRecords.push(line.Id);
                    this.selectedProductRecords.push(line.Id);
                }
                // Active the wizard
                this.activeWizard = true;
                // Get other informations
                this.getProvidersByProduct();
                this.getAllProviders();
                this.getAllProvidersUnknown();
            } else {
                if (this.isAfterSalesService) {
                    this.activeWizard = true;
                }else{
                    this.activeWizard = false;
                }                
                this.showLoadingSpinner = false;
            }
            this.error = undefined;
        } else if (result.error) {
            this.processErrorMessage(result.error);
            this.productsData = undefined;
        }
    }

    /**
     * Retrieving the unknown product using wire service
     */
     @wire(getUnknownProduct, { recordId: '$recordId'})
     unknownProductMethod(result) {
         this.refreshTable = result;
         if (result.data) {
             // Init Id
             this.unknownProductId = result.data;
             this.error = undefined;
         } else if (result.error) {
             this.processErrorMessage(result.error);
             this.productsData = undefined;
         }
     }

     /**
     * Retrieving the unknown product using wire service
     */
      @wire(getProviderOrderRecordType, { recordId: '$recordId'})
      getProviderOrderRecordTypeMethod(result) {
        if (result) {
            // Init Id
            this.providerOrderRT = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.processErrorMessage(result.error);
            this.productsData = undefined;
        }
      }


    /**
     * Retrieving the picklist values of "Transmission Channel".
     * @param {string} recordTypeId - Id of the record type of the Id.
     * @param {string} fieldApiName - API Name of the field.
    */
     @wire(getPicklistValues, { recordTypeId: '$orderObjectInfo.data.defaultRecordTypeId', fieldApiName: TRANSMISSIONCHANNEL_FIELD })
     setTransmissionChannelPicklist({error, data}) {
        if (data) {
            this.transmissionChannelPicklistValues = [{label:'-- Sélectionnez une valeur --', value:''}, ...data.values];
        } else if (error) {
            console.log(error);
        }
    }
    /**
     * Retrieving the picklist values of "Responsibility".
     * @param {string} recordTypeId - Id of the record type of the Id.
     * @param {string} fieldApiName - API Name of the field.
    */
    @wire(getPicklistValues, { recordTypeId: '$caseObjectInfo.data.defaultRecordTypeId', fieldApiName: RESPONSABILITY_FIELD })
    setResponsabilityPicklist({error, data}) {
       if (data) {
           this.responsabilityPicklistValues = [{label:'-- Sélectionnez une valeur --', value:''}, ...data.values];
       } else if (error) {
           console.log(error);
       }
   }

    /**
     * Retrieving the picklist values of "Order Type".
     * @param {string} recordTypeId - Id of the record type of the Id.
     * @param {string} fieldApiName - API Name of the field.
    */
    @wire(getPicklistValues, { recordTypeId: '$providerOrderRT', fieldApiName: ORDERTYPE_FIELD })
    setOrderTypePicklist({error, data}) {
        if (data) {
            this.orderTypePicklistValues = [{label:'-- Sélectionnez une valeur --', value:''}, ...data.values];
        } else if (error) {
            console.log(error);
        }
    }

    /* ========== EVENT METHODS ========== */
    
    /**
     * Display the next step of the wizard.
     * Executed when the user clicks on the "Suivant" button of the wizard.
     */
    handleNext() {
        this.resetErrorMessage();
        if(this.currentStep === 'step-2') {
            this.getSelectedProviders();
        }
        this.getProductProvidersDetails();
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
        
        this.selectedProviders = [];
        this.selectedProvidersWithUnknown = [];
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
     * Submit the form.
     * Executed when the user clicks on the "Confirmation" button of the wizard.
     */
    handleCreateOrder() {
        this.resetErrorMessage();
        this.showLoadingSpinner = true;
        // Check errors, continue if no errors
        if(this.checkForErrors()) {
            this.createOrders();
        }
    }

    /**
     * Set the value of the providers picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
    handleChangeProviderValue(event) {
        for(const line of this.providersData) {
            let prodivderId;
            let providerName;
            let provId;
            if(line.assetId === event.target.name) {
                for(const prov of line.providers) {
                    if(prov.value === event.detail.value) {
                        prodivderId = prov.value;
                        providerName = prov.label;
                        provId = prov.provId;
                    } 
                } 
            line.supId = prodivderId;
            line.provId = provId;
            line.supName = providerName;
            }
        }
    }

    /**
     * Set the value of the providers picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
    handleChangeCostValue(event) {
        for(const line of this.providersData) {
            if(line.assetId === event.target.name) {
                line.productCostPrev = event.detail.value;
            }
        }
    }

    /**
     * Set the value of the providers picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
    handleChangeDateValue(event) {
        for(const line of this.providersData) {
            if(line.assetId === event.target.name) {
                line.deliveryDatePrev = event.detail.value;
            }
        }
    }

    /**
     * Set the value of the "Line Number" in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangelineNumber(event) {
        for(const line of this.providersData) {
            if(line.assetId === event.target.name) {
                line.lineNumber = event.detail.value;
            }
        }
    }

    /**
     * Set the value of the "Provider Reference" in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeProviderReferenceOrder(event) {
        for(const line of this.providersData) {
            if(line.assetId === event.target.name) {
                line.providerReferenceOrder = event.detail.value;
            }
        }
    }

    /**
     * Set the value of the "Description" in the datatable of Unknown Product
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeDescriptionUnknownValue(event) {
        for(const line of this.unknownProductData) {
            if(line.id === event.target.name) {
                line.description = event.detail.value;
            }
        }
    }

    /**
     * Set the value of the "Couts prévisionels" in the datatable of Unknown Product
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeCostUnknownValue(event) {
        for(const line of this.unknownProductData) {
            if(line.id === event.target.name) {
                line.productCostPrev = event.detail.value;
            }
        }
    }

    /**
     * Set the value of the "Delivery Date" in the datatable of Unknown Product
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeDateUnknownValue(event) {
        for(const line of this.unknownProductData) {
            if(line.id === event.target.name) {
                line.deliveryDatePrev = event.detail.value;
            }
        }
    }

    /**
     * Set the value of the "Provider" in the datatable of Unknown Product
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeProviderUnknownValue(event) {
        for(const line of this.unknownProductData) {
            let prodivderId;
            let providerName;
            let provId;
            if(line.id === event.target.name) {
                for(const prov of this.allProvidersUnknownData) {
                    if(prov.value === event.detail.value) {
                        prodivderId = prov.value;
                        providerName = prov.label;
                        provId = prov.provId;
                    } 
                } 
                line.supId = prodivderId;
                line.provId = provId;
                line.supName = providerName;
            }
        }
    }

    /**
     * Set the value of the "LineNumber" in the datatable of Unknown Product
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeLineUnknownNumber(event) {
        for(const line of this.unknownProductData) {
            if(line.id === event.target.name) {
                line.lineNumber = event.detail.value;
            }
        }
    }

    /**
     * Set the value of the "Quantity" in the datatable of Unknown Product
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeQuantityUnknownNumber(event) {
        for(const line of this.unknownProductData) {
            if(line.id === event.target.name) {
                line.quantity = event.detail.value;
            }
        }
    }

    /**
     * Set the value of the "Provider Reference" in the datatable of Unknown Product
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeUnknownProviderReferenceOrder(event) {
        for(const line of this.unknownProductData) {
            if(line.id === event.target.name) {
                line.providerReferenceOrder = event.detail.value;
            }
        }
    }

    /**
     * Set the value of the providers picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeCostValueAll(event) {
        this.productCostPrevAll = event.detail.value;
    }

    /**
     * Set the value of the providers picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeUnknownValue(event) {
        this.unknownLineCount = event.detail.value;
    }

    /**
     * Set the value of the providers picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
    handleChangeDateValueAll(event) {
        this.deliveryDatePrevAll = event.detail.value;
    }

    /**
     * Set the value of the provider for all product picklist
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
    handleChangeAllProviderValue(event) {
        this.copyIdProvider = event.detail.value;
        this.copyLabelProvider = event.detail.label;
    }

    /**
     * Set the value of the providers picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeOrderType(event) {
        this.orderType = event.detail.value;
        if(this.objectApiName === 'Order'){
            if(this.orderType === 'Commande marchandise' || this.orderType === 'Commande de stock') {
                this.showResposibilityField = false;
                this.init = false;
            }else{
                this.showResposibilityField = true;
            }
        }
    }

     /**
     * Set the value of the providers picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeResponsability(event) {
        this.responsability = event.detail.value;
    }

    /**
     * Set the value of the providers picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeTransmissionDate(event) {
        this.transmissionDate = event.detail.value;
    }

    /**
     * Set the value of the providers picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeTransmissionReason(event) {
        this.transmissionReason = event.detail.value;
    }

    /**
     * Set the value of the providers picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeConfirmationDate(event) {
        this.confirmationDate = event.detail.value;
    }

    /**
     * Set the value of the providers picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeRefProvider(event) {
        this.refProvider = event.detail.value;
    }

    /* ========== JS METHODS ========== */

    /**
     * Function executed when the user click on the Previous/Next button to update the form.
     */
    updateWizardBody(){  
        this.showStep1Form = false;
        if (this.init) {
            this.showResposibilityField = true; 
        }        
        this.showStep2Form = false;
        this.showStep3Form = false;
        this.showPreviousButton = true;
        this.showNextButton = true;
        this.showSubmitButton = false;
        switch (this.currentStep) {
            case 'step-1':
                this.showStep1Form = true;
                this.showPreviousButton = false;
                this.isAlreadyCopied = false
                break;
            case 'step-2':
                this.showStep2Form = true;
                if(!this.isAlreadyCopied) {
                    this.copyProviderValueOnLines();
                }
                this.showNextButton = true;
                if(this.unknownLineCount > 0) {
                    this.showTableUnknown = true;
                    if(this.unknownProductData === '' || this.unknownLineCountTemp !== this.unknownLineCount) {
                        this.createUnknown();
                    }
                } else {
                    this.showTableUnknown = false;
                }
                break;
            case 'step-3':
                this.showStep3Form = true;
                this.showNextButton = false;
                this.processSortOutProvidersList();
                this.showSubmitButton = true;
                break;
        }
    }

    /**
     * Create Unknow values
     */
    createUnknown() {
        this.unknownLineCountTemp = this.unknownLineCount;
        this.unknownProductData = [];
        for(let i=0; i<this.unknownLineCount; i++) {
            let prodivderId;
            let providerName;
            if(this.copyIdProvider !== undefined) {
                for(const prov of this.allProvidersUnknownData) {
                    if(prov.value === this.copyIdProvider) {
                        prodivderId = prov.value;
                        providerName = prov.label;
                    } 
                }    
            } else {
                prodivderId = undefined;
                providerName = undefined;
            }

            const unknownProduct = {  id : i,
                                    assetId : '',
                                    productId : this.unknownProductId,
                                    description : '',
                                    productCostPrev : null,
                                    deliveryDatePrev : this.deliveryDatePrevAll,
                                    supId : prodivderId,
                                    supName : providerName,
                                    lineNumber : null,
                                    quantity : 1,
                                    providerReferenceOrder : this.refProvider
                                };
            this.unknownProductData.push(unknownProduct);
        }
    }

    /**
     * Retrieving the providers using wire service
     */
    getProvidersByProduct() {
        try {
            this.showLoadingSpinner = true;
            // Init
            this.providersData = [];
            // Call APEX method to get providers by products
            if(this.selectedProductRecords) {
                if(this.objectApiName === 'Order') {
                    getProviders({ assetsId: this.productRecords, isAfterSalesService: this.isAfterSalesService})
                    .then(result => {
                        // If providers, we set the table
                        if (result.length !== 0) {
                            this.providersData = JSON.parse(JSON.stringify(result)); 
                        } 
                        for(const line of this.providersData) {
                            line.productCostPrev = null;
                            line.deliveryDatePrev = null;
                        }
                        this.showLoadingSpinner = false;
                    })
                    .catch(error => {
                        this.processErrorMessage(error);
                    });
                } else if(this.objectApiName === 'Case') {
                    getProviders({ assetsId: this.productRecords, isAfterSalesService: true})
                    .then(result => {
                        // If providers, we set the table
                        if (result.length !== 0) {
                            this.providersData = JSON.parse(JSON.stringify(result)); 
                        } 
                        for(const line of this.providersData) {
                            line.productCostPrev = null;
                            line.deliveryDatePrev = null;
                        }
                        this.showLoadingSpinner = false;
                    })
                    .catch(error => {
                        this.processErrorMessage(error);
                    });
                } 
                
            }
        } catch(error) {
            this.processErrorMessage(error.message);
        }
    }

    /**
     * Retrieving the list of providers using wire service
     */
    getAllProviders() {
        try {
            this.showLoadingSpinner = true;
            // Init
            this.allProvidersData = [];
            // Call APEX method to get providers by products
            if(this.selectedProductRecords) {
                getAllProviders({ assetsId: this.productRecords, objectApiName: this.objectApiName})
                .then(result => {
                    // If providers, we set the table
                    if (result.length !== 0) {
                        this.allProvidersData = JSON.parse(JSON.stringify(result)); 
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
     * Retrieving the list of providers for unknown product using wire service
     */
    getAllProvidersUnknown() {
        try {
            this.showLoadingSpinner = true;
            // Init
            this.allProvidersUnknownData = [];
            // Call APEX method to get providers by products
            if(this.selectedProductRecords) {
                getAllProvidersUnknown()
                .then(result => {
                    // If providers, we set the table
                    if (result.length !== 0) {
                        this.allProvidersUnknownData = JSON.parse(JSON.stringify(result)); 
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
     * Function to get providers selected by the user.
     */
    getSelectedProviders() {
        try {
            this.selectedProviders = [];
            this.selectedProvidersWithUnknown = [];
            // Get the provider Id and values
            this.selectedProviders = Array.from(
                this.template.querySelectorAll('lightning-combobox')
            )
            .filter(element => (element.value !== undefined 
                                && element.value !== "" 
                                && element.dataset.productprovidersAssetid !== undefined)) // Filter to get only if provider is defined
            .map(element => { // Create a map of the provider
                return {
                    id: element.dataset.productprovidersAssetid,
                    name: element.dataset.productprovidersAssetname, 
                    value: element.value,
                    cout: element.dataset.productprovidersProductcostprev,
                    dateL: element.dataset.productprovidersDeliverydateprev,
                    lineNumber: element.dataset.productprovidersLinenumber,
                    providerReferenceOrder: element.dataset.productprovidersProviderreferenceorder,
                    provId: element.dataset.productprovidersProvid,
                };
            });
            this.selectedProvidersWithUnknown = Array.from(
                this.template.querySelectorAll('lightning-combobox')
            )
            .filter(element => (element.value !== undefined 
                                && element.value !== "" 
                                && element.dataset.unknownproductId !== undefined)) // Filter to get only if provider is defined
            .map(element => { // Create a map of the provider
                return {
                    name: element.dataset.productprovidersAssetname, 
                    value: element.value,
                    cout: element.dataset.productprovidersProductcostprev,
                    dateL: element.dataset.productprovidersDeliverydateprev,
                    lineNumber: element.dataset.productprovidersLinenumber,
                    providerReferenceOrder: element.dataset.productprovidersProviderreferenceorder,
                    provId: element.dataset.productprovidersProvid,
                };
            });
        } catch(error) {
            this.processErrorMessage(error.message);
        }
    }

    /**
     * Retrieving the providers for a product
     */
    getProductProvidersDetails() {
        try {
            this.showLoadingSpinner = true;
            // Init
            this.productProvidersData = [];
            // Call APEX method to get providers by products
            if(this.selectedProviders) {
                getSelectedProductProviders({ selectedSupList: this.selectedProviders, isAfterSalesService: this.isAfterSalesService})
                .then(result => {
                    // If providers, we set the table
                    if (result.length !== 0) {
                        this.productProvidersData = JSON.parse(JSON.stringify(result));  
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
     * Copy the provider for the product that can use this provider.
     */
    copyProviderValueOnLines() {
        this.isAlreadyCopied = true;
        const tab = Array.from(
            this.template.querySelectorAll('lightning-combobox')
        )
        for(const line of tab) {
            for(const line1 of line.options) {
                if(line1.value === this.copyIdProvider) {
                    line.value = this.copyIdProvider;
                }
            }
        }
        // Copy global values for each line where the provider of the product exists
        for(const line2 of this.providersData) {
            // Check if provider exists for this line and copy
            for(const prov of line2.providers) {
                if(prov.provId === this.copyIdProvider) {
                    line2.supId = prov.value;
                    line2.supName = prov.label;
                    line2.provId = prov.provId;
                    line2.productCostPrev = this.productCostPrevAll;
                    line2.deliveryDatePrev = this.deliveryDatePrevAll;
                    line2.providerReferenceOrder = this.refProvider;
                }
            }     
        }
    }

    /**
     * Execute the process to create the orders.
     */
    createOrders() {
        this.resetErrorMessage();        
        createOrders({selectedSupList: this.selectedProviders, recordId: this.recordId, transmissionDate: this.transmissionDate, 
                        transmissionReason: this.transmissionReason, orderType: this.orderType, confirmationDate: this.confirmationDate, 
                        unknownProducts: this.unknownProductData, isAfterSalesService: this.isAfterSalesService, objectApiName: this.objectApiName, responsability: this.responsability})
        .then(result => {
            // Clear the user enter values
            this.currentStep = 'step-1';
            this.updateWizardBody();
            // Show success messsage
            this.showNotification('Commandes créées', "Les commandes fournisseurs ont été créées avec succès", 'success');
            for(const res of result) {
                this.viewRecord(res);
            }
            // Close the quick action
            this.closeQuickAction();
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

    /**
     * Function to check all errors before each next step and before the creating of the Order.
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
            if(this.showResposibilityField && (this.responsability == null || this.responsability == '')) {  
                this.processErrorMessage("Vous devez saisir la responsabilité", false);
                result = false;                 
            }

            if(this.transmissionDate != null && this.transmissionReason === '') {
                result = false;
                this.processErrorMessage("Le moyen de transmission ne peut pas être vide si la date de transmission est remplie");
            }

            if(this.transmissionDate == null && this.transmissionReason !== '') {
                result = false;
                this.processErrorMessage("Le moyen de transmission doit être vide si la date de transmission n'est pas remplie");
            }
        }
        
        // check if on step 2 (provider for products)
        if(this.currentStep === 'step-2') {
            if (this.selectedProviders.length === 0 && this.selectedProvidersWithUnknown.length === 0) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner un fournisseur au minimum pour un produit", false);
            } 
            for(const selectedProvider of this.selectedProviders) {
                if(selectedProvider.providerReferenceOrder !== '' && selectedProvider.providerReferenceOrder != null && (selectedProvider.lineNumber === '' || selectedProvider.lineNumber == null)) {
                    result = false;
                    this.processErrorMessage("Vous devez remplir le N° de ligne si la référence fournisseur est renseignée", false);
                }
                if(selectedProvider.lineNumber !== '' && selectedProvider.lineNumber != null && (selectedProvider.providerReferenceOrder === '' || selectedProvider.providerReferenceOrder == null)) {
                    result = false;
                    this.processErrorMessage("Vous devez remplir la référence fournisseur si le N° de ligne est renseigné", false);
                }
                for(const selectedProvider2 of this.selectedProviders) {
                    if(selectedProvider.value != null && selectedProvider.value === selectedProvider2.value && selectedProvider.providerReferenceOrder !== selectedProvider2.providerReferenceOrder) {
                        result = false;
                        this.processErrorMessage("La référence fournisseur doit être identique pour chaque ligne ayant le même fournisseur", false);
                    }
                }
                for(const unknownProduct of this.unknownProductData) {
                    if(selectedProvider.provId != null && selectedProvider.provId === unknownProduct.supId && selectedProvider.providerReferenceOrder !== unknownProduct.providerReferenceOrder) {
                        result = false;
                        this.processErrorMessage("La référence fournisseur doit être identique pour chaque ligne ayant le même fournisseur", false);
                    }
                }
            }

            if(this.unknownLineCount > 0) {
                for(const unknownProduct of this.unknownProductData) {
                    if(unknownProduct.description === '' || unknownProduct.description == null) {
                        result = false;
                        this.processErrorMessage("Vous devez remplir le champ description de chaque produit inconnu", false);
                    }
                    if(!unknownProduct.quantity || unknownProduct.quantity < 0) {
                        result = false;
                        this.processErrorMessage("Vous devez définir une quantité pour chaque produit inconnu", false);
                    }
                    if(unknownProduct.providerReferenceOrder !== '' && unknownProduct.providerReferenceOrder != null && (unknownProduct.lineNumber === '' || unknownProduct.lineNumber == null)) {
                        result = false;
                        this.processErrorMessage("Vous devez remplir le N° de ligne si la référence fournisseur est renseignée", false);
                    }
                    if(unknownProduct.lineNumber !== '' && unknownProduct.lineNumber != null && (unknownProduct.providerReferenceOrder === '' || unknownProduct.providerReferenceOrder == null)) {
                        result = false;
                        this.processErrorMessage("Vous devez remplir la référence fournisseur si le N° de ligne est renseigné", false);
                    }
                    for(const unknownProduct2 of this.unknownProductData) {
                        if(unknownProduct.supId != null && unknownProduct.supId === unknownProduct2.supId && unknownProduct.providerReferenceOrder !== unknownProduct2.providerReferenceOrder) {
                            result = false;
                            this.processErrorMessage("La référence fournisseur doit être identique pour chaque ligne ayant le même fournisseur", false);
                        }
                    }
                }
            }
        }

        return result;
    }

    /**
     * SortOut Provider List in the last screen
     */
    processSortOutProvidersList() {
        this.productProvidersData.sort(function(a, b){
            const nameA=a.supName.toLowerCase();
            const nameB=b.supName.toLowerCase();
            if (nameA < nameB) {//sort string ascending
                return -1;
            } 
            if (nameA > nameB) {
                return 1;
            }
            return 0; //default return value (no sorting)
        })
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
    getNcpResponsability(){        
        try{
            getNcpResponsability({recordId: this.recordId, objectApiName: this.objectApiName}).
            then(result => {
                this.responsability= result;
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        }
        catch(error) {
            this.processErrorMessage(error.message);
        }
    }
}