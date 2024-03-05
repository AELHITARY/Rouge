/* eslint-disable no-console */

import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

// Apex class methods
import hasOrderItemRepriseGC from '@salesforce/apex/LWC_CustomProviderOrderLegacyWizard.hasOrderItemRepriseGC';
import getCustomerOrder from '@salesforce/apex/LWC_CustomProviderOrderLegacyWizard.getCustomerOrder';
import getAssets from '@salesforce/apex/LWC_CustomProviderOrderLegacyWizard.getAssets';
import getAssetsByDefault from '@salesforce/apex/LWC_CustomProviderOrderLegacyWizard.getAssetsByDefault';
import getOrderLines from '@salesforce/apex/LWC_CustomProviderOrderLegacyWizard.getOrderLines';
import createOrderItems from '@salesforce/apex/LWC_CustomProviderOrderLegacyWizard.createOrderItems';
import updateDatatableOrderItems from '@salesforce/apex/LWC_CustomProviderOrderLegacyWizard.updateDatatableOrderItems';
import getUnknownProduct from '@salesforce/apex/LWC_CustomProviderOrderLegacyWizard.getUnknownProduct';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

//Record fields
const ORDER_FIELDS = ['Order.Contract.ContractNumber', 'Order.Account.Name', 'Order.provider__c','Order.provider__r.Name', 'Order.providerReference__c',
                        'Order.confirmationDate__c', 'Order.estimatedDeliveryDate__c', 'Order.parentOrder__c', 'Order.orderItemCount__c', 'Order.totalCost__c',
                        'Order.EffectiveDate', 'Order.estimatedTotalCost__c', 'Order.deliveryDate__c', 'Order.billingDate__c', 'Order.provider__r.KparKReference__c'];

// Objects colums for datatables
const ASSET_COLUMNS = [
    { label: "Produit", fieldName: 'Name'},
    { label: "Quantité", fieldName: 'Quantity'},
    { label: "Dimensions", fieldName: 'dimensions__c'}
];

