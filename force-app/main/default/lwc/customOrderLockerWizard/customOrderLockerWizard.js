/* eslint-disable no-console */
import { LightningElement, api, track, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Apex class methods
import getAssetsFromRecordId from '@salesforce/apex/LWC_CustomOrderLockerWizard.getAssetsFromRecordId';
import getOrdersFromRecordId from '@salesforce/apex/LWC_CustomOrderLockerWizard.getOrdersFromRecordId';
import getServiceAppointments from '@salesforce/apex/LWC_CustomOrderLockerWizard.getServiceAppointments';
import lockOrder from '@salesforce/apex/LWC_CustomOrderLockerWizard.lockOrder';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

// Constants (Path, Fields displayed for each action/step)
const PATH_STEPS = [
    { label: 'Action sur les actifs', value: 'step-1', display: true },
    { label: 'Action sur les RDV', value: 'step-2', display: true },
    { label: 'Confirmation', value: 'step-3', display: true }
];
const ORDERS_COLUMNS = [
    { label: "Nom", fieldName: 'Name' },
    { label: "Statut", fieldName: 'Status'},
    { label: "Date d'activation", fieldName: 'ActivatedDate', type: 'date-local' }
];
const ASSETS_COLUMNS = [
    { label: "Produit", fieldName: 'Name' },
    { label: "Date d'installation", fieldName: 'InstallDate', type: 'date-local' }
];
const SERVICE_APPOINTMENT_COLUMNS = [
    { label: "N° de RDV", fieldName: 'appointmentNumber' },
    { label: "Objet", fieldName: 'subject'},
    { label: "Type de RDV", fieldName: 'workType'},
    {
        label: "Action à effectuer", fieldName: 'action', type: 'picklist', typeAttributes: {
            placeholder: '-- Aucune action --', options: [
                { label: 'Aucune action', value: 'Aucune action' },
                { label: 'Conservation du RDV', value: 'Conservation du RDV' },
                { label: 'Annulation du RDV', value: 'Annulation du RDV' }
            ] // list of all picklist options
            , value: { fieldName: 'action' } // default value for picklist
            , context: { fieldName: 'id' } // binding account Id with context variable to be returned back
        }
    }
];
const ASSET_CONFIRM_COLUMNS = [
    { label: "Produit", fieldName: 'Name' },
    { label: "Statut", fieldName: 'Status'},
    { label: "Date d'installation", fieldName: 'InstallDate', type: 'date-local' },
    { label: "Action", fieldName: 'Action'}
]
const ORDER_CONFIRM_COLUMNS = [
    { label: "Nom", fieldName: 'Name' },
    { label: "Statut", fieldName: 'Status'},
    { label: "Date d'activation", fieldName: 'ActivatedDate', type: 'date-local' }
]
const SERVICE_CONFIRM_COLUMNS = [
    { label: "N° de RDV", fieldName: 'appointmentNumber' },
    { label: "Objet", fieldName: 'subject'},
    { label: "Type de RDV", fieldName: 'workType'},
    { label: "Action", fieldName: 'action'}
];

export default class CustomOrderLockerWizard extends NavigationMixin(LightningElement) {
    // Current object api name
    @api objectApiName;
    // Current record's id
    @api recordId;
    // Current record
    @track record;

    // Setupped collections
    @track assetColumns = ASSETS_COLUMNS;
    @track orderColumns = ORDERS_COLUMNS;
    @track serviceAppointmentColumns = SERVICE_APPOINTMENT_COLUMNS;
    @track orderConfirmColumns = ORDER_CONFIRM_COLUMNS;
    @track assetConfirmColumns = ASSET_CONFIRM_COLUMNS;
    @track serviceConfirmColumns = SERVICE_CONFIRM_COLUMNS;

    // Data collections
    @track orderData = [];
    @track assetData = [];
    @track serviceAppointmentData = [];
    saSelectedData = [];
    orderConfirmData = [];
    assetConfirmData = [];
    saConfirmData = [];

    // Wizard Status
    @track currentStep = "step-1";
    @track steps = PATH_STEPS;
    @track showStep1Form = false;
    @track showStep2Form = false;
    @track showStep3Form = false;
    @track showStep4Form = false;
    @track showNextButton = true;
    @track showPreviousButton = false;
    @track showSubmitButton = true;

    // Event data
    @track showLoadingSpinner = false;
    @track error;

    // Non reactive variables
    selectedRecords = [];
    activeSummarySections = ['orderSummary', 'saSummary'];
     
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
     * Retrieving cancelling reasons
     */
    /*@wire(getOrdersFromRecordId, { recordId: '$recordId'})
    orders(orderList) {
        if (orderList.data) {
            var orderIdList = [];
            this.orderData = orderList.data;
            for(let order of orderList.data){          
                orderIdList.push(order.Id);
            }

            // Call APEX action to get every provider order from the customer order (parent)
            getServiceAppointments({ 
                orderIdList: orderIdList
            })
            .then(result => {
                if (result) {
                    this.serviceAppointmentData = result;
                    this.error = undefined;
                } else if (result.error) {
                    this.processErrorMessage(result.error);
                }
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        } else if (orderList.error) {
            this.processErrorMessage(result.error);
            this.orderData = undefined;
        }
    }*/

    /**
     * Retrieving cancelling reasons
     */
    @wire(getAssetsFromRecordId, { recordId: '$recordId'})
    assets(assetList) {
        if (assetList.data) {
            this.assetData = assetList.data;
            
            // Call APEX action to get every SA from the customer order (parent)
            getServiceAppointments({ 
                recordId: this.recordId
            })
            .then(result => {
                if (result) {
                    this.serviceAppointmentData = result;
                    this.error = undefined;
                    this.saSelectedData = [];
                    
                    for(let serviceAppointment of this.serviceAppointmentData){
                        console.log("serviceAppointment "+serviceAppointment);
                        this.saSelectedData.push(serviceAppointment);
                    }
                    this.saConfirmData = this.saSelectedData;
                } else if (result.error) {
                    this.processErrorMessage(result.error);
                }
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        } else if (assetList.error) {
            this.processErrorMessage(result.error);
            this.assetData = undefined;
        }
    }

    /* ========== EVENT METHODS ========== */

    /**
     * Handle a change on the "Asset" table
     * @param {object} event - Object of the Event.
     */
    handleSelectedAssetChange(event) {
        this.resetErrorMessage();
        // Get row selected
        const selectedRows = event.detail.selectedRows;
        // Init the array of assets
        this.selectedRecords = [];
        this.saSelectedData = [];
        this.assetConfirmData = [];  
        for(let row of selectedRows){  
            // Add asset selected in the array 
            var recapAsset = [];
            recapAsset.Id = row.Id;
            recapAsset.Name = row.Name;
            recapAsset.Status = row.Status;
            recapAsset.InstallDate = row.InstallDate;
            recapAsset.Action = 'Verrouillage';        
            this.selectedRecords.push(row.Id);
            this.assetConfirmData.push(recapAsset)

            // Add sa selected in the array 
            for(let serviceAppointment of this.serviceAppointmentData){     
                //if(row.Id === serviceAppointment.parentRecord){
                    this.saSelectedData.push(serviceAppointment);
                //}
            }    
        }
        this.saConfirmData = this.saSelectedData;
    }

    /**
     * Handle a change on the "Order" table
     * @param {object} event - Object of the Event.
     */
    handleSelectedOrderChange(event) {
        this.resetErrorMessage();
        // Get row selected
        const selectedRows = event.detail.selectedRows;
        // Init the array of products
        this.selectedRecords = [];
        this.saSelectedData = [];
        this.orderConfirmData = [];
        for(let row of selectedRows){      
            // Add order selected in the array 
            var recapOrder = [];
            recapOrder.Id = selectedRows[i].Id;
            recapOrder.Name = selectedRows[i].Name;
            recapOrder.Status = selectedRows[i].Status;
            recapOrder.ActivatedDate = selectedRows[i].ActivatedDate; 
            this.selectedRecords.push(selectedRows[i].Id);
            this.orderConfirmData.push(recapOrder);

            for(let serviceAppointment of this.serviceAppointmentData){       
                if(row.Id === serviceAppointment.parentRecord){
                    this.saSelectedData.push(serviceAppointment);
                }
            }    
        }
        this.saConfirmData = this.saSelectedData;
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
     * Handle a change on the picklist action of the "ServiceAppointment" table
     * @param {object} event - Object of the Event.
     */
    handleSAActionPicklistChanged(event) {
        event.stopPropagation();
        const dataRecieved = event.detail.data;     
        // Remove info's RDV changed of the array
        this.saConfirmData = this.saConfirmData.filter(item => item.id !== dataRecieved.context);
        // Add RDV changed in the array   
        for(let saSelected of this.saSelectedData){                     
            if (saSelected.id === dataRecieved.context) {
                let saObjectWithAction = {};
                saObjectWithAction.id = dataRecieved.context;
                saObjectWithAction.action = dataRecieved.value;
                saObjectWithAction.appointmentNumber = saSelected.appointmentNumber;
                saObjectWithAction.subject = saSelected.subject;
                saObjectWithAction.workType = saSelected.workType;
                saObjectWithAction.parentRecord = saSelected.parentRecord;
                saObjectWithAction.duration = saSelected.duration;
                this.saConfirmData.push(saObjectWithAction);
            } 
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
                break;
            case 'step-3':
                this.showStep3Form = true;
                this.showNextButton = false;
                this.showSubmitButton = true;
                break;
        }
    }

    /**
     * Function to lock orders and modify ServiceAppointment.
     */
    lockOrder(){
        this.showLoadingSpinner = true;
        this.resetErrorMessage(); 

        lockOrder({assetList: this.selectedRecords, orderId: this.recordId, saList: this.saConfirmData})
        .then(result => {
            this.showLoadingSpinner = false;
            // Show success messsage
            this.showNotification('Commande verrouillée', "La commande a été verrouillée avec succès", 'success');
            // Close the quick action
            this.closeQuickAction();
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

    /* ========== UTILITY METHODS ========== */  
    
    hasOrderData() {
        return this.orderData.length > 0;
    }
    
    hasAssetsData() {
        return this.assetData.length > 0;
    }

    /**
     * Function to check all errors before changing step.
     */
    checkForErrors() {
        let result = true;
        // check if on step 1 there is a selected asset
        if(this.currentStep === 'step-1') {
            if (this.selectedRecords.length === 0) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner au minimum une ligne.", false);
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

    get isOrderData() {
        return this.hasOrderData();
    }

    get isAssetsData() {
        return this.hasAssetsData();
    }

    get isServiceAppointmentsData() {
        let result = true;
        if (Object.keys(this.saSelectedData).length === 0) {
            result = false;
        } 
        return result;
    }
}