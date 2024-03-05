import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

//Apex class method
import renderDocumentPDF from '@salesforce/apex/LWC_ExportAccountingReportPDF.renderDocumentPDF';
import getEntityAccounts from '@salesforce/apex/LWC_ExportAccountingReportPDF.getEntityAccounts';
import generateJsonObject from '@salesforce/apex/LWC_ExportAccountingReportPDF.generateJsonObject';
import getBankAccounts from '@salesforce/apex/LWC_ExportAccountingReportPDF.getBankAccounts';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class ExportAccountingReportPDF extends NavigationMixin(LightningElement) {
    
    @track showLoadingSpinner = false;
    @track showLoadingSpinnerStep2 = false;
    @track error;
    @track currentStep = "step-1";
    @track showStep1Form = true;
    @track showStep2Form = false;
    @track isBankReport = false;
    @track showStepFinalForm = false;
    //@track showPreviousButton = false;

    serviceEntityId;
    serviceEntityName;
    serviceEntity;
    exportType;
    startDate = this.firstDayOfCurrentMonth;
    endDate = this.todaysDate;
    bankAccountsSelected = []; 

    @track serviceEntities = [];
    @track serviceEntitiesLoaded = false;
    @track bankAccounts = [];
    @track bankAccountsLoaded = false;

    // List of report Types availables
    get exportTypes() {
        return [
            { label: 'Journal de banque', value: 'Journal des banques' },
            { label: 'Journal des OD', value: 'Journal des OD' },
            { label: 'Journal des ventes', value: 'Journal des ventes' },
            { label: 'Non collecté', value: 'Non collecté' },
            
        ];
    }

    get filterServiceEntity(){
        return [
            { label: 'Dépôts actifs', value: 'Dépôts actifs' },
            { label: 'Dépôts fermés depuis moins d\'un an', value: 'Dépôts fermés depuis moins d\'un an' }
        ];
    }

    get steps(){
        return [
            { label: 'Configuration de l\'export', value: 'step-1', display: true },
            { label: 'Création du rapport', value: 'step-2', display: true }
        ];
    }

    @wire(getEntityAccounts, {})
    accounts(result){
        if(result.data){
            for(let key in result.data){
                this.serviceEntities.push({ label: key, value: result.data[key] });
            }
            this.serviceEntitiesLoaded = true;
        }
        else if(result.error){
            this.processErrorMessage(result.error);
        }
    }

    searchBankAccounts(){
        getBankAccounts({serviceEntityId : this.serviceEntityId, startDate : this.startDate, endDate : this.endDate})
            .then(result => {
                if(result){
                    for(let key in result){
                        this.bankAccounts.push({ label: key, value: result[key] });
                    }                   
                    if(this.bankAccounts.length == 0){
                        this.processErrorMessage("Aucun compte bancaire n'est visible depuis le dépôt sélectionné. Veuillez sélectionner un autre dépôt.");                       
                    }
                    else{
                        this.bankAccountsLoaded = true;
                    }                   
                }
            })
        .catch(error => {
            this.processErrorMessage(error);
        });
    }

    /**
     * Function to execute the Merkure API to generate the PDF.
     */
    generatePDF(){
        this.showLoadingSpinner = true;
        // Call APEX method to execute the API
        generateJsonObject({exportType : this.exportType, serviceEntityId : this.serviceEntityId, serviceEntityName : this.serviceEntityName, startDate : this.startDate,
            endDate : this.endDate, bankAccounts : this.bankAccountsSelected })
            .then(result => {
                if(result){
                    this.showLoadingSpinner = false;
                    this.showLoadingSpinnerStep2 = true;
                    this.generatePDFStep2(result);
                }
            })
        .catch(error => {
            this.processErrorMessage(error);
        });
    }

    generatePDFStep2(result){
        renderDocumentPDF({exportType : this.exportType, serviceEntityId : this.serviceEntityId, serviceEntityName : this.serviceEntityName, startDate : this.startDate,
                        endDate : this.endDate, jsonObject : result})
        .then(resultId => {
            if (resultId) {   
                // Show success messsage
                this.showNotification('Export PDF', "Le document a été généré et sauvegardé avec succès", 'success');
                // Open PDF Preview
                this.viewPdf(resultId);
                this.showStepFinalForm = true;
            }
            this.showLoadingSpinnerStep2 = false;
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
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

    /* ========== EVENT METHODS ========== */

    handleSave() {
        // Reset the error
        this.resetErrorMessage();
        // Check value of the input
        if(this.checkForErrors()){
            this.showStep1Form = false;
            if(this.isBankReport && this.currentStep == "step-1"){
                this.showStep2Form = true;
                //this.showPreviousButton = true;
                this.searchBankAccounts();
            }
            else{
                this.generatePDF();
                //this.showPreviousButton = false;
            }
            this.currentStep = "step-2";           
        }    
    }

    handlePrevious() {
        this.resetErrorMessage();
        this.currentStep = "step-1";
        this.showStep1Form = true;
        this.showStep2Form = false;
        //this.showPreviousButton = false;
        this.showStepFinalForm = false;
        this.bankAccounts = [];
        this.bankAccountsSelected = [];
        this.bankAccountsLoaded = false;
    }

    handleNewExport(){
        // Reset the error
        this.resetErrorMessage();
        this.currentStep = "step-1";
        this.showStep1Form = true;
        this.startDate = this.firstDayOfCurrentMonth;
        this.endDate = this.todaysDate;
        this.serviceEntityId = null;
        this.serviceEntityName = null;
        this.serviceEntity = "";
        this.exportType= null;
        this.showStepFinalForm = false;
        this.showStep2Form = false;
        this.bankAccounts = [];
        this.bankAccountsSelected = [];
        this.bankAccountsLoaded = false;
    }

    /**
     * Function to check all errors before next step and before the creating the report
     */
    checkForErrors() {
        let result = true;
        // Check if input fields are OK
        // Check special rules
        if(this.isNullOrWhitespace(this.serviceEntityId)) {
            this.processErrorMessage('L\'information "Dépôt" est obligatoire !', false);
            result = false;
        } 
        if(this.isNullOrWhitespace(this.exportType)) {
            this.processErrorMessage('L\'information "Type d\'export" est obligatoire !', false);
            result = false;
        }
        if(this.isNullOrWhitespace(this.startDate)) {
            this.processErrorMessage('L\'information "Date de début d\'observation" est obligatoire !', false);
            result = false;
        } 
        if(this.startDate > this.todaysDate) {
            this.processErrorMessage('La date de début d\'observation doit être inférieure ou égale à la date du jour !', false);
            result = false;
        }
        if(this.endDate < this.startDate) {
            this.processErrorMessage('La date de fin d\'observation doit être supérieure ou égale à la date de début d\'observation !', false);
            result = false;
        }
        if(this.endDate > this.todaysDate) {
            this.processErrorMessage('La date de fin d\'observation doit être inférieure ou égale à la date du jour !', false);
            result = false;
        }        
        if(this.isBankReport && this.currentStep == "step-2" && this.bankAccountsSelected.length == 0) {
            this.processErrorMessage('Au moins un compte bancaire doit être sélectionné !', false);
            result = false;
        } 
        
        return result;
    }

    /**
     * Function to check if the value is null.
     */
    isNullOrWhitespace( input ) {
        return  !input || input.toString().replace(/\s/g, '').length < 1;
    }
    

    /**
     * Handle a change on the "Date de début d'observation" field 
     * @param {object} event - Object of the Event.
     */	
    handleExportTypeChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.exportType = event.target.value;
        if(this.exportType == "Journal des banques"){
            this.isBankReport = true;
        }
        else{
            this.isBankReport = false;
        }
    }

    /**
     * Handle a change on the "Date de début d'observation" field 
     * @param {object} event - Object of the Event.
     */	
    handleStartDateChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.startDate = event.target.value;     
    }

    /**
     * Handle a change on the "Date de fin d'observation" field 
     * @param {object} event - Object of the Event.
     */	
    handleEndDateChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.endDate = event.target.value;     
    }

    /**
     * Handle a change on the "Liste des dépots" field 
     * @param {object} event - Object of the Event.
     */
    handleServiceEntityChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        let values = event.target.value.split('/');
        this.serviceEntityId = values[0];
        this.serviceEntityName = values[1];
        this.serviceEntity = event.target.value;
    }

    /**
     * Handle a change on the "Compte bancaire" field 
     * @param {object} event - Object of the Event.
     */
    handleChangeBankAccount(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.bankAccountsSelected = event.target.value;
    }

    /* ========== GETTER METHODS ========== */

    get todaysDate() {
        return new Date().toISOString().slice(0, 10);
    }

    get firstDayOfCurrentMonth() {
        var firstDateOfMonth = new Date();
        firstDateOfMonth.setDate(1);
        return firstDateOfMonth.toISOString().slice(0, 10);
    }

    /**
     * Reset the error message.
     */
    resetErrorMessage() {
        this.error = "";
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

}