const ORDERITEM_COLUMNS = [
    //{ label: " ", fieldName: 'orderItemNumber__c', initialWidth: 160},
    { label: "Produit", fieldName: 'assetName__c', initialWidth: 160},
    { label: "Quantité", fieldName: 'Quantity'},
    { label: "Dimensions", fieldName: 'invoiceNumber__c'},
    { label: "N° ligne frs", fieldName: 'providerLineNumber__c', initialWidth: 130,editable: true, type: 'number'},
    { label: "Date conf.", fieldName: 'confirmationDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130 , editable: true},
    { label: "Date livr. Prév", fieldName: 'estimatedDeliveryDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130 , editable: true},
    { label: "Coût prév", fieldName: 'estimatedProductCost__c', type: 'currency', initialWidth: 110 , editable: true},
    { label: "Date Livr", fieldName: 'deliveryDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130, editable: true },
    { label: "N° de BL", fieldName: 'deliveryNumber__c', initialWidth: 130, editable: true},
    { label: "N° de ligne BL", fieldName: 'deliveryLineNumber__c', initialWidth: 130, editable: true, type: 'number'}, /* Utilisation de champ inutile pour stocker provisoirement la ligne BL */
    { label: "Date fac", fieldName: 'billingDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130, editable: true },
    { label: "N° de facture", fieldName: 'billingNumber__c', initialWidth: 130, editable: true },
    { label: "Coût réel", fieldName: 'productCost__c', type: 'currency',initialWidth: 100 ,editable: true}
];

const ORDERITEM_COLUMNS_UNKNOWN = [
    //{ label: " ", fieldName: 'orderItemNumber__c', initialWidth: 160},
    //{ label: "Produit", fieldName: 'assetName__c', initialWidth: 160},
    //{ label: "Quantité", fieldName: 'Quantity'},
    //{ label: "Dimensions", fieldName: 'invoiceNumber__c'},
    { label: "Description du produit", fieldName: 'Description', editable: true, initialWidth: 260},
    { label: "N° ligne frs", fieldName: 'providerLineNumber__c', initialWidth: 130,editable: true, type: 'number'},
    { label: "Date conf.", fieldName: 'confirmationDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130 , editable: true},
    { label: "Date livr. Prév", fieldName: 'estimatedDeliveryDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130 , editable: true},
    { label: "Coût prév", fieldName: 'estimatedProductCost__c', type: 'currency', initialWidth: 110 , editable: true},
    { label: "Date Livr", fieldName: 'deliveryDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130, editable: true },
    { label: "N° de BL", fieldName: 'deliveryNumber__c', initialWidth: 130, editable: true},
    { label: "N° de ligne BL", fieldName: 'deliveryLineNumber__c', initialWidth: 130, editable: true, type: 'number'}, /* Utilisation de champ inutile pour stocker provisoirement la ligne BL */
    { label: "Date fac", fieldName: 'billingDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130, editable: true },
    { label: "N° de facture", fieldName: 'billingNumber__c', initialWidth: 130, editable: true },
    { label: "Coût réel", fieldName: 'productCost__c', type: 'currency',initialWidth: 100 ,editable: true}
];

// Colonnes des orderItems pour le résumé
const ORDERITEM_READONLY_COLUMNS = [
    { label: "Produit", fieldName: 'assetName__c', initialWidth: 160},
    { label: "Quantité", fieldName: 'Quantity'},
    { label: "Dimensions", fieldName: 'invoiceNumber__c'},
    { label: "N° ligne frs", fieldName: 'providerLineNumber__c', initialWidth: 130},
    { label: "Date conf.", fieldName: 'confirmationDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130},
    { label: "Date livr. Prév", fieldName: 'estimatedDeliveryDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130},
    { label: "Coût prév", fieldName: 'estimatedProductCost__c', type: 'currency', initialWidth: 110},
    { label: "Date Livr", fieldName: 'deliveryDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130},
    { label: "N° de BL", fieldName: 'deliveryNumber__c', initialWidth: 130},
    { label: "N° de ligne BL", fieldName: 'deliveryLineNumber__c', initialWidth: 130},
    { label: "Date fac", fieldName: 'billingDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130},
    { label: "N° de facture", fieldName: 'billingNumber__c', initialWidth: 130},
    { label: "Coût réel", fieldName: 'productCost__c', type: 'currency',initialWidth: 100}
];

// Colonnes des orderItems pour le résumé
const ORDERITEM_READONLY_COLUMNS_UNKNOWN = [
    //{ label: "Produit", fieldName: 'assetName__c', initialWidth: 160},
    //{ label: "Quantité", fieldName: 'Quantity'},
    //{ label: "Dimensions", fieldName: 'invoiceNumber__c'},
    { label: "Description du produit", fieldName: 'Description'},
    { label: "N° ligne frs", fieldName: 'providerLineNumber__c', initialWidth: 130},
    { label: "Date conf.", fieldName: 'confirmationDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130},
    { label: "Date livr. Prév", fieldName: 'estimatedDeliveryDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130},
    { label: "Coût prév", fieldName: 'estimatedProductCost__c', type: 'currency', initialWidth: 110},
    { label: "Date Livr", fieldName: 'deliveryDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130},
    { label: "N° de BL", fieldName: 'deliveryNumber__c', initialWidth: 130},
    { label: "N° de ligne BL", fieldName: 'deliveryLineNumber__c', initialWidth: 130},
    { label: "Date fac", fieldName: 'billingDate__c', type: 'date-local', typeAttributes:{ year:"numeric", month:"numeric", day:"numeric" }, initialWidth: 130},
    { label: "N° de facture", fieldName: 'billingNumber__c', initialWidth: 130},
    { label: "Coût réel", fieldName: 'productCost__c', type: 'currency',initialWidth: 100}
];

const PATH_STEPS = [
    { label: 'Commande', value: 'step-1', display: true },
    { label: 'Actifs', value: 'step-2', display: true },
    { label: 'Lignes de commande', value: 'step-3', display: true },
    { label: 'Résumé', value: 'step-4', display: true },
];

export default class CustomProviderOrderLegacyWizard extends LightningElement {
    // Current object api name
    //@api objectApiName;

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
    @track showStep3Form = false;
    @track showStep4Form = false;
    @track showSubmitButton = false;
    @track isPreviousState = false;
    @track reloadOrderItemData = false;
    @track showTableUnknown = false;
    @track unknownLineCount = 0;
    @track unknownLineCountTemp = 0;

    @track hasOrderItemRepriseGC = true;

    //Datatable
    @track assetsData = [];
    @track orderItemsData = [];
    @track selectedAssets = [];
    @track draftValues = [];
    @track draftValuesUnknown = [];
    @track unknownProductData = [];
    @track assetSelectedNumber = 0;
    @track unknownProductId;

    // Event data
    @track showLoadingSpinner = false;
    @track error;

    // non-reactive variables
    orderContractContractNumber;
    orderAccountName;
    orderProviderId;
    orderProviderName;
    orderProviderReference;
    orderConfirmationDate;
    orderEffectiveDate;
    orderEstimatedDeliveryDate;
    orderDeliveryDate;
    orderDeliveryNumber;
    orderBillingDate;
    orderBillingNumber;
    orderProviderKparKReference;
    orderParentOrder;
    orderItemCount;
    selectedAssetRecords = [];
    activeSummarySections = ['assetSummary', 'unknownSummary'];

    orderTotalCost;
    orderEstimatedTotalCost;
    orderLinesEstimatedTotalCost;
    orderLinesTotalCost;

    //Other
    @track assetColumns = ASSET_COLUMNS;
    @track orderItemColumns = ORDERITEM_COLUMNS;
    @track orderItemColumnsUnknown = ORDERITEM_COLUMNS_UNKNOWN;
    @track orderItemReadOnlyColumns = ORDERITEM_READONLY_COLUMNS;
    @track orderItemReadOnlyColumnsUnknown = ORDERITEM_READONLY_COLUMNS_UNKNOWN;

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
        this.assetsData = [];
        this.selectedAssetRecords = [];  
        this.orderItemsData = [];
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

            this.getHasOrderItemRepriseGC();
            if(this.hasOrderItemRepriseGC == false){
                this.activeWizard=false;
            }
            else{                
                if(this.record.fields) {
                    this.orderProviderId = this.record.fields.provider__c.value;
                    this.orderProviderReference = this.record.fields.providerReference__c.value;
                    if(this.record.fields.provider__c.value != null) {
                        this.orderProviderName = this.record.fields.provider__r.value.fields.Name.value; 
                        this.orderProviderKparKReference = this.record.fields.provider__r.value.fields.KparKReference__c;
                    }

                    this.orderConfirmationDate = this.record.fields.confirmationDate__c.value;
                    this.orderEffectiveDate = this.record.fields.EffectiveDate.value;
                    this.orderEstimatedDeliveryDate = this.record.fields.estimatedDeliveryDate__c.value;
                    this.orderEstimatedTotalCost = this.record.fields.estimatedTotalCost__c.value;
                    this.orderDeliveryDate = this.record.fields.deliveryDate__c.value;
                    this.orderBillingDate = this.record.fields.billingDate__c.value;
                    this.orderParentOrder = this.record.fields.parentOrder__c.value;

                    if(this.record.fields.orderItemCount__c.value==null) {
                        this.orderItemCount = 0;
                    } else {
                        this.orderItemCount = this.record.fields.orderItemCount__c.value;
                    }
                    this.orderTotalCost = this.record.fields.totalCost__c.value;
                    this.getCustomerOrder();
                }
            }
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
                if(this.isPreviousState == false) {
                    this.getCustomerOrder();
                }
                this.showStep1Form = true;
                this.showPreviousButton = false;
                break;
            case 'step-2':
			    this.getAssets();
                this.showStep2Form = true;
                break;
            case 'step-3':
                if(this.isPreviousState == false) {
                    this.getOrderLines();
                }
                //this.getOrderLinesCosts();
                this.showStep3Form = true;
                if(this.unknownLineCount > 0) {
                    this.showTableUnknown = true;
                    if(this.unknownProductData == '' || this.unknownLineCountTemp != this.unknownLineCount)
                        this.createUnknown();
                } else {
                    this.showTableUnknown = false;
                }
                break;
            case 'step-4':
                this.showStep4Form = true;
                this.showSubmitButton = true;
                this.showNextButton = false;
                break;
        }
    }

    /**
     * Create Unknow values
     */
     createUnknown() {
        this.unknownLineCountTemp = this.unknownLineCount;
        this.unknownProductData = [];
        let flagDifferenceEntreLesCouts=false;

        for(let i=0; i<this.unknownLineCount; i++) {
            //for(let unknownProduct of this.unknownProductData) {
            
            let prodivderId;
            let providerName;
            let unknownProduct
            if(this.copyIdProvider != undefined) {
                for(const prov of this.allProvidersUnknownData) {
                    if(prov.value == this.copyIdProvider) {
                        prodivderId = prov.value;
                        providerName = prov.label;
                    } 
                }    
            } else {
                prodivderId = undefined;
                providerName = undefined;
            }
            if(parseInt(this.selectedAssetRecords.length) > 0 && parseInt(this.selectedAssetRecords.length) != 1) {
                flagDifferenceEntreLesCouts = true;
                console.log('test : ' +flagDifferenceEntreLesCouts);
            }

            let iplus1 = parseInt(this.selectedAssetRecords.length)+1+i;
            
            let orderItemsCount;
            orderItemsCount = parseInt(this.selectedAssetRecords.length) + parseInt(this.unknownLineCount);

            let coutPrevParLine;    
            let sommeCoutPrevParLine;
            let estimatedProductCost;       

            let coutReelParLigne;      
            let productCostWithDiff;
            let sommeCoutReelParLigne;                               

            if(this.orderTotalCost!=null){
                coutReelParLigne = parseFloat(this.orderTotalCost/orderItemsCount).toFixed(2);
                sommeCoutReelParLigne = (coutReelParLigne*orderItemsCount);
                productCostWithDiff = (parseFloat(coutReelParLigne) + (parseFloat(this.orderTotalCost) - parseFloat(sommeCoutReelParLigne).toFixed(2)));
            } else{
                productCostWithDiff=null;
                coutReelParLigne = null;
            } 
            if(this.orderEstimatedTotalCost != null) {
                coutPrevParLine = parseFloat(this.orderEstimatedTotalCost/orderItemsCount).toFixed(2);
                sommeCoutPrevParLine = (coutPrevParLine*orderItemsCount);
                estimatedProductCost = (parseFloat(coutPrevParLine) + (parseFloat(this.orderEstimatedTotalCost) - parseFloat(sommeCoutPrevParLine).toFixed(2)));
            } else {
                estimatedProductCost = null; 
                coutPrevParLine = null;          
            }
            if(flagDifferenceEntreLesCouts == true) {
                console.log('TEST : ' + parseFloat(coutPrevParLine));
                console.log('TEST : ' + parseFloat(coutReelParLigne));
                unknownProduct = {  orderItemNumber__c : ''+iplus1,
                                    Quantity : 1,
                                    Description : '',
                                    providerLineNumber__c : '',
                                    confirmationDate__c : this.orderConfirmationDate,
                                    estimatedDeliveryDate__c : this.orderEstimatedDeliveryDate,
                                    estimatedProductCost__c : parseFloat(coutPrevParLine),
                                    deliveryDate__c : this.orderDeliveryDate,
                                    deliveryNumber__c : this.orderDeliveryNumber,
                                    deliveryLineNumber__c : '',
                                    billingDate__c : this.orderBillingDate,
                                    billingNumber__c : this.orderBillingNumber,
                                    productCost__c : parseFloat(coutReelParLigne)
                                };
            } else {
                unknownProduct = {  orderItemNumber__c : ''+iplus1,
                                    Quantity : 1,
                                    Description : '',
                                    providerLineNumber__c : '',
                                    confirmationDate__c : this.orderConfirmationDate,
                                    estimatedDeliveryDate__c : this.orderEstimatedDeliveryDate,
                                    estimatedProductCost__c : parseFloat(estimatedProductCost),
                                    deliveryDate__c : this.orderDeliveryDate,
                                    deliveryNumber__c : this.orderDeliveryNumber,
                                    deliveryLineNumber__c : '',
                                    billingDate__c : this.orderBillingDate,
                                    billingNumber__c : this.orderBillingNumber,
                                    productCost__c : parseFloat(productCostWithDiff)
                                };
                flagDifferenceEntreLesCouts = true;
            }
            this.unknownProductData.push(unknownProduct);
            //}
        }
        this.getOrderLinesCosts();
    }

    /**
     * Calculate sum informations in step 3.
     */
    getOrderLinesCosts(){
        let sumEstimatedCost=0.00;
        let sumTotalCost=0.00;
        if(this.orderItemsData != null && this.orderItemsData.length!=0){
            for(let line of this.orderItemsData){
                sumTotalCost+=line.productCost__c;
                sumEstimatedCost+=line.estimatedProductCost__c;
            }
        }
        if(this.unknownProductData != null && this.unknownProductData.length!=0) {
            for(let line of this.unknownProductData){
                if(line.productCost__c != null)
                    sumTotalCost+=parseFloat(line.productCost__c);
                if(line.estimatedProductCost__c != null)
                    sumEstimatedCost+=parseFloat(line.estimatedProductCost__c);
            }
        }
        // Update Estimated Cost
        if(this.isNullOrWhitespace(sumEstimatedCost)){
            this.orderLinesEstimatedTotalCost=null;
        } else{
            this.orderLinesEstimatedTotalCost=sumEstimatedCost;
        }
        // Update Total Cost
        if(this.isNullOrWhitespace(sumTotalCost)){
            this.orderLinesTotalCost=null;
        } else{
            this.orderLinesTotalCost=sumTotalCost;
        }
    }

    /*
     * Execute the process to update the Order Items on the datatable.
     * @param {object} draftValues - Values defined in the datatable for each order items.
     */
     updateDatatableOrderItems(draftValues) {
        this.showLoadingSpinner = true;
        // Call APEX action to update the OrderItems
        updateDatatableOrderItems({ 
            newValues: draftValues, orderItemsData : this.orderItemsData
        })
        .then(result => {
            if(result) {
                this.showNotification('Lignes de commandes modifiées', "Les lignes de commandes ont bien été modifiées.", 'success');
                this.orderItemsData = result;
                this.getOrderLinesCosts();
                this.draftValues = [];
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
     * Function to call "hasOrderItemRepriseGC" APEX method.
     */
    getHasOrderItemRepriseGC(){

        try {
            hasOrderItemRepriseGC({ recordId: this.recordId})
            .then(result => {
                if (result && result.length > 0) {  
                    this.hasOrderItemRepriseGC = true;   
                    // Alimentation des données de la ligne
                    this.orderBillingNumber = result[0].billingNumber__c;
                    this.orderDeliveryNumber = result[0].deliveryNumber__c;
                    this.error = undefined;
                } else{
                    this.hasOrderItemRepriseGC = false;
                    this.activeWizard=false;
                }
            })
            .catch(error => {
                this.processErrorMessage(error);
            });

        } catch(error) {
            this.processErrorMessage(error.message);
        }
    }

    /**
     * Function to call "getCustomerOrder" APEX method.
     */
    getCustomerOrder(){
        try {
            //this.showLoadingSpinner = true;
            // Call APEX method to get products
            getCustomerOrder({ customerOrderId: this.orderParentOrder})
            .then(result => {
                // If products, we set the table
                if (result.length == 1) {  
                    for (let line of result) {
                        this.orderContractContractNumber=line.legacyReference__c;
                        this.orderAccountName=line.billingName__c;
                    }
                    
                    this.error = undefined;
                }
                
            })
            .catch(error => {
                this.processErrorMessage(error);
            });

        } catch(error) {
            this.processErrorMessage(error.message);
        }
    }

    /**
     * Function to call "getAssets" APEX method.
     */
    getAssets() {
        try {
            // Call only if no assets
            if(this.assetsData.length == 0) {
                this.showLoadingSpinner = true;
                // Call APEX method to get assets
                getAssets({ customerOrderId: this.orderParentOrder, providerId : this.orderProviderId})
                .then(result => {
                    // If assets, we set the table
                    if (result.length !== 0) {
                        this.reloadOrderItemData = true; // Reload OrderItem Data  
                        this.assetsData = result;   
                        let assetsId = [];
                        for (let line of result) {
                            assetsId.push(line.Id);
                            /*
                            console.log("1@@@@ Product2Id :" + line.Product2Id);
                            console.log("1@@@@ location__c :" + line.location__c);
                            console.log("1@@@@ height__c :" + line.height__c);
                            console.log("1@@@@ width__c :" + line.width__c);
                            */
                        }
                        
                        getAssetsByDefault({ assetsId: assetsId, recordId : this.recordId, providerId : this.orderProviderId})
                        .then(result2 => {
                            // If result, we set the table
                            if (result2.length !== 0) {
                                let selectedIds = [];
                                for (let line of result2) {
                                    selectedIds.push(line);
                                }
                                this.selectedAssetRecords = selectedIds;
                                this.error = undefined;    
                            }                        
                            this.showLoadingSpinner = false;
                        })
                        .catch(error => {
                            this.processErrorMessage(error);
                        });  
                        this.error = undefined;
                    } else {
                        this.showLoadingSpinner = false;
                    }
                    
                })
                .catch(error => {
                    this.processErrorMessage(error);
                });
            }
        } catch(error) {
            this.processErrorMessage(error.message);
            this.assetsData = undefined;
        }
    }

    /**
     * Function to call "getOrderLines" APEX method.
     */
    getOrderLines(){
        try{
            // Call APEX only when needed
            if(this.reloadOrderItemData) {
                this.reloadOrderItemData = false;
                this.showLoadingSpinner = true;
                this.selectedAssets= [];
                for (let line of this.assetsData) {
                    if(this.selectedAssetRecords.includes(line.Id)){
                        this.selectedAssets.push(line);
                    }
                }
                // If this.orderTotalCost is empty then is null
                if(this.orderTotalCost == "") {
                    this.orderTotalCost = null;
                }
                if(this.orderEstimatedTotalCost == "") {
                    this.orderEstimatedTotalCost = null;
                }
                let orderItemsCount = 0;
                orderItemsCount = parseInt(this.selectedAssetRecords.length) + parseInt(this.unknownLineCount);
                // Call APEX
                getOrderLines({recordId : this.recordId, selectedAssets : this.selectedAssets, orderItemCount : orderItemsCount, 
                                orderTotalCost : this.orderTotalCost, orderEstimatedTotalCost : this.orderEstimatedTotalCost, 
                                orderBillingNumber : this.orderBillingNumber, orderDeliveryNumber : this.orderDeliveryNumber,
                                orderBillingDate : this.orderBillingDate, orderConfirmationDate : this.orderConfirmationDate, 
                                orderEstimatedDeliveryDate : this.orderEstimatedDeliveryDate, orderDeliveryDate : this.orderDeliveryDate}
                                ).
                then(result => {
                    // If OrderItems, we set the table
                    if (result.length !== 0) {
                        let orderItems = [];
                        for (let line of result) {
                            orderItems.push(line);
                        }
                        this.orderItemsData = orderItems;
                        this.assetSelectedNumber = this.orderItemsData.length;
                        this.getOrderLinesCosts();
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
            this.orderItemsData = undefined;
        }

    }

    /**
     * Function to call "createOrderItems" APEX method.
     */
    createOrderItems(){
        try{
            createOrderItems({newOrderItems: this.orderItemsData, selectedAssets: this.selectedAssets, orderId: this.recordId, 
                                providerReference: this.orderProviderReference, effectiveDate: this.orderEffectiveDate, unknownOrderItems: this.unknownProductData}).
            then(result => {
                if (result) {
                    this.showNotification('Modification de la commande fournisseur', "La modification a été effectuée avec succès", 'success');
                    // Close the quick action
                    this.closeQuickAction();
                }
                else{
                    this.showNotification('Erreur', "Echec de la modification de la commande founisseur.", 'error');
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
            // Check special rules
            /*else if((this.isNullOrWhitespace(this.orderDeliveryDate) || this.isNullOrWhitespace(this.orderDeliveryNumber)) && 
                    (!this.isNullOrWhitespace(this.orderDeliveryDate) || !this.isNullOrWhitespace(this.orderDeliveryNumber) )) {
                this.processErrorMessage("Les champs « Date de livraison » et « N° de BL » sont liés : si l'un est saisi, les deux autres doivent l'être aussi", false);
                result = false;
            }*/
            else if((this.isNullOrWhitespace(this.orderBillingDate) /*|| this.orderTotalCost == null*/ || this.isNullOrWhitespace(this.orderBillingNumber)) && 
                    (!this.isNullOrWhitespace(this.orderBillingDate) /*|| this.orderTotalCost != null*/ || !this.isNullOrWhitespace(this.orderBillingNumber))) {
                this.processErrorMessage("Les champs « Date de facture » et « N° de facture » sont liés : si l'un est renseigné, l'autre doit l'être aussi", false);
                result = false;
            }
        }

        // check if on step 2 (asset)
        if(this.currentStep === 'step-2') {
            //console.log('STEP-2 orderLinesEstimatedTotalCost: '+typeof this.orderLinesEstimatedTotalCost);
            if (this.selectedAssetRecords.length < 1 && (this.unknownLineCount == 0 || this.isNullOrWhitespace(this.unknownLineCount))) {
                result = false;
                this.processErrorMessage("Le nombre d'actifs sélectionnés est incorrect !", false);
            } 
		}

        // check if on step 3 (order item)
        if(this.currentStep === 'step-3') {
            if (this.orderItemsData.length === 0 && (this.unknownLineCount == 0 || this.isNullOrWhitespace(this.unknownLineCount))) {
                result = false;
                this.processErrorMessage("Il n'y a aucune ligne de commande fournisseur associée à la commande !", false);
            } else {
                if(this.selectedAssetRecords.length > 0) {
                    // Pour chaque lignes
                    for(let line of this.orderItemsData){
                        // Règles de gestion spécifique par lignes
                        if(this.isNullOrWhitespace(line.providerLineNumber__c)){
                            this.processErrorMessage("Pour chaque ligne, un numéro de ligne de commande fournisseur doit-être renseigné !", false);
                            result = false;
                        }
                        /*
                        else if(this.isNullOrWhitespace(line.estimatedDeliveryDate__c)){
                            this.processErrorMessage("Pour chaque ligne, une date de livraison prévisionnelle doit-être renseignée !", false);
                            result = false;
                        }
                        */
                    /*
                        else if(this.isNullOrWhitespace(line.estimatedProductCost__c)){
                            this.processErrorMessage("Pour chaque ligne, un coût prévisionnel doit-être renseigné !", false);
                            result = false;
                        }
                        */
                        else if((this.isNullOrWhitespace(line.confirmationDate__c) || this.isNullOrWhitespace(line.estimatedDeliveryDate__c) /*|| line.estimatedProductCost__c == null*/) && 
                                (!this.isNullOrWhitespace(line.confirmationDate__c) || !this.isNullOrWhitespace(line.estimatedDeliveryDate__c) /*|| line.estimatedProductCost__c != null*/)) {
                            this.processErrorMessage("Les champs « Date conf. » et « Date livr. Prév » sont liés : si l'un est saisi, l'autre doit l'être aussi", false);
                            result = false;
                        }
                        else if((/*this.isNullOrWhitespace(line.deliveryDate__c) ||*/ this.isNullOrWhitespace(line.deliveryNumber__c) || this.isNullOrWhitespace(line.deliveryLineNumber__c)) && 
                                (/*!this.isNullOrWhitespace(line.deliveryDate__c) ||*/ !this.isNullOrWhitespace(line.deliveryNumber__c) || !this.isNullOrWhitespace(line.deliveryLineNumber__c))) {
                            this.processErrorMessage("Les champs « N° de BL » et « N° ligne BL » sont liés : si l'un est saisi, l'autre doit l'être aussi", false);
                            result = false;
                        }
                        else if((this.isNullOrWhitespace(line.billingDate__c) /*|| line.productCost__c == null*/ || this.isNullOrWhitespace(line.billingNumber__c)) && 
                                (!this.isNullOrWhitespace(line.billingDate__c) /*|| line.productCost__c != null*/ || !this.isNullOrWhitespace(line.billingNumber__c))) {
                            this.processErrorMessage("Les champs « Date fac » et « N° de facture » sont liés : si l'un est renseigné, l'autre doit l'être aussi", false);
                            result = false;
                        }                   
                    }
                }
                // Règles de gestion total
                //console.log('STEP-3 : '+typeof this.orderTotalCost);
                if(!this.isNullOrWhitespace(this.orderLinesTotalCost) && !this.isNullOrWhitespace(this.orderTotalCost) && this.orderTotalCost.toFixed(2) != this.orderLinesTotalCost.toFixed(2)){
                    this.processErrorMessage("Le total des coûts réels saisis sur les différentes lignes est différent du coût global saisi sur l’écran 1", false);
                    result = false;
                }
                else if(!this.isNullOrWhitespace(this.orderLinesEstimatedTotalCost) && !this.isNullOrWhitespace(this.orderEstimatedTotalCost) && this.orderEstimatedTotalCost.toFixed(2) != this.orderLinesEstimatedTotalCost.toFixed(2)){
                    this.processErrorMessage("Le total des coûts prévisionnels saisis sur les différentes lignes est différent du coût global saisi sur l’écran 1", false);
                    result = false;
                } 
            }

            if(this.unknownLineCount > 0) {
                for(let unknownProduct of this.unknownProductData) {
                    if(unknownProduct.Description == '' || unknownProduct.Description == null) {
                        result = false;
                        this.processErrorMessage("Vous devez remplir le champ description de chaque produit inconnu", false);
                    }
                    if(this.isNullOrWhitespace(unknownProduct.providerLineNumber__c)){
                        this.processErrorMessage("Pour chaque ligne, un numéro de ligne de commande fournisseur doit-être renseigné !", false);
                        result = false;
                    }
                    else if((this.isNullOrWhitespace(unknownProduct.confirmationDate__c) || this.isNullOrWhitespace(unknownProduct.estimatedDeliveryDate__c) ) && 
                            (!this.isNullOrWhitespace(unknownProduct.confirmationDate__c) || !this.isNullOrWhitespace(unknownProduct.estimatedDeliveryDate__c) )) {
                        this.processErrorMessage("Les champs « Date conf. » et « Date livr. Prév » sont liés : si l'un est saisi, l'autre doit l'être aussi", false);
                        result = false;
                    }
                    else if((this.isNullOrWhitespace(unknownProduct.deliveryNumber__c) || this.isNullOrWhitespace(unknownProduct.deliveryLineNumber__c)) && 
                            ( !this.isNullOrWhitespace(unknownProduct.deliveryNumber__c) || !this.isNullOrWhitespace(unknownProduct.deliveryLineNumber__c))) {
                        this.processErrorMessage("Les champs « N° de BL » et « N° ligne BL » sont liés : si l'un est saisi, l'autre doit l'être aussi", false);
                        result = false;
                    }
                    else if((this.isNullOrWhitespace(unknownProduct.billingDate__c) || this.isNullOrWhitespace(unknownProduct.billingNumber__c)) && 
                            (!this.isNullOrWhitespace(unknownProduct.billingDate__c) || !this.isNullOrWhitespace(unknownProduct.billingNumber__c))) {
                        this.processErrorMessage("Les champs « Date fac » et « N° de facture » sont liés : si l'un est renseigné, l'autre doit l'être aussi", false);
                        result = false;
                    }
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
     * Function to reset values.
     */
    resetValues() {
        this.orderConfirmationDate = null;
        this.orderEstimatedDeliveryDate = null;
        this.orderEstimatedTotalCost = null;
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
                let currIndex = this.steps.findIndex(x => x.value === currentStage); // Get the index in the array of the step
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
     * Get the products selected in the datatable
     * @param {object} event - Event object of the "onrowselection" of the datatable.
     */
    handleSelectedAssetsChange(event) {
        this.resetErrorMessage();
        // Get row selected
        const selectedRows = event.detail.selectedRows;
        // Init the array of assets
        this.selectedAssetRecords = [];        
        // Add asset selected in the array
        for (let i = 0; i < selectedRows.length; i++){            
            this.selectedAssetRecords.push(selectedRows[i].Id);
        }        
        this.reloadOrderItemData = true; // Reload OrderItem Data
    }
    /**
     * Create the orderItems when the users click on "Valider"
     */
    handleCreateOrderItems(){
        this.resetErrorMessage();
        this.showLoadingSpinner = true;
        // Check errors, continue if no errors
        if(this.checkForErrors()) {
            this.createOrderItems();
            //this.currentStep = 'step-1';
            //this.updateWizardBody();
        }
    }

    /**
     * Get the values defined in the datatable for each order items
     * @param {object} event - Event object of the "onsave" of the datatable.
     */
    handleOrderItemsSave(event) {
        this.resetErrorMessage();
        // Call APEX action to update the WorkOrder
        //console.log(event.detail.draftValues);
        this.updateDatatableOrderItems(event.detail.draftValues);
    }

    /**
     * Get the values defined in the datatable for each order items
     * @param {object} event - Event object of the "onsave" of the datatable.
     */
     handleOrderItemsSaveUnknown(event) {
        this.resetErrorMessage();
        // Call APEX action to update the WorkOrder
        //console.log(event.detail.draftValues);
        updateDatatableOrderItems({ 
            newValues: event.detail.draftValues, orderItemsData : this.unknownProductData
        })
        .then(result => {
            if(result) {
                this.showNotification('Lignes de commandes modifiées', "Les lignes de commandes ont bien été modifiées.", 'success');
                this.unknownProductData = result;
                this.getOrderLinesCosts();
                this.draftValuesUnknown = [];
                console.log(this.unknownProductData);
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
     * Handle a change on the "Provider reference" field for the "Commande" step
     * @param {object} event - Object of the Event.
     */	
     handleProviderReferenceChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.orderProviderReference = event.target.value;     
        // Reset values
        if(this.isNullOrWhitespace(this.orderProviderReference)) {
            this.resetValues();
        }
    }

    /**
     * Handle a change on the "Date de commande" field for the "Commande" step
     * @param {object} event - Object of the Event.
     */	
    handleEffectiveDateChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.orderEffectiveDate = event.target.value;     
    }

    /**
     * Handle a change on the "Date de confirmation" field for the "Commande" step
     * @param {object} event - Object of the Event.
     */	
    handleConfirmationDateChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.orderConfirmationDate = event.target.value;     
        this.reloadOrderItemData = true; // Reload OrderItem Data
        // Reset values
        if(this.isNullOrWhitespace(this.orderConfirmationDate)) {
            this.resetValues();
        }
    }

    /**
     * Handle a change on the "Date de livraison prévisionnelle" field for the "Commande" step
     * @param {object} event - Object of the Event.
     */	
    handleEstimatedDeliveryDateChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.orderEstimatedDeliveryDate = event.target.value;    
        this.reloadOrderItemData = true; // Reload OrderItem Data 
        // Reset values
        if(this.isNullOrWhitespace(this.orderEstimatedDeliveryDate)) {
            this.resetValues();
        }
    }

    /**
     * Handle a change on the "Date de livraison" field for the "Commande" step
     * @param {object} event - Object of the Event.
     */	
    handleDeliveryDateChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.orderDeliveryDate = event.target.value;     
        this.reloadOrderItemData = true; // Reload OrderItem Data
    }  

    /**
     * Handle a change on the "N° de BL" field for the "Commande" step
     * @param {object} event - Object of the Event.
     */	
    handleDeliveryNumberChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.orderDeliveryNumber = event.target.value;  
        this.reloadOrderItemData = true; // Reload OrderItem Data    
    }    

    /**
     * Handle a change on the "Date de facture" field for the "Commande" step
     * @param {object} event - Object of the Event.
     */	
    handleBillingDateChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.orderBillingDate = event.target.value;
        this.reloadOrderItemData = true; // Reload OrderItem Data      
    }

    /**
     * Handle a change on the "N° de facture" field for the "Commande" step
     * @param {object} event - Object of the Event.
     */	
    handleBillingNumberChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.orderBillingNumber = event.target.value;   
        this.reloadOrderItemData = true; // Reload OrderItem Data   
    }

    /**
     * Set the value of the providers picklist in the datatable
     * @param {object} event - Event object of the "onchange" of the combobox.
     */
     handleChangeUnknownValue(event) {
        this.unknownLineCount = event.detail.value;
    }

    /**
     * Handle a change on the "Coût prévisionnel" field for the "Commande" step
     * @param {object} event - Object of the Event.
     */	
    handleEstimatedTotalCostChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.orderEstimatedTotalCost = event.target.value; 
        this.reloadOrderItemData = true; // Reload OrderItem Data   
        // Reset values
        if(this.isNullOrWhitespace(this.orderEstimatedTotalCost)) {
            this.resetValues();
        }
        else{
            this.orderEstimatedTotalCost=parseFloat(this.orderEstimatedTotalCost);
        }
        //console.log('type of orderEstimatedTotalCost : '+typeof this.orderEstimatedTotalCost);
    }

    /**
     * Handle a change on the "Coût réel" field for the "Commande" step
     * @param {object} event - Object of the Event.
     */	
    handleTotalCostChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.orderTotalCost = event.target.value;   
        if(!this.isNullOrWhitespace(this.orderTotalCost)) {
            this.orderTotalCost=parseFloat(this.orderTotalCost);
        }
        this.reloadOrderItemData = true; // Reload OrderItem Data  
        console.log('type of orderTotalCost : '+this.orderTotalCost);
    }

    /* ========== GETTER METHODS ========== */

    get hasAssets() {
        let result = true;
        if (Object.keys(this.assetsData).length === 0) {
            result = false;
        } 
        return result;
    }

    get hasOrderItems() {
        let result = true;
        if (Object.keys(this.orderItemsData).length === 0) {
            result = false;
        } 
        return result;
    }

    get isOrderTotalCostSupTo0() {
        let result = false;
        if (this.orderTotalCost > 0) {
            result = true;
        } 
        return result;
    }

    get orderContractContractNumber(){
        return this.orderContractContractNumber;
    }

    get orderAccountName(){
        return this.orderAccountName;
    }

    get orderProviderName(){
        return this.orderProviderName;
    }

    get orderProviderReference(){
        return this.orderProviderReference;
    }

    get orderConfirmationDate(){
        return this.orderConfirmationDate;
    }

    get orderEstimatedDeliveryDate(){
        return this.orderEstimatedDeliveryDate;
    }

    get orderEstimatedTotalCost(){
        return this.orderEstimatedTotalCost;
    }


    get orderDeliveryDate(){
        return this.orderDeliveryDate;
    }

    get orderBillingDate(){
        return this.orderBillingDate;
    }
    
    get orderTotalCost(){
        return this.orderTotalCost;
    }

    get orderItemCount(){
        return this.orderItemCount;
    }
    
}