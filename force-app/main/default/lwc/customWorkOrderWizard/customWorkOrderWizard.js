/* eslint-disable no-console */
import { LightningElement, api, track, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';

// Apex class methods
import getPreferenceTypePickListValues from '@salesforce/apex/LWC_CustomWorkOrderWizard.getPreferenceTypePickListValues';
import getProducts from '@salesforce/apex/LWC_CustomWorkOrderWizard.getProducts';
import getProductsNonCompliance from '@salesforce/apex/LWC_CustomWorkOrderWizard.getProductsNonCompliance';
import getNCPByDefault from '@salesforce/apex/LWC_CustomWorkOrderWizard.getNCPByDefault';
import getEntityWorkTypeParameters from '@salesforce/apex/LWC_CustomWorkOrderWizard.getEntityWorkTypeParameters';
import getSkills from '@salesforce/apex/LWC_CustomWorkOrderWizard.getSkills';
import getTechnicians from '@salesforce/apex/LWC_CustomWorkOrderWizard.getTechnicians';
import getWorkType from '@salesforce/apex/LWC_CustomWorkOrderWizard.getWorkType';
import getWorkTypeDetails from '@salesforce/apex/LWC_CustomWorkOrderWizard.getWorkTypeDetails';
import createWorkOrder from '@salesforce/apex/LWC_CustomWorkOrderWizard.createWorkOrder';
import calculateEarliestStartDateChantier from '@salesforce/apex/LWC_CustomWorkOrderWizard.calculateEarliestStartDateChantier';
import initSubWorkType from '@salesforce/apex/LWC_CustomWorkOrderWizard.initSubWorkType';
import initDueDate from '@salesforce/apex/LWC_CustomWorkOrderWizard.initDueDate';
import checkForServiceAppointmentDebriefed from '@salesforce/apex/LWC_CustomWorkOrderWizard.checkForServiceAppointmentDebriefed';

//import getCasesIdFromOrder from '@salesforce/apex/LWC_CustomWorkOrderWizard.getCasesIdFromOrder';
// Field & Object Metadata
import WORKORDER_OBJECT from '@salesforce/schema/WorkOrder';
import DURATIONTYPE_FIELD from '@salesforce/schema/WorkOrder.DurationType';
import PRIORITY_FIELD from '@salesforce/schema/WorkOrder.Priority';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

const ORDER_FIELDS = ['Order.ShipToContactId', 'Order.Status', 'Order.EffectiveDate', 'Order.Type', 'Order.chantier__c',
                        'Order.controlledAndDelivredAssetCount__c', 'Order.financingMethod__c', 'Order.serviceEntity__c',
                        'Order.source__c', 'Order.controlledAssetCount__c', 'Order.controllableAssetCount__c', 'Order.earliestControlDateOpp__c',
                        'Order.chantier__r.proprietaire__r.contactParDefaut__c', 'Order.chantier__r.occupant__r.contactParDefaut__c', 
                        'Order.chantier__r.locataire__r.contactParDefaut__c', 'Order.chantier__r.autreLocataire__r.contactParDefaut__c', 
                        'Order.chantier__r.autreOccupant__r.contactParDefaut__c', 'Order.chantier__r.occupant__c', 
                        'Order.chantier__r.autreOccupant__c', 'Order.chantier__r.locataire__c', 'Order.chantier__r.autreLocataire__c', 'Order.chantier__r.proprietaire__c', 'Order.SBQQ__Quote__c'];

const CHANTIER_FIELDS = ['AfterSalesService__c.proprietaire__c', 'Chantier__c.proprietaire__r.contactParDefaut__c', 
                        'Chantier__c.proprietaire__r.contactParDefaut__c', 'Chantier__c.serviceEntity__c'];

const SAV_FIELDS = ['AfterSalesService__c.workSite__c', 'AfterSalesService__c.workSite__r.proprietaire__r.contactParDefaut__c', 
                    'AfterSalesService__c.workSite__r.proprietaire__r.contactParDefaut__c', 'AfterSalesService__c.account__r.contactParDefaut__c',
                    'AfterSalesService__c.account__r.PersonContactId', 'AfterSalesService__c.workSite__r.serviceEntity__c'];

const PATH_STEPS = [
    { label: 'Type du RDV', value: 'step-1', display: true },
    { label: 'Produits', value: 'step-2', display: true },
    { label: 'Non-conformités produits', value: 'step-2a', display: false },
    { label: 'Contraintes', value: 'step-3', display: true },
    { label: 'Compétences', value: 'step-4', display: false },
    { label: 'Intervenants', value: 'step-5', display: false },
    { label: 'Résumé', value: 'step-6', display: true }
];
const PRODUCT_COLUMNS = [
    { label: "Nom", fieldName: 'Name'},
    { label: "Produit", fieldName: 'ProductCode'},
    { label: "Date métrage", fieldName: 'controlDate__c', type: 'date-local', initialWidth: 120 },
    { label: "Date de livraison", fieldName: 'deliveryDate__c', type: 'date-local', initialWidth: 130 },
    { label: "Date d'installation", fieldName: 'InstallDate', type: 'date-local', initialWidth: 140 }
];
const NCP_COLUMNS = [
    { label: "Numéro", fieldName: 'CaseNumber', initialWidth: 160},
    { label: "Actif", fieldName: 'AssetName'},
    { label: "Statut", fieldName: 'Status'},
    { label: "Date d'ouverture", fieldName: 'CreatedDate', type: 'date-local', initialWidth: 120 },
    { label: "Date de diagnostic", fieldName: 'diagnosticDate__c', type: 'date-local', initialWidth: 140 },
    { label: "Date de clôture", fieldName: 'ClosedDate', type: 'date-local', initialWidth: 120 }
];
const DAYS_ARRAY = [ 
    { label: 'Lundi', value: 'Lundi' },
    { label: 'Mardi', value: 'Mardi' },
    { label: 'Mercredi', value: 'Mercredi' },
    { label: 'Jeudi', value: 'Jeudi' },
    { label: 'Vendredi', value: 'Vendredi' },
    { label: 'Samedi', value: 'Samedi' }
];
const WORKTYPE_CONSTANTS = { 
    CONTROLE: 'Métrage', 
    INTERVENTION: 'Intervention', 
    DIAGNOSTIC: "Diagnostic" 
};
const WORKTYPE_OBJECT = [
    [WORKTYPE_CONSTANTS.CONTROLE, { label: 'Métrage', metier: 'Métrage', workType: WORKTYPE_CONSTANTS.CONTROLE }],
    [WORKTYPE_CONSTANTS.INTERVENTION, { label: 'Intervention', metier: 'Intervention', workType: WORKTYPE_CONSTANTS.INTERVENTION }],
    [WORKTYPE_CONSTANTS.DIAGNOSTIC, { label: 'Diagnostic', metier: 'Diagnostic', workType: WORKTYPE_CONSTANTS.DIAGNOSTIC }],
    ["installation", { label: 'Pose', metier: 'POSEUR', workType: "INSTALLATION" }]
];

export default class CustomWorkOrderWizard extends NavigationMixin(LightningElement) {
    // Current object api name
    @api objectApiName;
    // Current record's id
    @api recordId;
    // Current record
    @track record;
    // Current object metadata info
    @track objectInfo;  
    contactId;
    financingMethodId;
    sourceId;
    financingMethodName;
    quoteId;
    @track fieldArray = [];
    @api isOrderChantierInput = false;

    // Other
    @track productColumns = PRODUCT_COLUMNS;
    @track ncpColumns = NCP_COLUMNS;
    @track daysArray = DAYS_ARRAY;
    @track workTypeId;
    @track entityId;

    // Wizard Status
    @track activeWizard = true;
    @track currentRDVType;
    @track currentStep = "step-1";
    @track steps = PATH_STEPS;
    @track showStep1Form = false;
    @track showStep2Form = false;
    @track showStep2aForm = false;
    @track showStep3Form = false;
    @track showStep4Form = false;
    @track showStep5Form = false;
    @track showStep6Form = false;
    @track showNextButton = true;
    @track showResourceStep = false;
    @track showSkillStep = false;
    @track showNCPStep = false;
    @track showPreviousButton = false;
    @track showSubmitButton = false;
    @track showAllResources = false;
    @track showNCPButton = false;
    @track showNCPFilterButton = false;
    @track applyNCPFilter = false;
    @track showAssetFilterButton = false;
    @track applyAssetFilter = false;
    @track isDossierSAV = false;
    @track isCommandeSAV = false;
    @track workTypeParametersId;
    activeConstraintsSections = ['planification', 'intervenant'];
    activeSummarySections = ['planificationSummary', 'skillSummary', 'intervenantSummary'];
    
    // Datatable
    @track productsData = [];
    @track ncpData = [];
    @track skillsData = [];
    @track resourcesData = [];
    @track workTypeData;
    @track workTypeParameters;

    // Event data
    @track showLoadingSpinner = false;
    @track error;

    // Constraints step variables
    workOrderContactId;
    workOrderContactName;
    workOrderSchedulingPolicyId;
    workOrderSchedulingPolicyName;
    workOrderEarliestStartDate;
    workOrderEarliestStartDateOpp;
    workOrderDueDate;
    workOrderDuration;
    workOrderDurationType;
    workOrderMinimumCrewSize = 1;
    workOrderPriority = 'MOYEN';
    workOrderVisitingDays = [];
    workOrderVisitingStartHour;
    workOrderVisitingEndHour;
    calculatedDate;
    subWorkType = 'Inconnu';
    @track workOrderMultiDay = false;
    workOrderServiceNote;
    @track resourcePreferencePicklistValues = [];

    // non-reactive variables
    getEntityWorkTypeParametersedActionRDVTypeValue = WORKTYPE_CONSTANTS.CONTROLE;
    selectedProductRecords = [];
    selectedProductDetails = [];
    selectedNCPRecords = [];
    selectedNCPDetails = [];
    selectedSkillsRecords = [];
    selectedResourcesRecords = [];
    refreshTable;
    financingDelayBeforeControl;
    sourceDelayBeforeControl
    assetFilterButtonLabel;
    ncpFilterButtonLabel;
    productsArray = [];
    @track ncpWithoutAsset = false;
    
    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        // Init body
        this.showLoadingSpinner = true;
        this.activeWizard = true;
        this.updateWizardBody();
    }

    connectedCallback(){
        this.isDossierSAV = false;
        this.showAssetFilterButton = false;
        if(this.objectApiName === 'Order') {
            this.fieldArray = ORDER_FIELDS;
            this.steps[1].display = true; // Enable Product step
            this.steps[2].display =false; // Disable NCP step
        } else if(this.objectApiName === 'AfterSalesService__c') {
            this.fieldArray = SAV_FIELDS;
            this.steps[1].display = false; // Disable Product step
			this.steps[2].display =true; // Enable NCP step
			this.showNCPStep =true; // Enable NCP step
			this.selectedActionRDVTypeValue = WORKTYPE_CONSTANTS.INTERVENTION;
			this.isDossierSAV = true;
            this.checkForServiceAppointmentDebriefed();
        } else {
            this.fieldArray = CHANTIER_FIELDS;
            this.steps[1].display = true; // Enable Product step
			this.steps[2].display =false; // Disable NCP step
        }
        this.steps[4].display =false; // Disable Skill step
    }

    /* ========== WIRED METHODS ========== */

    /**
     * Retrieving the data of the record (Order, SAV or Chantier).
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
            // Get Work Type
            //this.getWorkTypeInit();
            // Define value for constraints
            if(this.objectApiName === 'Order') {
                this.workOrderEarliestStartDate = this.record.fields.EffectiveDate.value;
                this.workOrderEarliestStartDateOpp = this.record.fields.earliestControlDateOpp__c.value;
                this.workOrderContactId = this.contactId;            
                this.financingMethodId = this.record.fields.financingMethod__c.value;
                this.sourceId = this.record.fields.source__c.value;
                this.entityId = this.record.fields.serviceEntity__c.value;
                if(this.record.fields.Type.value === 'Commande SAV'){
                    this.steps[1].display = false; // Disable Product step
                    this.steps[2].display = true; // Enable NCP step
                    this.isCommandeSAV=true;
                    this.quoteId = this.record.fields.SBQQ__Quote__c.value;
                    this.showNCPStep =true;
                }
                // Define contactId depends on the worksite
                if(this.record.fields.chantier__r.value.fields.occupant__c.value) {
                    this.contactId = this.record.fields.chantier__r.value.fields.occupant__r.value.fields.contactParDefaut__c.value;
                } else if(this.record.fields.chantier__r.value.fields.autreOccupant__c.value) {
                    this.contactId = this.record.fields.chantier__r.value.fields.autreOccupant__r.value.fields.contactParDefaut__c.value;
                } else if(this.record.fields.chantier__r.value.fields.locataire__c.value) {
                    this.contactId = this.record.fields.chantier__r.value.fields.locataire__r.value.fields.contactParDefaut__c.value;
                } else if(this.record.fields.chantier__r.value.fields.autreLocataire__c.value) {
                    this.contactId = this.record.fields.chantier__r.value.fields.autreLocataire__r.value.fields.contactParDefaut__c.value;
                } else if(this.record.fields.chantier__r.value.fields.proprietaire__c.value) {
                    this.contactId = this.record.fields.chantier__r.value.fields.proprietaire__r.value.fields.contactParDefaut__c.value;
                } 
                // Define the entry if the chantier
                if(this.isOrderChantierInput) {
                    this.recordId = this.record.fields.chantier__c.value;
                    this.objectApiName = 'Chantier__c';
                }
            } else if(this.objectApiName === 'Chantier__c' && !this.isOrderChantierInput) {
                this.contactId = this.record.fields.proprietaire__r.value.fields.contactParDefaut__c.value;
                this.entityId = this.record.fields.serviceEntity__c.value;
                if(this.contactId == null) {
                    this.contactId = this.record.fields.proprietaire__r.value.fields.contactParDefaut__c.value;
                }
                this.workOrderContactId = this.contactId;
            } else if(this.objectApiName === 'AfterSalesService__c') {
                this.contactId = this.record.fields.account__r.value.fields.contactParDefaut__c.value;
                this.entityId = this.record.fields.workSite__r.value.fields.serviceEntity__c.value;
                if(this.contactId == null) {
                    this.contactId = this.record.fields.workSite__r.value.fields.proprietaire__r.value.fields.contactParDefaut__c.value;
                }
                this.workOrderContactId = this.contactId;
            }
            this.getWorkTypeInit();
            // Update the date
            //this.updateEarliestStartDate();
        }
    }

    /**
     * Retrieving the data of the contact.
     * @param {string} recordId - Id of the record.
     * @param {string} fields - List of fields .
     */
    @wire(getRecord, { recordId: '$contactId', fields: ['Contact.Id', 'Contact.Name'] })
    wiredContactRecord({ error, data }) {
        if (error) {
            this.processErrorMessage(error);
        } else if (data) {
            // Define default value of the contact lookup
            this.workOrderContactName = data.fields.Name.value;
        }
    }

    /**
     * Retrieving the data of the financing method.
     * @param {string} recordId - Id of the record.
     * @param {string} fields - List of fields .
     */
    @wire(getRecord, { recordId: '$financingMethodId', fields: ['Referencial__c.Id', 'Referencial__c.Name', 'Referencial__c.delayBeforeControl__c'] })
    wiredMFRecord({ error, data }) {
        if (error) {
            this.processErrorMessage(error);
        } else if (data) {
            // Define default value of the financing method
            this.financingMethodName = data.fields.Name.value;
            this.financingDelayBeforeControl = data.fields.delayBeforeControl__c.value;
            // Update the Earliest Start Date
            this.updateEarliestStartDate();
        }
    }

    /**
     * Retrieving the data of the source.
     * @param {string} recordId - Id of the record.
     * @param {string} fields - List of fields .
     */
    @wire(getRecord, { recordId: '$sourceId', fields: ['Referencial__c.Id', 'Referencial__c.delayBeforeControl__c'] })
    wiredSourceRecord({ error, data }) {
        if (error) {
            this.processErrorMessage(error);
        } else if (data) {
            // Define default value of the delay
            this.sourceDelayBeforeControl = data.fields.delayBeforeControl__c.value;
            // Update the Earliest Start Date
            this.updateEarliestStartDate();
        }
    }
    
    /**
     * Retrieving the object information of work order.
     * @param {string} objectApiName - API Name of the object.
     */
    @wire(getObjectInfo,  { objectApiName: WORKORDER_OBJECT })
    workOrderObjectInfo;
    
    /**
     * Retrieving the picklist values of "Duration Type" and "Priority" field.
     * @param {string} recordTypeId - Id of the record type of the Id.
     * @param {string} fieldApiName - API Name of the field.
     */
    @wire(getPicklistValues, { recordTypeId: '$workOrderObjectInfo.data.defaultRecordTypeId', fieldApiName: DURATIONTYPE_FIELD })
    durationTypePicklistValues;
    @wire(getPicklistValues, { recordTypeId: '$workOrderObjectInfo.data.defaultRecordTypeId', fieldApiName: PRIORITY_FIELD })
    priorityPicklistValues;

    /**
     * Retrieving the picklist values of "Resource Preference Type" field.
     */
    @wire(getPreferenceTypePickListValues)
    resourcePrefTypePicklist(result) {
        if (result.data) {
            this.resourcePreferencePicklistValues.push({label:"-- Aucune sélection --", value:""});            
            // eslint-disable-next-line guard-for-in
            for(const key in result.data){
                this.resourcePreferencePicklistValues.push({label:result.data[key], value:key}); //Here we are creating the array to show on UI.
            }
            this.error = undefined;
        } else if (result.error) {
            this.processErrorMessage(result.error);
            this.productsData = undefined;
        }
    }

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
                    if(this.steps[currIndex+2].display === true) {
                        currentStage = this.steps[currIndex+2].value;
                    } else {
                        currentStage = this.steps[currIndex+3].value;
                    }
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
                if(this.steps[currIndex-2].display === true) {
                    currentStage = this.steps[currIndex-2].value;
                } else {
                    currentStage = this.steps[currIndex-3].value;
                }
            }
            this.currentStep = currentStage;
        } 
        // Update the form to show the previous step
        this.updateWizardBody();
    }

    /**
     * Generic method to update the variable defined as name in the field with the value
     * @param {object} event - Event object of the input field.
     */
    handleGenericChange(event){
        this[event.target.name] = event.target.value;
    }

    /**
     * Handle the selected action value.
     * Executed when the user change the action on step 1.
     * @param {object} event - Event object of the "onchanged" of the radio group.
     */
    handleActionChange(event) {
        const selectedOption = event.detail.value;
        this.selectedActionRDVTypeValue = selectedOption;
        // Define Type of the RDV
        this.getWorkTypeDetails();
        // Check for debrifed SA        
    }

    /**
     * Get the products selected in the datatable
     * @param {object} event - Event object of the "onrowselection" of the datatable.
     */
    handleSelectedProductsChange(event) {
        this.resetErrorMessage();
        // Get row selected
        const selectedRows = event.detail.selectedRows;
        // Init the array of products
        this.selectedProductRecords = [];        
        // Add product selected in the array
        for (const asset of selectedRows){            
            this.selectedProductRecords.push(asset.Id);
        }
        // If RDV != Control, then get NCP
        if(this.currentRDVType.workType !== WORKTYPE_CONSTANTS.CONTROLE) {                    
            this.getPNCs(false);
        }
        // Update duration
        this.updateDuration();        
        // Update crew size
        this.updateCrewSize();
    }

    /**
     * Get the NPCs selected in the datatable
     * @param {object} event - Event object of the "onrowselection" of the datatable.
     */
    handleSelectedNCPsChange(event) {
        this.resetErrorMessage();
        // Get row selected
        const selectedRows = event.detail.selectedRows;
        // Init the array of NCPs
        this.selectedNCPRecords = [];        
        // Add NCP selected in the array
        for (const ncp of selectedRows){           
            this.selectedNCPRecords.push(ncp.Id);
        }
        // Update duration
        this.updateDuration();      
        // Update crew size
        this.updateCrewSize();
    }

    /**
     * Method executed when the contact lookup is changed
     * @param {object} event - Event object of the input field.
     */
    handleContactLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.workOrderContactId = selection[0].id;
            this.workOrderContactName = selection[0].title;
        } else {
            this.workOrderContactId = "";
            this.workOrderContactName = "";
            this.processErrorMessage(this.checkContact(), false);
        }
    }

    /**
     * Method executed when the service territory lookup is changed
     * @param {object} event - Event object of the input field.
     */
    /*handleServiceTerritoryLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.serviceTerritoryId = selection[0].id;
            this.serviceTerritoryName = selection[0].title;
        } else {
            this.serviceTerritoryId = "";
            this.serviceTerritoryName = "";
        }
    }*/

    handleSchedulingPolicyLookupChange(event) {
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.workOrderSchedulingPolicyId = selection[0].id;
            this.workOrderSchedulingPolicyName = selection[0].title;
        } else {
            this.workOrderSchedulingPolicyId = null;
            this.workOrderSchedulingPolicyName = "";
        }
    }

    /**
     * Update the variable workOrderVisitingStartHour and check errors
     * @param {object} event - Event object of the input field.
     */
    handleVisitingStartHourChange(event) {
        this.resetErrorMessage();
        this.workOrderVisitingStartHour = event.target.value;     
        // Check errors
        event.target.setCustomValidity(this.checkVisitingStartHour());
        // Active the error state or not
        event.target.reportValidity();
    }

    /**
     * Update the variable workOrderVisitingEndHour and check errors
     * @param {object} event - Event object of the input field.
     */
    handleVisitingEndHourChange(event) {
        this.resetErrorMessage();
        this.workOrderVisitingEndHour = event.target.value;     
        // Check errors
        event.target.setCustomValidity(this.checkVisitingEndHour());
        // Active the error state or not
        event.target.reportValidity();
    }     

    /**
     * Update the variable workOrderEarliestStartDate and check errors
     * @param {object} event - Event object of the input field.
     */
    handleEarliestStartDateChange(event) {
        this.resetErrorMessage();
        this.workOrderEarliestStartDate = event.target.value;     
        // Check errors
        event.target.setCustomValidity(this.checkEarliestStartDate());
        // Active the error state or not
        event.target.reportValidity();
    }

    /**
     * Update the variable workOrderDueDate and check errors
     * @param {object} event - Event object of the input field.
     */
    handleDueDateChange(event) {
        this.resetErrorMessage();
        this.workOrderDueDate = event.target.value;        
        // Check errors
        event.target.setCustomValidity(this.checkDueDate());
        // Active the error state or not
        event.target.reportValidity();
    }

    /**
     * Convert the duration value if type is hours or minutes
     * @param {object} event - Event object of the input field.
     */
    handleDurationTypeChange(event) {
        this.resetErrorMessage();
        this.workOrderDurationType = event.detail.value;
        if(this.workOrderDurationType === 'Hours') {
            this.workOrderDuration = this.workOrderDuration / 60;
        } else if(this.workOrderDurationType === 'Minutes') {
            this.workOrderDuration = this.workOrderDuration * 60;
        }
        this.updateMultiDayDuration();
    }

    /**
     * Check the duration and tick the MultiDay field if duration > 5 hours
     * @param {object} event - Event object of the input field.
     */
    handleDurationChange(event) {
        this.resetErrorMessage();
        this.workOrderDuration = event.detail.value;
        this.updateMultiDayDuration();
    }

    /**
     * Update the variable when the picklist values changes
     * @param {object} event - Event object of the input field.
     */
    handleVisitingDaysChange(event) {
        this.resetErrorMessage();
        this.workOrderVisitingDays = event.detail.value;
    }  

    /**
     * Update the variable workOrderMinimumCrewSize and check errors
     * @param {object} event - Event object of the input field.
     */
    handleMinimumCrewSizeChange(event) {
        this.resetErrorMessage();
        this.workOrderMinimumCrewSize = event.target.value;   

        // Active the error state or not
        event.target.reportValidity();
    } 

    /**
     * Update the variable to display or not the step "Non-conformité produits" when the toggle field changes
     * @param {object} event - Event object of the input field.
     */
    handleShowNCPStepChange(event) {
        this.showNCPStep = event.target.checked;
        // Update the flag for the step "NCP"
        this.steps[2].display = this.showNCPStep;
        // Clear NCP Selected if deactivate
        if(!this.showNCPStep) {
            this.selectedNCPRecords = [];
        }
        // Update Crew Size
        this.updateCrewSize();
    }

    /**
     * Update the variable to display or not asset by status when the toggle field changes
     * @param {object} event - Event object of the input field.
     */
    handleAssetFilterChange(event) {
        this.applyAssetFilter = event.target.checked;
        // Update the asset list
        this.getProducts();
    }

    /**
     * Update the variable to display or not NCP by status when the toggle field changes
     * @param {object} event - Event object of the input field.
     */
    handleNCPFilterChange(event) {
        this.applyNCPFilter = event.target.checked;
        // Update the NCP list
        this.getPNCs(false);
    }

    /**
     * Update the variable to display or not the step "Intervenant" when the toggle field changes
     * @param {object} event - Event object of the input field.
     */
    handleShowResourceStepChange(event) {
        this.showResourceStep = event.target.checked;
        // Update the flag for the step "Intervenant"
        this.steps[5].display = this.showResourceStep;
    }

    /**
     * Update the variable to display or not the step "Compétence" when the toggle field changes
     * @param {object} event - Event object of the input field.
     */
     handleShowSkillStepChange(event) {
        this.showSkillStep = event.target.checked;
        // Update the flag for the step "Compétence"
        this.steps[4].display = this.showSkillStep;
    }
    
    /**
     * Update the variable to display or not all resources 
     * @param {object} event - Event object of the input field.
     */
    handleShowAllResourcesChange(event) {
        this.showAllResources = event.target.checked;
        // Update the table of resources
        this.getResources();
    }
    
    /**
     * Execute the process to check errors and to create Work Order.
     * Executed when the user clicks on the "Créer le RDV" button of the wizard.
     */
    handleCreateWorkOrder() {
        this.resetErrorMessage();
        this.showLoadingSpinner = true;
        // Check errors, continue if no errors
        if(this.checkForErrors()) {
            this.createWorkOrder();
            this.currentStep = 'step-1';
            this.updateWizardBody();
        }
    }

    /* ========== GETTER METHODS ========== */

    get actionRDVTypeValues() {
        let result;
		// Don't display the "Controle" value for SAV
   		if(this.isDossierSAV || this.isCommandeSAV) {
			result = [
				{ label: WORKTYPE_CONSTANTS.INTERVENTION, value: WORKTYPE_CONSTANTS.INTERVENTION },
				{ label: WORKTYPE_CONSTANTS.DIAGNOSTIC, value: WORKTYPE_CONSTANTS.DIAGNOSTIC }
			];
		} else {
			result = [
				{ label: WORKTYPE_CONSTANTS.CONTROLE, value: WORKTYPE_CONSTANTS.CONTROLE },
				{ label: WORKTYPE_CONSTANTS.INTERVENTION, value: WORKTYPE_CONSTANTS.INTERVENTION },
				{ label: WORKTYPE_CONSTANTS.DIAGNOSTIC, value: WORKTYPE_CONSTANTS.DIAGNOSTIC }
			];
		}
        return result;
    }

    get hasSkillsData() {
        let result = true;
        if (this.skillsData.length === 0) {
            result = false;
        } 
        return result;
    }

    get hasSkillsSelected() {
        let result = true;
        if (this.selectedSkillsRecords.length === 0) {
            result = false;
        } 
        return result;
    }

    get hasNCPsSelected() {
        let result = true;
        if (this.selectedNCPRecords.length === 0) {
            result = false;
        } 
        return result;
    }

    get hasResourcesSelected() {
        let result = true;
        if (this.selectedResourcesRecords.length === 0) {
            result = false;
        } 
        return result;
    }

    get workTypeLabel() {
        let result = "";
        if (this.currentRDVType) {
            result = this.currentRDVType.label.toLowerCase();
        }
        return result;
    }

    /* ========== JS METHODS ========== */

    /**
     * Retrieving the work type using wire service
     */
    getWorkTypeInit() {
        try {
            this.showLoadingSpinner = true;

            // Call APEX method to get workType infos
            getWorkType({ recordId: this.recordId, objectApiName: this.objectApiName, isCommandeSAV : this.isCommandeSAV})
            .then(result => {
                // If worktype, we set values
                if (result) {
                    // Init workType values
                    this.workTypeData = result;
                    this.workTypeId  = result.Id;
                    // Get entityWorktYpeParamenters
                    this.getEntityWorkTypeParameters();
                    // Init value of WorkType data
                    this.initWorkTypeData(true);
                } else {                    
                    this.activeWizard = false;
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
     * Retrieving the work type detail using wire service
     */
    getWorkTypeDetails() {
        try {
            this.showLoadingSpinner = true;

            // Call APEX method to get workType infos
            getWorkTypeDetails({ workTypeName: this.selectedActionRDVTypeValue})
            .then(result => {
                // If worktype, we set values
                if (result) {
                    // Init workType values
                    this.workTypeData = result;
                    this.workTypeId = result.Id;
                    // Get entityWorktYpeParamenters
                    this.getEntityWorkTypeParameters();
                    // Init value of WorkType data
                    this.initWorkTypeData(false);
                } else {                    
                    this.activeWizard = false;
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
     * Retrieving the entity work type parameter detail using wire service
     */
    getEntityWorkTypeParameters() {
        try {
            this.showLoadingSpinner = true;

            // Call APEX method to get EntityWorkTypeParameters infos
            getEntityWorkTypeParameters({ workTypeId: this.workTypeId, entityId: this.entityId})
            .then(result => {
                // If worktype parameter, we set values
                if (result) {
                    // Init workType parameter values
                    this.workTypeParameters = result;
                    this.workTypeParametersId = this.workTypeParameters.Id;
                } else {
                    this.workTypeParameters = null;
                    this.workTypeParametersId = null;
                }
                // Init value of WorkType data
                this.initWorkTypeData(false);
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
     * Initialize fields of the wizard with data of the work type
     */
    initWorkTypeData(isInit) {
        try {
            // If worktype, we set values
            if (this.workTypeData) {
                // Init workType values
                this.selectedActionRDVTypeValue = this.workTypeData.Name;
                this.workOrderDuration = this.defineAdministrativeDuration();

                this.workOrderDurationType = this.workTypeData.DurationType;
                this.workOrderMinimumCrewSize = this.workTypeData.MinimumCrewSize;
                
                // Init SchedulingPolicy lookup
                if (this.workTypeParameters && this.workTypeParameters.schedulingPolicy__c != null){
                    this.workOrderSchedulingPolicyId = this.workTypeParameters.schedulingPolicy__c;
                    this.workOrderSchedulingPolicyName = this.workTypeParameters.schedulingPolicy__r.Name;
                } else if (this.workTypeData && this.workTypeData.schedulingPolicy__c != null){
                    this.workOrderSchedulingPolicyId = this.workTypeData.schedulingPolicy__c;
                    this.workOrderSchedulingPolicyName = this.workTypeData.schedulingPolicy__r.Name;
                } else {
                    this.workOrderSchedulingPolicyId = null;
                    this.workOrderSchedulingPolicyName = "";
                }

                // Define Type of the RDV
                const workTypeMap = new Map(WORKTYPE_OBJECT);
                if(this.objectApiName === 'AfterSalesService__c' && isInit) {
                    this.selectedActionRDVTypeValue = WORKTYPE_CONSTANTS.INTERVENTION;
                } 
                this.currentRDVType = workTypeMap.get(this.selectedActionRDVTypeValue); // Define WorkType by Name

                //Do not show NCP Button and step on CONTROLE
                if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.CONTROLE) {
                    this.hideNCPStep();
                } else{
                    this.showNCPButton = true; //Show the NCP Button on Diagnostic and Intervention
                }

                // Display asset filter or not 
                this.showAssetFilterButton = true;
                this.applyAssetFilter = true;
                if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.CONTROLE) {
                    this.assetFilterButtonLabel = 'Non métrés ?';
                }
                if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.INTERVENTION) {
                    this.assetFilterButtonLabel = 'Non installés ?';                       
                }
                if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.DIAGNOSTIC) {
                    this.assetFilterButtonLabel = 'Déjà installés ?';                        
                }
                // Display ncp filter or not 
                this.showNCPFilterButton = false;
                this.applyNCPFilter = false;
                if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.INTERVENTION) {
                    this.applyNCPFilter = true;   
                    this.showNCPFilterButton = true; 
                    this.ncpFilterButtonLabel = 'Déjà diagnostiqués ?'; 
                }
                if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.DIAGNOSTIC) {
                    this.applyNCPFilter = true;   
                    this.showNCPFilterButton = true; 
                    this.ncpFilterButtonLabel = 'Non diagnostiqués ?';                        
                }
                this.activeWizard = true;
                this.error = undefined;
                // Update the date
                this.updateEarliestStartDate();
            }
        } catch(error) {
            this.processErrorMessage(error.message);
        }
    }
    
    /**
     * Retrieving the products using wire service
     */
    getProducts() {
        try {
            this.showLoadingSpinner = true;
            // Init the array of products
            this.productsData = [];
            this.selectedProductRecords = [];  

            // Call APEX method to get products
            getProducts({ recordId: this.recordId, objectApiName: this.objectApiName, activityType: this.currentRDVType.workType, applyAssetFilter: this.applyAssetFilter})
            .then(result => {
                // If products, we set the table
                if (result.length !== 0) {
                    this.productsData = result;   
                    const selectedIds = [];
                    for (const line of result) {
                        // For Controle : Init product only for not controled date or no ServiceAppoiment in progress (use WOLI because no direct link with SA)
                        if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.CONTROLE) {
                            if(line.hasOwnProperty('controlDate__c') === false && line.hasOwnProperty('WorkOrderLineItems') === false && line.Product2.isControllable__c) {
                                selectedIds.push(line.Id);
                            }
                        }
                        // For Intervention : Init product only for not install date or no ServiceAppoiment in progress (use WOLI because no direct link with SA)
                        // AND no controllable OR (controllable with a control date)
                        if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.INTERVENTION) {
                            if(line.hasOwnProperty('InstallDate') === false && line.hasOwnProperty('WorkOrderLineItems') === false 
                                && (!line.Product2.isControllable__c || (line.Product2.isControllable__c && line.hasOwnProperty('controlDate__c')))
                            ) 
                            {
                                selectedIds.push(line.Id);
                            }
                        }
                    }
                    this.selectedProductRecords = selectedIds;
                    // If RDV != CONTROLE, then get NCP
                    if(this.currentRDVType.workType !== WORKTYPE_CONSTANTS.CONTROLE) {                    
                        this.getPNCs();
                    } 
                    // Update duration
                    this.updateDuration();      
                    this.error = undefined;
                }
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        } catch(error) {
            this.processErrorMessage(error.message);
            this.productsData = undefined;
        }
    }
    
    /**
     * Retrieving the NCP (Non conformité produit) using wire service
     */
    getPNCs(processNCPStep = true) {
        // Init the array of NCP
        this.ncpData = [];
        this.selectedNCPRecords = [];

        try {
            // Parameters 
            let parameters = {};
            if(this.isCommandeSAV) {
            parameters = { activityType: this.currentRDVType.workType, orderId: this.recordId, isCommandeSAV: this.isCommandeSAV, applyNCPFilter: this.applyNCPFilter, quoteId: this.quoteId }
            }
            else if(this.objectApiName === 'Order' && !this.isOrderChantierInput) {
                parameters = { activityType: this.currentRDVType.workType, orderId: this.recordId, applyNCPFilter: this.applyNCPFilter }
            }
            else if(this.isDossierSAV) {
                parameters = { savId: this.recordId, activityType: this.currentRDVType.workType, applyNCPFilter: this.applyNCPFilter };
            } else {
                //Get the Id of products
                const assetsId = [];
                for(const line of this.productsData) {
                    assetsId.push(line.Id);
                }
                parameters = { assetsId: assetsId, activityType: this.currentRDVType.workType, applyNCPFilter: this.applyNCPFilter };
            }

            // Call APEX method to get NCP
            //if((this.isDossierSAV && this.recordId != null) || (this.isCommandeSAV && this.recordId != null) || ((this.isDossierSAV === false && this.isCommandeSAV === false) && assetsId.length !== 0)) {
                getProductsNonCompliance(parameters)
                .then(resultNCP => {
                    // If skills, we set the table
                    if (resultNCP.length !== 0) {                        
                        // Is no Asset, check a flag to display a warning msg
                        for(const line of resultNCP) {
                            if(line.Asset === undefined) {
                                this.ncpWithoutAsset = true;
                            }
                        }

                        // Filter to remove NCP without Asset and add property "AssetName" in the JS variable                       
                        this.ncpData = resultNCP.filter(element => element.Asset !== undefined).map((item) =>
                            Object.assign({}, item, { AssetName:item.Asset.Name })
                        )

                        const casesId = [];
                        for(const line of this.ncpData) {
                            casesId.push(line.Id);
                        }
                        if(casesId) {
                            getNCPByDefault({ casesId: casesId, activityType: this.currentRDVType.workType})
                            .then(resultNCPDef => {
                                // If NCP, we set the table
                                if (resultNCPDef.length !== 0) {
                                    const selectedIds = [];
                                    for (const line of resultNCPDef) {
                                        selectedIds.push(line);
                                    }
                                    this.selectedNCPRecords = selectedIds;
                                    this.error = undefined;    
                                    this.updateCrewSize();
                                } 
                            })
                            .catch(error => {
                                this.processErrorMessage(error);
                            });
                            this.error = undefined;    

                            // Display the NCP step or not
                            this.showNCPButton = true;
                            if(processNCPStep) {
                                if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.CONTROLE) {
                                    this.hideNCPStep();
                                } else {
                                    this.showNCPStep = true; //Show the NCP Button on Diagnostic and Intervention
                                }
                            }
                            this.steps[2].display = this.showNCPStep;
                            // Update crew size
                            this.updateCrewSize();
                        }
                    } 
                })
                .catch(error => {
                    this.processErrorMessage(error);
                });
                //Default record checked

            //} else {
                // Hide NCP step
            //    this.hideNCPStep();
            //}
        } catch(error) {
            this.processErrorMessage(error.message);
            this.ncpData = undefined;
        }
    }

    /**
     * Retrieving the skills using wire service
     */
    getAllSkills() {
        try {
            this.showLoadingSpinner = true;
            // Init
            this.skillsData = [];
            const ncpSelected = (this.selectedNCPRecords.length !== 0 && this.showNCPStep
                                    && this.currentRDVType.workType === WORKTYPE_CONSTANTS.INTERVENTION) ? true : false;
            // Call APEX method to get skills by products or type
            getSkills({ assetsId: this.selectedProductRecords, 
                        workTypeName: this.currentRDVType.workType, 
                        withNCP: ncpSelected })
            .then(result => {
                // If skills, we set the table
                if (result.length !== 0) {
                    this.skillsData = JSON.parse(JSON.stringify(result));                                
                    // Get the default skills  
                    this.selectedSkillsRecords = result.filter(element => element.value > 0) // Filter to get only if value > 0
                    .map(element => { // Create an map of the skill
                        return {
                            id: element.id, 
                            name: element.name, 
                            value: element.value
                        };
                    });
                    // Define list of resources depends on skills
                    this.getResources();
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
     * Calculate the EarliestStartDate for a chantier (max of the EffectiveDate of all Customer Order link with all assets)
     */
    calculDateForChantier() {
        try {
			// Define parameters by object
			let parameters = {};
			if(this.isDossierSAV || this.isCommandeSAV) {
				parameters = { assetsId: this.selectedProductRecords};
			} else {
				parameters = { ncpsId: this.selectedNCPRecords};
			}

            // Call APEX method to get resources
            calculateEarliestStartDateChantier(parameters)
            .then(result => {
                const today = new Date().toISOString().slice(0, 10);
                if (result != null) {
                    this.workOrderEarliestStartDate = result;           
                } else {                    
                    this.workOrderEarliestStartDate = today // Update date with the today date
                }
                // if the date is lower than today date
                if(this.workOrderEarliestStartDate < today) {
                    this.workOrderEarliestStartDate = today // Update date with the today date
                }
                this.calculatedDate = this.workOrderEarliestStartDate; 
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
     * Retrieving the technicians using wire service
     */
    getResources() {
        try{
            // Init
            this.resourcesData = [];
            let actitivitype = this.currentRDVType.metier;
            if(this.showAllResources) {
                actitivitype = 'ALL'; 
            }
            // Call APEX method to get resources
            getTechnicians({ recordId: this.recordId, objectApiName: this.objectApiName, activityType: actitivitype, skills: this.selectedSkillsRecords})
            .then(result => {
                // If resources, we set the table
                if (result.length !== 0) {
                    this.resourcesData = JSON.parse(JSON.stringify(result));   
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
     * Execute the process to initialise the subWorkType Field
     */
    initSubWorkType() {
        // Init the array of NCP
        
        try {
            console.log(JSON.stringify(this.selectedNCPRecords));
            // Call APEX method to init subWorkType
            initSubWorkType({workTypeName : this.currentRDVType.workType,
                                casesIdList : this.selectedNCPRecords,
                                recordId : this.recordId
                            }
            )
            .then(result =>{
                if(result){
                    console.log("result = " + result);
                    this.subWorkType = result;
                }
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
            
        } catch(error) {
            this.processErrorMessage(error.message);
            this.ncpData = undefined;
        }
    }
    
    /**
     * Execute the process to create the Work Order.
     */
    createWorkOrder() {
        // Create map parameters
        console.log('swt : ' + this.subWorkType != null);
        const parameters = {workType: this.currentRDVType.workType,
                            workOrderVisitingDays: this.workOrderVisitingDays.toString(),
                            workOrderVisitingStartHour: this.workOrderVisitingStartHour,
                            workOrderVisitingEndHour: this.workOrderVisitingEndHour,
                            workOrderDurationType: this.workOrderDurationType,
                            workOrderDuration: this.workOrderDuration,
                            workOrderMultiDay: this.workOrderMultiDay,
                            workOrderEarliestStartDate: this.workOrderEarliestStartDate,
                            workOrderDueDate: this.workOrderDueDate,
                            workOrderPriority: this.workOrderPriority,
                            workOrderMinimumCrewSize: this.workOrderMinimumCrewSize,
                            workOrderServiceNote: this.workOrderServiceNote,
                            workOrderContactId: this.workOrderContactId,
                            workTypeParametersId : this.workTypeParametersId,
                            subWorkType : this.subWorkType
                        };
        console.log("parameters: "+JSON.stringify(parameters));
        // Call APEX action to create the WorkOrder
        createWorkOrder({ recordId: this.recordId, 
                            assetsId: this.selectedProductRecords, 
                            skills: this.selectedSkillsRecords, 
                            ressources: this.selectedResourcesRecords, 
                            ncpsId: this.selectedNCPRecords, 
                            mapParameters: parameters
                        }
        )
        .then(result => {
            if(result) {
                this.showNotification('Demande de rendez-vous créée', "La demande de rendez-vous a été créée avec succès", 'success');
                // View the detail of the record.
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        actionName: 'view'
                    }
                });
            } else {                
                this.showNotification('Erreur', "La demande de rendez-vous n'a pas été créée.", 'error');
            }
            this.showLoadingSpinner = false;
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
    }

    /**
     * Function executed when the user click on the Previous/Next button to update the form.
     */
    updateWizardBody() {
        this.showStep1Form = false;
        this.showStep2Form = false;
        this.showStep2aForm = false;
        this.showStep3Form = false;
        this.showStep4Form = false;
        this.showStep5Form = false;
        this.showStep6Form = false;
        this.showPreviousButton = true;
        this.showNextButton = true;
        this.showSubmitButton = false;
        switch (this.currentStep) {
            case 'step-1':
                this.showStep1Form = true;
                this.showPreviousButton = false;
                break;
            case 'step-2':
                //For Controle : Diseable the NCP view
                if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.CONTROLE) {
                    this.steps[2].display = false;
				}
				this.getProducts();
                this.showStep2Form = true;
                break;
            case 'step-2a':
				//if(this.isDossierSAV || this.isCommandeSAV) {
					this.getPNCs(false);
				//} 
                this.showStep2aForm = true;
                break;
            case 'step-3':
                if(this.objectApiName === 'Chantier__c' || this.isDossierSAV) {
                    this.calculDateForChantier();
                }
                this.getSelectedProductDetails();
                this.updateEarliestStartDate();
                this.updateDueDate();
                this.getAllSkills();
                this.showStep3Form = true;
                break;
            case 'step-4': 
                this.showStep4Form = true;
                break;
            case 'step-5':
                this.getResources();
                this.showStep5Form = true;
                break;
            case 'step-6':
                this.getSelectedProductDetails();
                this.getSelectedNCPDetails();
                this.showStep6Form = true;
                this.showSubmitButton = true;
                this.showNextButton = false;
                this.initSubWorkType();
                break;
        }
    }

    /**
     * Initialize the Earliest Start Date according to the business rules.
     */
    updateEarliestStartDate() {
        try {
            // Define value of the earliest date
            if(this.objectApiName === 'Order') {
                this.workOrderEarliestStartDate = this.record.fields.EffectiveDate.value;
            } else {
                this.workOrderEarliestStartDate = new Date();
            }
            // Define value of the earliest date
            //this.workOrderEarliestStartDate = this.record.fields.EffectiveDate.value;
            if(this.workOrderEarliestStartDate && this.currentRDVType) {
                // If WorkType = Control, then calcul the date with delay by the source or the financing method
                if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.CONTROLE) {  
                    const delayMax = Math.max(this.financingDelayBeforeControl, this.sourceDelayBeforeControl);
                    // If delay defined, then Date+Delay MAX
                    if(delayMax && delayMax !== null) {
                        const tmp = new Date(this.workOrderEarliestStartDate);
                        tmp.setDate(tmp.getDate() + delayMax);
                        this.workOrderEarliestStartDate = tmp.toISOString().split('T')[0];
                    } else {
                        // If other, then Date+14J
                        const tmp = new Date(this.workOrderEarliestStartDate);
                        tmp.setDate(tmp.getDate() + 14);
                        this.workOrderEarliestStartDate = tmp.toISOString().split('T')[0];
                    }
                    if(this.workOrderEarliestStartDateOpp !== null && this.workOrderEarliestStartDateOpp > this.workOrderEarliestStartDate) {
                        this.workOrderEarliestStartDate = this.workOrderEarliestStartDateOpp;
                    }
                }

                // If WorkType = Intervention, then calcul the date by delivery date of assets
                if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.INTERVENTION) { 
                    // Check if assets is selected
                    if(this.selectedProductDetails.length > 0) {
                        let tmpDeliveyDate = null;
                        for(const asset of this.selectedProductDetails) {
                            // Get Delivery date for each assets and get the min
                            if(asset.data.maxDeliveryDate__c && (tmpDeliveyDate < asset.data.maxDeliveryDate__c || tmpDeliveyDate == null) ) {
                                tmpDeliveyDate = asset.data.maxDeliveryDate__c;
                            }
                        }
                        // If no delivery date, get the Estimated date for each assets and get the min
                        if(tmpDeliveyDate === null) {
                            for(const asset of this.selectedProductDetails) {
                                if(asset.data.maxEstimatedDeliveryDate && (tmpDeliveyDate < asset.data.maxEstimatedDeliveryDate || tmpDeliveyDate == null) ) {
                                    tmpDeliveyDate = asset.data.maxEstimatedDeliveryDate;
                                }
                            }
                        }
                        if(tmpDeliveyDate) {
                            this.workOrderEarliestStartDate = tmpDeliveyDate;
                        }
                    } 

                }

                // Change the date if lesser than today
                const today = new Date();
                const date = new Date(this.workOrderEarliestStartDate+'T00:00:00');
                if(today > date) {
                    const dd = String(today.getDate()).padStart(2, '0');
                    const mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
                    const yyyy = today.getFullYear();
                    const todayDate = yyyy + '-' + mm + '-' + dd;
                    
                    this.workOrderEarliestStartDate = todayDate;
                }
                this.calculatedDate = this.workOrderEarliestStartDate;
            }
        } catch(error) {
            this.processErrorMessage(error);
        }
    }

    /**
     * Initialize the Duration according to the business rules.
     */
    updateDuration() {
        try {
            let durationType;
            let duration;            
            // Check the global values to get product selected
            this.getSelectedProductDetails();    
            // Check the global values to get NCP selected
            this.getSelectedNCPDetails();

            // Get duration by the workType
            if(this.workTypeData) {
                durationType = this.workTypeData.DurationType;
                duration = this.defineAdministrativeDuration();
                if(durationType === "Hours") {
                    duration = duration * 60;
                    durationType = "Minutes";
                } 
            }           
            console.log('duration '+duration);
            // Get duration from products and by worktype
            if(this.selectedProductDetails.length > 0) {
                for(const asset of this.selectedProductDetails) {
                    // Duration for control
                    if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.CONTROLE && asset.data.warrantyMaxDuration__c) {
                        duration += asset.data.warrantyMaxDuration__c; // Utilisation temporaire du champ pour stocker la valeur de métrage
                    }
                    // Duration for intervention
                    if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.INTERVENTION && asset.data.installDuration__c) {
                        duration += asset.data.installDuration__c;
                    }
                }
            }
            // Get duration from NCP
            if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.INTERVENTION && this.selectedNCPDetails.length > 0) {
                for(const line of this.selectedNCPDetails) {
                    // Duration for control
                    if(line.data.interventionDuration__c) {
                        duration += line.data.interventionDuration__c;
                    }
                }
            }
            // Update
            if(duration) {
                if(durationType === 'Minutes' && duration%60 == 0){
                    durationType = 'Hours';
                    duration = duration/60;
                }
                this.workOrderDurationType = durationType;
                this.workOrderDuration = duration;
                this.updateMultiDayDuration();
            }
        } catch(error) {
            this.processErrorMessage(error.message);
        }
    }
    
    /**
     * Update administrative duration by worktype data or by Entity/Worktype parameters
     */
    defineAdministrativeDuration() {
        let result;
        if(this.workTypeParameters != null && this.workTypeParameters.estimatedDuration__c != null) {
            result = this.workTypeParameters.estimatedDuration__c;
        } else {
            result = this.workTypeData.EstimatedDuration;
        }
        return result;
    }
    
    /**
     * Update the MultiDay field if duration > 5 hours
     */
    updateMultiDayDuration() {
        if(this.workOrderDurationType === 'Hours' && this.workOrderDuration > 5) {
            this.workOrderMultiDay = true;
        } else if(this.workOrderDurationType === 'Minutes' && this.workOrderDuration > 300) {
            this.workOrderMultiDay = true;
        } else {
            this.workOrderMultiDay = false;
        }
    }

    /**
     * Initialize the Crew size (min and max) according to the business rules for RDV = intervention.
     */
    updateCrewSize() {
        try {
            // Process for intervention
            if(this.currentRDVType.workType === WORKTYPE_CONSTANTS.INTERVENTION) {
                let crewSize = 0;     

                // Check the global values to get product selected
                this.getSelectedProductDetails();       
                // Get crew size from products 
                if(this.selectedProductDetails.length > 0) {
                    for(const asset of this.selectedProductDetails) {
                        if(asset.data.installCrewSize__c > crewSize) {
                            crewSize = asset.data.installCrewSize__c;
                        }
                    }
                }
                
                // Check the global values to get NCP selected
                const ncpSelected = (this.selectedNCPRecords.length !== 0 && this.showNCPStep) ? true : false; 
                if(ncpSelected) {
                    this.getSelectedNCPDetails();
                    // Get crew size from NCP
                    if(this.selectedNCPDetails.length > 0) {
                        for(const ncp of this.selectedNCPDetails) {
                            if(ncp.data.interventionCrewSize__c > crewSize) {
                                crewSize = ncp.data.interventionCrewSize__c;
                            }
                        }
                    }
                }
                // Update
                if(crewSize > 0) {
                    this.workOrderMinimumCrewSize = crewSize;
                }
            }
        } catch(error) {
            this.processErrorMessage(error.message);
        }
    }

    /**
     * Function to get skills selected by the user to display them in the step 6 (summary).
     */
    getSelectedSkillsRecords() {
        try {
            // Get skills Id and values in the datatable
            this.selectedSkillsRecords = Array.from(
                this.template.querySelectorAll('lightning-input')
            )
            .filter(element => element.value > 0) // Filter to get only if value > 0
            .map(element => { // Create an map of the skill
                return {
                    id: element.dataset.skillId, 
                    name: element.dataset.skillName, 
                    value: element.value
                };
            });
        } catch(error) {
            this.processErrorMessage(error.message);
        }
    }

    /**
     * Function to get products selected by the user to display them in the step 6 (summary).
     */
    getSelectedProductDetails() {
        try {
            const result = [];
            for (const assetId of this.selectedProductRecords) {
                for(const line of this.productsData) {
                    if(assetId === line.Id) {
                        // Add details of the product in the list
                        result.push({
                            id: line.Id, 
                            name: line.Name, 
                            productCode: line.ProductCode, 
                            url: "/"+line.Id,
                            data: line
                        });
                        break;
                    }
                }
            }
            this.selectedProductDetails = result;
        } catch(error) {
            this.processErrorMessage(error.message);
        }
    }
    
    /**
     * Function to get ncp selected by the user.
     */
    getSelectedNCPDetails() {
        try {
            const result = [];
            for (const ncpId of this.selectedNCPRecords) {
                for(const line of this.ncpData) {
                    if(ncpId === line.Id) {
                        result.push({
                            id: line.Id, 
                            caseNumber: line.CaseNumber, 
                            asset: line.AssetName, 
                            url: "/"+line.Id,
                            data: line
                        });
                        break;
                    }
                }
            }
            this.selectedNCPDetails = result;
        } catch(error) {
            this.processErrorMessage(error.message);
        }
    }

    /**
     * Function to get resources selected by the user.
     */
    getSelectedResourcesRecords() {
        try {
            // Get the resource Id and values
            this.selectedResourcesRecords = Array.from(
                this.template.querySelectorAll('lightning-combobox')
            )
            .filter(element => element.value !== "") // Filter to get only if presence is defined
            .map(element => { // Create an map of the resource
                return {
                    id: element.dataset.resourceId, // Id of the resource
                    name: element.dataset.resourceName, // Name of the resource
                    value: element.value, // Value of the picklist value
                    label: element.options.find(opt => opt.value === element.value).label // Label of the picklist value
                };
            });
        } catch(error) {
          this.processErrorMessage(error.message);
        }
    }

    /**
     * Function to check the contact in step 4.
     */
    checkContact() {
        let result = "";
        if(this.workOrderContactName === "") {
            result = "La sélection d'un contact est obligatoire";
        } 
        return result;
    }

    /**
     * Function to check the validity of the due date in step 4.
     */
    checkDueDate() {
        let result = "";
        if(this.workOrderDueDate) {
            //const dueDateTMP = new Date(this.workOrderDueDate);
            const startDate3M = new Date(this.record.fields.EffectiveDate.value);
            startDate3M.setMonth( startDate3M.getMonth() + 3 );
            // Define error message
            if(this.workOrderEarliestStartDate && this.workOrderDueDate <= this.workOrderEarliestStartDate) {
                result = "La date d'échéance ne peut pas être inférieure ou égale à la date de début du rendez-vous";
            } 
            /* DESACTIVATION SUITE MEP PAR KPARK
            if(dueDateTMP > startDate3M) {
                result = "Le rendez-vous doit être effectué dans les 3 mois après la date de début de la commande";
            } 
            */
        } 
        return result;
    }

    /**
     * Function to check the validity of the earliest start date in step 4.
     */
    checkEarliestStartDate() {
        let result = "";
        if(this.objectApiName === 'Order') {
            if(this.workOrderEarliestStartDate && this.workOrderEarliestStartDate < this.record.fields.EffectiveDate.value) {
                result = "La date du rendez-vous ne peut pas être inférieure à la date de début de la commande";
            } 
        }
        if(this.calculatedDate > this.workOrderEarliestStartDate) {
            result = "La date du rendez-vous ne peut pas être inférieure à la date initialement définie";
        }         
        return result;
    }

    /**
     * Function to check the validity of the visiting start hour in step 4.
     */
    checkVisitingStartHour() {
        let result = "";
        if(this.workOrderVisitingStartHour >= this.workOrderVisitingEndHour) {
            result = "L'heure de début ne peut pas être supérieure ou égale à l'heure de fin";
        } 
        return result;
    }

    /**
     * Function to check the validity of the visiting start hour in step 4.
     */
    checkVisitingEndHour() {
        let result = "";
        if(this.workOrderVisitingEndHour <= this.workOrderVisitingStartHour) {
            result = "L'heure de fin ne peut pas être inférieure ou égale à l'heure de début";
        } 
        return result;
    }
    
    /**
     * Function to check all errors before each next step and before the creating of the Work Order.
     */
    checkForErrors() {
        let result = true;
        // check if on step 1 (worktype)
        if(this.currentStep === 'step-1') {
            if (this.selectedActionRDVTypeValue === "") {
                result = false;
                this.processErrorMessage("Vous devez sélectionner un type de rendez-vous", false);
            }
            if(this.rdvDebrifed && this.selectedActionRDVTypeValue === WORKTYPE_CONSTANTS.INTERVENTION){
                result = false;
                this.processErrorMessage("Vous ne pouvez pas créer un rendez-vous d'intervention!", false);
            }
        }

        // check if on step 2 (product)
        if(this.currentStep === 'step-2') {
            if (this.selectedProductRecords.length === 0 && 
                (this.selectedActionRDVTypeValue === WORKTYPE_CONSTANTS.CONTROLE 
                    || (this.selectedActionRDVTypeValue === WORKTYPE_CONSTANTS.INTERVENTION && !this.showNCPStep)
                    || (this.selectedActionRDVTypeValue === WORKTYPE_CONSTANTS.DIAGNOSTIC && !this.showNCPStep)
                )
            ) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner au minimum un produit", false);
            } else {        
                result = true;
            }
		}
		
        // check if on step 2a (PNC)
        if(this.currentStep === 'step-2a') {
            if (this.selectedNCPRecords.length === 0 && 
                (this.isDossierSAV || this.isCommandeSAV || (this.showNCPFilterButton && this.selectedProductRecords.length === 0))
            ) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner au minimum une non-conformité de produit", false);
            } else {        
                result = true;
            }
        }
        
        // check if on step 3 (constraints)
        if(this.currentStep === 'step-3') {
            const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
                .reduce((validSoFar, inputCmp) => {
                            inputCmp.reportValidity();
                            return validSoFar && inputCmp.checkValidity();
                }, true);
            if (allValid) {
                const earliestStartDateMsg = this.checkEarliestStartDate();
                const dueDateMsg = this.checkDueDate();
                const contactMsg = this.checkContact();
                if(contactMsg === "" && earliestStartDateMsg === "" && dueDateMsg === "") {
                    result = true;
                } else {
                    this.processErrorMessage(contactMsg + " " + earliestStartDateMsg + " " +dueDateMsg, false);
                    result = false;
                }
            } else {
                result = false;
            }
        }

        // check if on step 4 (skills)
        if(this.currentStep === 'step-4') {
            // Check if input fields are OK
            const allValid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
            }, true);
            
            if (allValid) {          
                // Get skills selected
                this.getSelectedSkillsRecords();      
                result = true;
            } else {
                result = false;
            }
        }

        // check if on step 5 (resources)
        if(this.currentStep === 'step-5') {          
            // Get the resources
            this.getSelectedResourcesRecords(); 
            result = true;
        }

        return result;
    }

    /**
     * Hide NCP step and clear all NCP selected
     */
    hideNCPStep() {
        console.log('hide NPC');
        this.showNCPButton = false;
        this.showNCPStep = false;
        this.selectedNCPRecords = [];  
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
        if(error.stack) {            
            console.error(error.stack);
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

    updateDueDate(){

        try {
            initDueDate(
                {earliestDate : this.workOrderEarliestStartDate, 
                workTypeParametersId : this.workTypeParametersId}
            )
            .then(result =>{
                if(result){
                    let d = new Date(result);
                    const padL = (nr, len = 2, chr = `0`) => `${nr}`.padStart(2, chr);
                    this.workOrderDueDate = [d.getFullYear(),
                        (padL(d.getMonth()+1)),
                        padL(d.getDate())].join('-')+' '+
                       [padL(d.getHours()),
                        padL(d.getMinutes()),
                        padL(d.getSeconds())].join(':');
                }
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
            
        } catch(error) {
            this.processErrorMessage(error.message);
            this.ncpData = undefined;
        }
    }
    /**
     * Function to call "checkForServiceAppointmentDebriefed" APEX method.
     */    
    checkForServiceAppointmentDebriefed(){
        
        try{
            checkForServiceAppointmentDebriefed({recordId: this.recordId}).
            then(result => {
                this.rdvDebrifed= result;
                console.log('log : '+this.rdvDebrifed);
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