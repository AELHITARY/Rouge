/* eslint-disable no-console */
import { LightningElement, api, track, wire} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi'; 

// Apex class methods
import getSkills from '@salesforce/apex/LWC_ProductSkillSelector.getSkills';
import createProductSkillsRecord from '@salesforce/apex/LWC_ProductSkillSelector.createProductSkillsRecord';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class ProductSkillsSelector extends LightningElement {
    // Current object api name
    @api objectApiName;
    // Current record's id
    @api recordId;
    
    // Datatable
    @track skillsData = [];

    // Event data
    @track showLoadingSpinner = false;
    @track error;

    // non-reactive variables
    selectedSkillsRecords = [];
    
    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        
        // Init        
        this.showLoadingSpinner = true;
        this.skillsData = [];
    }

    /* ========== WIRED METHODS ========== */

    @wire(getRecord, { recordId: '$recordId', fields: ["Product.Name", "Product.Id"] })
    product;

    /**
     * Retrieving the skills of the product.
     * @param {string} recordId - Id of the record.
     */
    @wire(getSkills, { productId: '$recordId'})
    wiredGetSkills({ error, data }) {
        if (error) {
            this.processErrorMessage(error);
        } else if (data) {
            console.log("getSkills: "+data);
            // If skills, we set the table
            if (data.length !== 0) {
                this.skillsData = JSON.parse(JSON.stringify(data));            
            } 
            this.showLoadingSpinner = false;
        }
    }

    /* ========== EVENT METHODS ========== */

    /**
     * Generic method to update the variable defined as name in the field with the value
     * @param {object} event - Event object of the input field.
     */
    handleGenericChange(event){
        this[event.target.name] = event.target.value;
    }
    
    /**
     * Execute the process to check errors and to create product/skill links.
     * Executed when the user clicks on the "Enregistrer" button of the component.
     */
    handleCreateProductSkills() {
        console.log("handleCreateProductSkills");
        this.resetErrorMessage();
        this.showLoadingSpinner = true;
        // Check errors, continue if no errors
        if(this.checkForErrors()) {
            this.creatProductSkillRecords();
        } else {
            this.showLoadingSpinner = false;
        }
    }

    /* ========== GETTER METHODS ========== */

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

    /* ========== JS METHODS ========== */

    /**
     * Retrieving the skills using wire service
     */
    getSkillsbyProduct() {
        try {
            this.showLoadingSpinner = true;
            // Init
            this.skillsData = [];
            // Call APEX method to get skills by products
            if(this.selectedProductRecords) {
                getSkills({ productId: this.selectedProductRecords })
                .then(result => {
                    // If skills, we set the table
                    if (result.length !== 0) {
                        this.skillsData = JSON.parse(JSON.stringify(result));            
                    } else {
                        // Else, jump to the next step (step 3)
                        this.handleNext();
                    }
                    this.showLoadingSpinner = false;
                })
                .catch(error => {
                    this.processErrorMessage(error.body.message);
                });
            }
        } catch(error) {
            this.processErrorMessage(error.message);
        }
    }
    
    /**
     * Execute the process to create the link between the product and the skills.
     */
    creatProductSkillRecords() {
        // Call APEX action to create the WorkOrder
        createProductSkillsRecord({ productId: this.recordId, 
                                    skills: this.selectedSkillsRecords
                        }
        )
        .then(result => {
            if(result) {
                console.log("OK");
                this.showNotification('Compétences mises à jour', "La liste des compétences du produit a été mise à jour", 'success');
            } else {                
                this.showNotification('Erreur', "La liste des compétences n'a pas pu être mise à jour.", 'error');
            }
            this.showLoadingSpinner = false;
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
    }

    /**
     * Function to get skills selected by the user.
     */
    getSelectedSkillsRecords() {
        try {
            // Get the resource Id and values
            this.selectedSkillsRecords = Array.from(
                this.template.querySelectorAll('lightning-input')
            )
            .filter(element => element.value > 0) // Filter to get only if value > 0
            .map(element => { // Create an map of the skill
                var rObj = {
                    id: element.dataset.skillId, 
                    name: element.dataset.skillName, 
                    value: element.value
                };
                return rObj;
            });
            console.log(this.selectedSkillsRecords);
        } catch(error) {
          this.processErrorMessage(error.message);
        }
    }
    
    /**
     * Function to check all errors before the creating of the Work Order.
     */
    checkForErrors() {
        let result = true;

        // check skills
        // Check if input fields are OK
        const allValid = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
        }, true);
        
        if (allValid) {             
            // Get the skills                        
            this.getSelectedSkillsRecords();
            result = true;
        } else {
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
}