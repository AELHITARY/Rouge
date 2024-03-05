/* eslint-disable no-console */
import { LightningElement, api, track, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';

// Field & Object Metadata
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import CHANTIER_OBJECT from '@salesforce/schema/Chantier__c';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import QUOTE_OBJECT from '@salesforce/schema/Quote';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import CIVILITE_FIELD from '@salesforce/schema/Account.Salutation';
import ORIGINE_FIELD from '@salesforce/schema/Account.AccountSource';
import ORIGINECALL_FIELD from '@salesforce/schema/Account.accountCallSource__c';
import TYPEHABITATION_FIELD from '@salesforce/schema/Chantier__c.typeHabitation__c';
import TYPERESIDENCE_FIELD from '@salesforce/schema/Chantier__c.typeResidence__c';
import TYPEOPP_FIELD from '@salesforce/schema/Opportunity.Type';
import MODEFINANCEMENT_FIELD from '@salesforce/schema/Quote.modeFinancement__c';
import TYPECONTRAT_FIELD from '@salesforce/schema/Quote.typeContrat__c';

// Apex class methods
import saveAllObjects from '@salesforce/apex/LWC_CreateGlobalWizard.saveAllObjects';
import getAccount from '@salesforce/apex/LWC_CreateGlobalWizard.getAccount';
import getChantier from '@salesforce/apex/LWC_CreateGlobalWizard.getChantier';
import getOpportunity from '@salesforce/apex/LWC_CreateGlobalWizard.getOpportunity';
import getQuote from '@salesforce/apex/LWC_CreateGlobalWizard.getQuote';
import getQuoteCPQ from '@salesforce/apex/LWC_CreateGlobalWizard.getQuoteCPQ';
import getSourceRef from '@salesforce/apex/LWC_CreateGlobalWizard.getSourceRef';


// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

// Constants (Path, Fields displayed for each action/step)
const PATH_STEPS = [
    { label: 'Sélection du type', value: 'step-1', display: true },
    { label: 'Compte', value: 'step-2', display: true },
    { label: 'Chantier', value: 'step-3', display: true },
    { label: 'Projet', value: 'step-4', display: true },
    { label: 'Devis', value: 'step-5', display: true },
    { label: 'Confirmation', value: 'step-6', display: true }
];
const PATH_STEPS_CPQ = [
    { label: 'Sélection du type', value: 'step-1', display: true },
    { label: 'Compte', value: 'step-2', display: true },
    { label: 'Chantier', value: 'step-3', display: true },
    { label: 'Projet', value: 'step-4', display: true },
    { label: 'Devis CPQ', value: 'step-5', display: true },
    { label: 'Confirmation', value: 'step-6', display: true }
];

const OBJECTTYPE_CONSTANTS = { 
    ACCOUNT: 'Compte', 
    CHANTIER: 'Chantier',
    OPPORTUNITY: 'Projet', 
    QUOTE: "Devis", 
    QUOTE_CPQ: "Devis CPQ" 
};

export default class CreateGlobalWizard extends NavigationMixin(LightningElement) {
    // Current object api name
    @api recordId;
    @api objectApiName;

    // CPQ Mode or not
    @api createQuoteCPQ = false;

    // User fields
    @track prfName;

    // Account fields
    @track accId;
    @track accName;
    @track civility;
    @track firstName;
    @track lastName;
    @track accStreet;
    @track accPostalcode;
    @track accState;
    @track accCity;
    @track accComplementAddress;
    @track etage;
    @track accCountry;
    @track email;
    @track telDomicile;
    @track telMobile;
    @track accLongitude;
    @track accLatitude;
    @track origine;
    @track origineCall;

    // Chantier fields
    @track chaId;
    @track chaName;
    @track chaStreet;
    @track chaPostalcode;
    @track chaState;
    @track chaCity;
    @track chaComplementAddress;
    @track typeHabitation;
    @track typeResidence;
    @track nbPortesFenetres;
    @track chaLongitude;
    @track chaLatitude;

    // Opportunity fields
    @track oppId;
    @track oppName;
    @track type;
    @track datePrevisionelleSignature;
    @track opeId
    @track opeName
    @track campagneCall

    // Quote fields
    @track quoteId;
    @track quoteName;
    @track dateDevis;
    @track montant;
    @track modeFinancement;
    @track typeContrat;

    // Quote CPQ fields
    @track quoteFinancingMethodId;
    @track quoteFinancingMethodName;
    @track quoteTermsAndConditionsId;
    @track quoteTermsAndConditionsName;
    @track quoteSourceId;
    @track quoteSourceName;

    // Data collections
    @track typeData = [];

    // Wizard Status
    @track currentStep = "step-1";
    @track steps = PATH_STEPS;
    @track showStep1Form = false;
    @track showStep2Form = false;
    @track showStep3Form = false;
    @track showStep4Form = false;
    @track showStep5Form = false;
    @track showStep6Form = false;
    @track showNextButton = true;
    @track showPreviousButton = false;
    @track showSubmitButton = true;
    @track isCall = false;
    @track isSales = false;
    @track isAdmin = false;
    activeSummarySections = ['accountSummary', 'chantierSummary', 'opportunitySummary', 'quoteSummary'];

    // Event data
    @track showLoadingSpinner = false;
    @track error;

    // Filters for lookups (constants)
    @track accFilter;
    @track chaFilter;
    @track oppFilter;
    @track quoFilter;
    @track quoCPQFilter;

    // Non reactive variables
    selectedActionTypeValue = OBJECTTYPE_CONSTANTS.ACCOUNT;
    selectedRecords = [];
     
    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();

        // Init body
        this.updateWizardBody();
        this.updateDisplayedSteps();

        // Init default field values and filters for lookups
        this.accFilter = 'RecordType.DeveloperName =\'PersonalAccount\'';
        this.dateDevis = new Date().toISOString().slice(0, 10);
        this.type = 'Nouveau';
    }

    /* ========== WIRED METHODS ========== */

    /**
     * Retrieving the objects information.
     * @param {string} objectApiName - API Name of the object.
     */

    @wire(getObjectInfo,  { objectApiName: ACCOUNT_OBJECT })
    accountObjectInfo;
    @wire(getObjectInfo,  { objectApiName: CHANTIER_OBJECT })
    chantierObjectInfo;
    @wire(getObjectInfo,  { objectApiName: OPPORTUNITY_OBJECT })
    opportunityObjectInfo;
    @wire(getObjectInfo,  { objectApiName: QUOTE_OBJECT })
    quoteObjectInfo;

    /**
     * Retrieving the picklist values field.
     * @param {string} recordTypeId - Id of the record type of the Id.
     * @param {string} fieldApiName - API Name of the field.
     */
    @wire(getPicklistValues, { recordTypeId: '$accountObjectInfo.data.defaultRecordTypeId', fieldApiName: CIVILITE_FIELD })
    salutationPicklistValues;
    @wire(getPicklistValues, { recordTypeId: '$accountObjectInfo.data.defaultRecordTypeId', fieldApiName: ORIGINE_FIELD })
    originePicklistValues;
    @wire(getPicklistValues, { recordTypeId: '$accountObjectInfo.data.defaultRecordTypeId', fieldApiName: ORIGINECALL_FIELD })
    origineCallPicklistValues;
    @wire(getPicklistValues, { recordTypeId: '$chantierObjectInfo.data.defaultRecordTypeId', fieldApiName: TYPEHABITATION_FIELD })
    typeHabitationPicklistValues;
    @wire(getPicklistValues, { recordTypeId: '$chantierObjectInfo.data.defaultRecordTypeId', fieldApiName: TYPERESIDENCE_FIELD })
    typeResidencePicklistValues;
    @wire(getPicklistValues, { recordTypeId: '$opportunityObjectInfo.data.defaultRecordTypeId', fieldApiName: TYPEOPP_FIELD })
    typeOppPicklistValues;
    @wire(getPicklistValues, { recordTypeId: '$quoteObjectInfo.data.defaultRecordTypeId', fieldApiName: MODEFINANCEMENT_FIELD })
    modeFinancementPicklistValues;
    @wire(getPicklistValues, { recordTypeId: '$quoteObjectInfo.data.defaultRecordTypeId', fieldApiName: TYPECONTRAT_FIELD })
    typeContratPicklistValues;
    
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [PROFILE_NAME_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           this.error = error ; 
        } else if (data) {
            // Get profile name, and allow permissions/visibility
            this.prfName = data.fields.Profile.value.fields.Name.value;   
            if(this.prfName === 'Administrateur système'){
                this.isCall = true;
                this.isSales = true;
            } else if(this.prfName === 'K/K - Assistante Call' || this.prfName === 'K/K - DC' ||
                    this.prfName === 'K/K - Superviseur' || this.prfName === 'K/K - TA' ||
                    this.prfName === 'K/K - TA/Entrant' || this.prfName === 'K/K - TA/Sortant'){
                this.isCall = true;
                this.isSales = false;
            } else {
                this.isCall = false;
                this.isSales = true;
            }
            // Update Steps
            if(this.createQuoteCPQ) {
                this.steps[4].label = 'Devis CPQ';
            } 
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
                // If the step is display, display it else jump in the next step (or 2, 3 steps after)
                if(this.steps[currIndex+1].display === true) {
                    currentStage = this.steps[currIndex+1].value;
                } else if(this.steps[currIndex+2].display === true) {
                    currentStage = this.steps[currIndex+2].value;
                } else if(this.steps[currIndex+3].display === true) {
                    currentStage = this.steps[currIndex+3].value;
                } else {
                    currentStage = this.steps[currIndex+4].value;
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
            // If the step is display, display it else jump in the previous step (or 2, 3 steps before)
            if(this.steps[currIndex-1].display === true) {
                currentStage = this.steps[currIndex-1].value;
            } else if(this.steps[currIndex-2].display === true) {
                currentStage = this.steps[currIndex-2].value;
            } else if(this.steps[currIndex-3].display === true) {
                currentStage = this.steps[currIndex-3].value;
            } else {
                currentStage = this.steps[currIndex-4].value;
            }
            this.currentStep = currentStage;
        } 
        // Update the form to show the previous step
        this.updateWizardBody();
    } 

    /**
     * Function executed when a user click on "Enregistrer" button.
     */	
    handleSave() {
        // Reset the error
        this.resetErrorMessage();
        // Check fields and save if it's OK
        if(this.checkAddressFields()) {
            this.showLoadingSpinner = true;
            // Call APEX to save data
            // Create map parameters
            const accountParameters = {
                accId: this.accId,
                firstName: this.firstName,
                lastName: this.lastName,
                civility: this.civility,
                accStreet: this.accStreet,
                accPostalcode: this.accPostalcode,
                accState: this.accState,
                accCity: this.accCity,
                accComplementAddress: this.accComplementAddress,
                etage: this.etage,
                accCountry: this.accCountry,
                email: this.email,
                telDomicile: this.telDomicile,
                telMobile: this.telMobile,
                accLongitude: this.accLongitude,
                accLatitude: this.accLatitude,
                source: this.origine,
                sourceCall: this.origineCall
            };
            const chantierParameters = {
                chaId: this.chaId,
                chaStreet: this.chaStreet,
                chaPostalcode: this.chaPostalcode,
                chaState: this.chaState,
                chaCity: this.chaCity,
                chaComplementAddress: this.chaComplementAddress,
                typeHabitation: this.typeHabitation,
                typeResidence: this.typeResidence,
                nbPortesFenetres: this.nbPortesFenetres,
                chaLongitude: this.chaLongitude,
                chaLatitude: this.chaLatitude
            };
            const opportunityParameters = {
                oppId: this.oppId,
                type: this.type,
                datePrevisionelleSignature: this.datePrevisionelleSignature,
                opeId: this.opeId,
                opeName: this.opeName,
                campagneCall: this.campagneCall
            };
            const quoteParameters = {
                quoteId: this.quoteId,
                dateDevis: this.dateDevis,
                montant: this.montant,
                modeFinancement: this.modeFinancement,
                typeContrat: this.typeContrat
            };
            const quoteCPQParameters = {
                quoteId: this.quoteId,
                dateDevis: this.dateDevis,
                montant: this.montant,
                source: this.quoteSourceId,
                financingMethod: this.quoteFinancingMethodId,
                termsAndConditions: this.quoteTermsAndConditionsId
            };
            const objectsParameters = {
                hasChantier: this.hasChantier,
                hasOpportunity: this.hasOpportunity,
                hasQuote: this.hasQuote,
                createQuoteCPQ: this.createQuoteCPQ
            };

            // Call for the Aura method
            saveAllObjects({accParams : accountParameters, chaParams : chantierParameters, 
                            oppParams : opportunityParameters, quoParams : quoteParameters,
                            quoCPQParams : quoteCPQParameters, objectsParams : objectsParameters
            })
            .then(result => {
                this.showNotification("Création des objets", "Les objets ont bien été créés", 'success');
                console.log('Succes');
                // Reload page, go back to step1, and empty fields
                this.reloadPage();
                this.showLoadingSpinner = false;
                // View the detail of the record.
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        }
    }

    /**
     * Handle the selected action value.
     * Executed when the user change the action on step 1.
     * @param {object} event - Event object of the "onchanged" of the radio group.
     */
    handleTypeObjectChange(event) {
        this.selectedActionTypeValue = event.detail.value;
        this.updateDisplayedSteps();
    }

    /**
     * Handle a change on the "Origine" field for the "Select a type" step
     * @param {object} event - Event object of the input field.
     */
    handleOrigineChange(event) {
        this.resetErrorMessage();
        this.origine = event.detail.value;
    }

    /**
     * Handle a change on the "Origine call" field for the "Select a type" step
     * @param {object} event - Event object of the input field.
     */
    handleOrigineCallChange(event) {
        this.resetErrorMessage();
        this.origineCall = event.detail.value;
    }

    /**
     * Handle a change on the "Account lookup" field for the "Account" step
     * @param {object} event - Event object of the input field.
     */
    handleAccountLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.accId = selection[0].id;
            this.accName = selection[0].title;
            this.autoFillAccountFields(selection[0].id);            
        } else {
            this.accId = "";
            this.accName = "";            
        }
        // Update filters for chantier,opportunity,quote lookups
        this.updateFilters();
    }

    /**
     * Handle a change on the "Chantier lookup" field for the "Chantier" step
     * @param {object} event - Event object of the input field.
     */
    handleChantierLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.chaId = selection[0].id;
            this.chaName = selection[0].title;
            this.autoFillChantierFields(selection[0].id);
        } else {
            this.chaId = "";
            this.chaName = "";
        }
        this.updateFilters();
    }

    /**
     * Handle a change on the "Opportunity lookup" field for the "Opportunity" step
     * @param {object} event - Event object of the input field.
     */
    handleOpportunityLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.oppId = selection[0].id;
            this.oppName = selection[0].title;
            this.autoFillOpportunityFields(selection[0].id);
        } else {
            this.oppId = "";
            this.oppName = "";
        }
        this.updateFilters();
    }

    /**
     * Handle a change on the "Quote lookup" field for the "Quote" step
     * @param {object} event - Event object of the input field.
     */
    handleQuoteLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.quoteId = selection[0].id;
            this.quoteName = selection[0].title;
            this.autoFillQuoteFields(selection[0].id);
        } else {
            this.quoteId = "";
            this.quoteName = "";
        }
    }

    /**
     * Handle a change on the "Quote CPQ lookup" field for the "Quote" step
     * @param {object} event - Event object of the input field.
     */
    handleQuoteCPQLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.quoteId = selection[0].id;
            this.quoteName = selection[0].title;
            this.autoFillQuoteCPQFields(selection[0].id);
        } else {
            this.quoteId = "";
            this.quoteName = "";
        }
    }

    /**
     * Function executed when a user select an address by the autcompletion component on the "Account" step.
     * @param {object} event - Object of the Event.
     */	
    handleAccountSelectedEvent(event){
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.accCity = event.detail.city;
        this.accStreet = event.detail.street;
        this.accPostalcode = event.detail.zip;
        this.accState = event.detail.state;
        this.accCountry = event.detail.country;
        this.accLongitude = event.detail.longitude;
        this.accLatitude = event.detail.latitude;

        // Define the same address for Chantier object
        this.handleChantierSelectedEvent(event);
    }

    /**
     * Function executed when a user select an address by the autcompletion component on the "Account" step.
     * @param {object} event - Object of the Event.
     */	
    handleInputAccAddressChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        //console.log('event.detail : '+JSON.stringify(event.detail));
        this.accCity = event.detail.city;
        this.accStreet = event.detail.street;
        this.accPostalcode = event.detail.postalCode;
        this.accState = event.detail.province;
        this.accCountry = event.detail.country;

        // Define the same address for Chantier object
        this.handleInputChaAddressChange(event);
    }

    /**
     * Function executed when a user select an address by the autcompletion component on the "Chantier" step.
     * @param {object} event - Object of the Event.
     */	
    handleChantierSelectedEvent(event){
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.chaCity = event.detail.city;
        this.chaStreet = event.detail.street;
        this.chaPostalcode = event.detail.zip;
        this.chaState = event.detail.state;
        this.chaCountry = event.detail.country;
        this.chaLongitude = event.detail.longitude;
        this.chaLatitude = event.detail.latitude;
    }

    /**
     * Function executed when a user select an address by the autcompletion component on the "Chantier" step.
     * @param {object} event - Object of the Event.
     */	
    handleInputChaAddressChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        console.log('result : '+JSON.stringify(event.detail));
        this.chaCity = event.detail.city;
        this.chaStreet = event.detail.street;
        this.chaPostalcode = event.detail.postalCode;
        this.chaState = event.detail.province;
        this.chaCountry = event.detail.country;
    }

    /**
     * Handle a change on the "Complement adresse" field for the "Account" step
     * @param {object} event - Object of the Event.
     */	
    handleAccComplementAddressChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.accComplementAddress = event.target.value; 
        
        // Define the same address for Chantier object
        this.handleChaComplementAddressChange(event);
    }

    /**
     * Handle a change on the "Civilité" field for the "Account" step
     * @param {object} event - Object of the Event.
     */	
    handleCiviliteChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.civility = event.target.value;     
    }

    /**
     * Handle a change on the "First Name" field for the "Account" step
     * @param {object} event - Object of the Event.
     */	
    handleFirstNameChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.firstName = event.target.value;     
    }

    /**
     * Handle a change on the "Last Name" field for the "Account" step
     * @param {object} event - Object of the Event.
     */	
    handleLastNameChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.lastName = event.target.value;     
    }

    /**
     * Handle a change on the "Etage" field for the "Account" step
     * @param {object} event - Object of the Event.
     */	
    handleEtageChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.etage = event.target.value;     
    }

    /**
     * Handle a change on the "Email" field for the "Account" step
     * @param {object} event - Object of the Event.
     */	
    handleEmailChange(event) {
        // Reset the error
        this.resetErrorMessage();
        console.log('email');
        // Define fields
        this.email = event.target.value;     
    }

    /**
     * Handle a change on the "Tel Domicile" field for the "Account" step
     * @param {object} event - Object of the Event.
     */	
    handleTelDomicileChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.telDomicile = event.target.value;     
    }

    /**
     * Handle a change on the "Tel Mobile" field for the "Account" step
     * @param {object} event - Object of the Event.
     */	
    handleTelMobileChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.telMobile = event.target.value;     
    }

    /**
     * Handle a change on the "Complement adresse" field for the "Chantier" step
     * @param {object} event - Object of the Event.
     */	
    handleChaComplementAddressChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.chaComplementAddress = event.target.value;   
    }

    /**
     * Handle a change on the "Type d'habitation" field for the "Chantier" step
     * @param {object} event - Object of the Event.
     */	
    handleTypeHabitationChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.typeHabitation = event.target.value;     
    }

    /**
     * Handle a change on the "Type résidence" field for the "Chantier" step
     * @param {object} event - Object of the Event.
     */	
    handleTypeResidenceChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.typeResidence = event.target.value;     
    }

    /**
     * Handle a change on the "Nombre portes fenetres" field for the "Chantier" step
     * @param {object} event - Object of the Event.
     */	
    handleNbPortesFenetresChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.nbPortesFenetres = event.target.value;     
    }

    /**
     * Handle a change on the "Type" field for the "Opportunity" step
     * @param {object} event - Object of the Event.
     */	
    handleTypeChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.type = event.target.value;     
    }

    /**
     * Handle a change on the "Date prévisionelle de signature" field for the "Opportunity" step
     * @param {object} event - Object of the Event.
     */	
    handleDatePrevisionelleSignatureChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.datePrevisionelleSignature = event.target.value;     
    }

    /**
     * Handle a change on the "Opération" lookup field for the "Opportunity" step
     * @param {object} event - Event object of the input field.
     */
    handleOperationLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.opeId = selection[0].id;
            this.opeName = selection[0].title;
            this.autoFillOpportunityFields(selection[0].id);
        } else {
            this.opeId = "";
            this.opeName = "";
        }
    }

    /**
     * Handle a change on the "Campagne (Call)" field for the "Opportunity" step
     * @param {object} event - Object of the Event.
     */	
    handleCampagneCallChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.campagneCall = event.target.value;     
    }

    /**
     * Handle a change on the "Date de devis" field for the "Quote" step
     * @param {object} event - Object of the Event.
     */	
    handleDateDevisChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.dateDevis = event.target.value;     
    }

    /**
     * Handle a change on the "Montant" field for the "Quote" step
     * @param {object} event - Object of the Event.
     */	
    handleMontantChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.montant = event.target.value;     
    }

    /**
     * Handle a change on the "Mode de financement" field for the "Quote" step
     * @param {object} event - Object of the Event.
     */	
    handleModeFinancementChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.modeFinancement = event.target.value;     
    }

    /**
     * Handle a change on the "Type de contrat" field for the "Quote" step
     * @param {object} event - Object of the Event.
     */	
    handleTypeContratChange(event) {
        // Reset the error
        this.resetErrorMessage();
        // Define fields
        this.typeContrat = event.target.value;     
    }
    
    /**
     * Handle a change on the "Mode de finacement" field 
     * @param {object} event - Object of the Event.
     */
     handleFinancingMethodLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.quoteFinancingMethodId = selection[0].id;
            this.quoteFinancingMethodName = selection[0].title;
        } else {
            this.quoteFinancingMethodId = "";
            this.quoteFinancingMethodName = "";
        }
    }
    
    /**
     * Handle a change on the "Source" field 
     * @param {object} event - Object of the Event.
     */
     handleSourceLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.quoteSourceId = selection[0].id;
            this.quoteSourceName = selection[0].title;
        } else {
            this.quoteSourceId = "";
            this.quoteSourceName = "";
        }
    }
    
    /**
     * Handle a change on the "CGV" field 
     * @param {object} event - Object of the Event.
     */
     handleTermsAndConditionsLookupChange(event) {
        this.resetErrorMessage();
        const selection = event.target.getSelection();
        // Update the variable
        if(selection.length !== 0) {
            this.quoteTermsAndConditionsId = selection[0].id;
            this.quoteTermsAndConditionsName = selection[0].title;
        } else {
            this.quoteTermsAndConditionsId = "";
            this.quoteTermsAndConditionsName = "";
        }
    }

    /* ========== JS METHODS ========== */
    
    /**
     * Function executed when the user click on the Previous/Next button to update the form.
     */
    updateWizardBody() {
        this.showStep1Form = false;
        this.showStep2Form = false;
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
                this.getSourceReferencial();
                this.showStep2Form = true;
                break;
            case 'step-3':
                this.showStep3Form = true;
                break;
            case 'step-4':
                this.showStep4Form = true;
                break;
            case 'step-5':
                this.showStep5Form = true;
                break;
            case 'step-6':
                this.showStep6Form = true;
                this.showNextButton = false;
                this.showSubmitButton = true;
                break;
        }
    }

    /**
     * Function executed when the user select the object to create to display the correct steps.
     */
    updateDisplayedSteps(){
        if(this.selectedActionTypeValue === OBJECTTYPE_CONSTANTS.ACCOUNT){
            this.steps[2].display = false;
            this.steps[3].display = false;
            this.steps[4].display = false;
        } else if(this.selectedActionTypeValue === OBJECTTYPE_CONSTANTS.CHANTIER){
            this.steps[2].display = true;
            this.steps[3].display = false;
            this.steps[4].display = false;
        } else if(this.selectedActionTypeValue === OBJECTTYPE_CONSTANTS.OPPORTUNITY){
            this.steps[2].display = true;
            this.steps[3].display = true;
            this.steps[4].display = false;
        } else if(this.selectedActionTypeValue === OBJECTTYPE_CONSTANTS.QUOTE){
            this.steps[2].display = true;
            this.steps[3].display = true;
            this.steps[4].display = true;
        }
    }

    getSourceReferencial(){
        if(this.createQuoteCPQ && this.origine) {
            try {
                this.showLoadingSpinner = true;
    
                // Call APEX method to get source infos
                getSourceRef({ sourceName: this.origine})
                .then(result => {
                    if (result) {
                        this.quoteSourceId = result.Id;
                        this.quoteSourceName = result.Name;
                    } else {
                        this.quoteSourceId = "";
                        this.quoteSourceName = "";
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
    }

    /**
     * Retrieving the selected account in the lookup field from the database
     */
    autoFillAccountFields(accId) {
        try {
            this.showLoadingSpinner = true;

            // Call APEX method to get account infos
            getAccount({ accId: accId})
            .then(result => {
                if (result) {
                    console.log('result : '+result);
                    // Selected account infos update the form variables
                    this.civility = result.Salutation;
                    this.firstName = result.FirstName;
                    this.lastName = result.LastName;
                    this.accStreet = result.PersonMailingStreet;
                    this.accPostalcode = result.PersonMailingPostalCode;
                    this.accState = result.PersonMailingState;
                    this.accCity = result.PersonMailingCity;
                    this.accComplementAddress = result.complementAdresse__c;
                    this.etage = result.etage__c;
                    this.accCountry = result.PersonMailingCountry;
                    this.email = result.PersonEmail;
                    this.telDomicile = result.PersonHomePhone;
                    this.telMobile = result.PersonMobilePhone;
                    this.accLongitude = result.Localisation__Longitude__s;
                    this.accLatitude = result.Localisation__Latitude__s;
                    this.origine = result.AccountSource;
                    this.origineCall = result.accountCallSource__c;                    
                    this.getSourceReferencial();
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
     * Retrieving the selected chantier in the lookup field from the database
     */
    autoFillChantierFields(chaId) {
        try {
            this.showLoadingSpinner = true;

            // Call APEX method to get chantier infos
            getChantier({ chaId: chaId})
            .then(result => {
                if (result) {
                    // Selected chantier infos update the form variables
                    console.log('result : '+result);
                    this.chaStreet = result.rue__c;
                    this.chaPostalcode = result.codePostal__c;
                    this.chaState = result.departement__c;
                    this.chaCity = result.ville__c;
                    this.chaComplementAddress = result.complementAdresse__c;
                    this.typeHabitation = result.typeHabitation__c;
                    this.typeResidence = result.typeResidence__c;
                    this.nbPortesFenetres = result.nbPortesEtFenetres__c;
                    this.chaLongitude = result.Localisation__Longitude__s;
                    this.chaLatitude = result.Localisation__Latitude__s;
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
     * Retrieving the selected opportunity in the lookup field from the database
     */
    autoFillOpportunityFields(oppId) {
        try {
            this.showLoadingSpinner = true;

            // Call APEX method to get opportunity infos
            getOpportunity({ oppId: oppId})
            .then(result => {
                if (result) {
                    // Selected opportunity infos update the form variables
                    console.log('result : '+JSON.stringify(result));
                    this.type = result.Type;
                    this.datePrevisionelleSignature = result.CloseDate;
                    this.campagneCall = result.campagneCall__c;
                    if(result.operation__r){
                        this.opeId = result.operation__c;
                        this.opeName = result.operation__r.Name;
                    }
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
     * Retrieving the selected quote in the lookup field from the database
     */
    autoFillQuoteFields(quoteId) {
        try {
            this.showLoadingSpinner = true;

            // Call APEX method to get quote infos
            getQuote({ quoteId: quoteId})
            .then(result => {
                if (result) {
                    // Selected quote infos update the form variables
                    console.log('result : '+JSON.stringify(result));
                    this.dateDevis = result.dateDevis__c;
                    this.montant = result.Total_TTC_devis__c;
                    this.modeFinancement = result.modeFinancement__c;
                    this.typeContrat = result.typeContrat__c;
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
     * Retrieving the selected quote CPQ in the lookup field from the database
     */
    autoFillQuoteCPQFields(quoteId) {
        try {
            this.showLoadingSpinner = true;

            // Call APEX method to get quote infos
            getQuoteCPQ({ quoteId: quoteId})
            .then(result => {
                if (result) {
                    // Selected quote infos update the form variables
                    console.log('result : '+JSON.stringify(result));
                    this.dateDevis = result.dateDevis__c;
                    this.montant = result.totalAmount__c;
                    this.quoteSourceId = result.sourceRef__c;
                    this.quoteSourceName = result.sourceRef__r.Name;
                    this.quoteFinancingMethodId = result.financingMethod__c;
                    this.quoteFinancingMethodName = result.financingMethod__r.Name;
                    this.quoteTermsAndConditionsId = result.termsAndConditions__c;
                    this.quoteTermsAndConditionsName = result.termsAndConditions__r.Name;
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

    /* ========== UTILITY METHODS ========== */    

    /**
     * Function to check all errors before the save action.
     */
    checkAddressFields() {
        // Check if input fields are OK
        let result;
        const allValid = [...this.template.querySelectorAll('lightning-input-address')]
        .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
        }, true);
        
        if (allValid) {                      
            result = true;
        } else {
            result = false;
        }
        return result;
    }

    /**
     * Function to update filters on chantier/opportunity/quote lookup fields so the selection
     * is based on records linked to the already selected lookups
     */
    updateFilters(){
        if(this.accId == null || this.accId === "" || this.accId === "undefined"){
            this.chaFilter = 'CreatedDate > 1970-01-01T00:00:00.000Z';
            if(this.chaId == null || this.chaId === "" || this.chaId === "undefined"){
                this.oppFilter = 'CreatedDate > 1970-01-01T00:00:00.000Z';
            } else {
                this.oppFilter = 'chantier__c = \''+this.chaId+'\'';
            }
            if(this.oppId == null || this.oppId === "" || this.oppId === "undefined"){
                this.quoFilter = 'CreatedDate > 1970-01-01T00:00:00.000Z';
                this.quoCPQFilter = 'CreatedDate > 1970-01-01T00:00:00.000Z';
            } else {
                this.quoFilter = 'OpportunityId = \''+this.oppId+'\'';
                this.quoCPQFilter = 'SBQQ__Opportunity2__c = \''+this.oppId+'\'';
            }
        } else {
            this.chaFilter = 'proprietaire__c = \''+this.accId+'\'';
            if(this.chadId == null || this.chaId === "" || this.chaId === "undefined"){
                this.oppFilter = 'AccountId = \''+this.accId+'\'';
            } else {
                this.oppFilter = 'AccountId = \''+this.accId+'\' AND chantier__c = \''+this.chaId+'\'';
            }
            if(this.oppId == null || this.oppId === "" || this.oppId === "undefined"){
                this.quoFilter = '(compte__c = \''+this.accId+'\' OR autreCompte__c = \''+this.accId+'\')';
                this.quoCPQFilter = '(SBQQ__Account__c = \''+this.accId+'\' OR autreCompte__c = \''+this.accId+'\')';
            } else {
                this.quoFilter = '(compte__c = \''+this.accId+'\' OR autreCompte__c = \''+this.accId+'\') AND OpportunityId = \''+this.oppId+'\'';
                this.quoCPQFilter = '(SBQQ__Account__c = \''+this.accId+'\' OR autreCompte__c = \''+this.accId+'\') AND SBQQ__Opportunity2__c = \''+this.oppId+'\'';
            }
        }
    }

    /**
     * Function to check all errors before changing step.
     */
    checkForErrors() {
        let result = true;
        const today = new Date().toISOString().slice(0, 10);
        //** Standard rules
        // Check if input fields are OK
        const allValid = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
        }, true);            
        if (!allValid) {             
            result = false;
        }
        const allComboboxValid = [...this.template.querySelectorAll('lightning-combobox')]
        .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
        }, true);            
        if (!allComboboxValid) {             
            result = false;
        }
        const allAddressValid = [...this.template.querySelectorAll('lightning-input-address')]
        .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
        }, true);            
        if (!allAddressValid) {             
            result = false;
        }
        //** Special rules
        // check errors on step 1 (Actions)
        if(this.currentStep === 'step-1') {
            if (!this.origine && ! this.origineCall) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner une source.", false);
            } 
        // check errors on step 2 (Account)
        } else if(this.currentStep === 'step-2') {	
            if (!this.lastName) {	
                result = false;	
                this.processErrorMessage("Vous devez sélectionner un nom pour le compte.", false);	
            } else if (!this.accCity || !this.accPostalcode) {	
                result = false;	
                this.processErrorMessage("Vous devez sélectionner une ville et un code postal.", false);	
            } else if (!this.email && !this.telDomicile && !this.telMobile) {	
                result = false;	
                this.processErrorMessage("Vous devez remplir au moins un moyen de joignabilité (email ou téléphone).", false);	
            } 
        // check errors on step 4 (Opportunity)
        } else if(this.currentStep === 'step-4') {	
            if (!this.type) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner un type de projet.", false);
            } else if (!this.datePrevisionelleSignature || this.datePrevisionelleSignature < today) {	
                result = false;	
                this.processErrorMessage("Vous devez sélectionner une date prévisionelle de signature supérieure à la date du jour.", false);	
            }  
        // check errors on step 5 (Quote or Quote CPQ)
        } else if(this.currentStep === 'step-5') {	
            if (!this.dateDevis || this.dateDevis > today) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner la date du devis antérieure à la date du jour.", false);
            } 
            if (this.createQuoteCPQ && !this.quoteSourceId) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner une source.", false);
            } 
            if (this.createQuoteCPQ && !this.quoteFinancingMethodId) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner un mode de financement.", false);
            } 
            if (this.createQuoteCPQ && !this.quoteTermsAndConditionsId) {
                result = false;
                this.processErrorMessage("Vous devez sélectionner une CGV.", false);
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
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    /**
     * Reload the page after a save.
     */
    reloadPage() {
        // go back to step 1
        this.currentStep = "step-1";
        this.selectedActionTypeValue = OBJECTTYPE_CONSTANTS.ACCOUNT;
        this.updateWizardBody();
        this.updateDisplayedSteps();

        // Empty all fields
        this.accId = null;
        this.accName = null;
        this.chaId = null;
        this.chaName = null;
        this.oppId = null;
        this.oppName = null;
        this.quoteId = null;
        this.quoteName = null;
        this.civility = null;
        this.firstName = null;
        this.lastName = null;
        this.accStreet = null;
        this.accPostalcode = null;
        this.accState = null;
        this.accCity = null;
        this.accComplementAddress = null;
        this.etage = null;
        this.accCountry = null;
        this.email = null;
        this.telDomicile = null;
        this.telMobile = null;
        this.accLongitude = null;
        this.accLatitude = null;
        this.origine = null;
        this.origineCall = null;
        this.chaStreet = null;
        this.chaPostalcode = null;
        this.chaState = null;
        this.chaCity = null;
        this.chaComplementAddress = null;
        this.typeHabitation = null;
        this.typeResidence = null;
        this.nbPortesFenetres = null;
        this.chaLongitude = null;
        this.chaLatitude = null;
        this.type = 'Nouveau';
        this.datePrevisionelleSignature = null;
        this.campagneCall = null;
        this.opeId = null;
        this.opeName = null;
        this.dateDevis = new Date().toISOString().slice(0, 10);
        this.montant = null;
        this.modeFinancement = null;
        this.typeContrat = null;
        this.quoteSourceName = null;
        this.quoteSourceId = null;
        this.quoteFinancingMethodName = null;
        this.quoteFinancingMethodId = null;
        this.quoteTermsAndConditionsName = null;
        this.quoteTermsAndConditionsId = null;
    }

    /**
     * Check if the Chantier record has to be created.
     */
    get hasChantier() {
        return (this.selectedActionTypeValue === OBJECTTYPE_CONSTANTS.CHANTIER 
                || this.selectedActionTypeValue === OBJECTTYPE_CONSTANTS.OPPORTUNITY 
                || this.selectedActionTypeValue === OBJECTTYPE_CONSTANTS.QUOTE
        );
    }

    /**
     * Check if the Opportunity record has to be created.
     */
    get hasOpportunity() {
        return (this.selectedActionTypeValue === OBJECTTYPE_CONSTANTS.OPPORTUNITY 
                || this.selectedActionTypeValue === OBJECTTYPE_CONSTANTS.QUOTE
        );
    }

    /**
     * Check if the Quote record has to be created.
     */
    get hasQuote() {
        return (this.selectedActionTypeValue === OBJECTTYPE_CONSTANTS.QUOTE);
    }

    /**
     * Return the action type depends on the CPQ parameter
     */
    get actionTypeValues() {
        let result;
        if(this.createQuoteCPQ) {
            result = [
                { label: OBJECTTYPE_CONSTANTS.ACCOUNT, value: OBJECTTYPE_CONSTANTS.ACCOUNT },
                { label: OBJECTTYPE_CONSTANTS.CHANTIER, value: OBJECTTYPE_CONSTANTS.CHANTIER },
                { label: OBJECTTYPE_CONSTANTS.OPPORTUNITY, value: OBJECTTYPE_CONSTANTS.OPPORTUNITY },
                { label: OBJECTTYPE_CONSTANTS.QUOTE_CPQ, value: OBJECTTYPE_CONSTANTS.QUOTE }
            ]
        } else {
            result = [
                { label: OBJECTTYPE_CONSTANTS.ACCOUNT, value: OBJECTTYPE_CONSTANTS.ACCOUNT },
                { label: OBJECTTYPE_CONSTANTS.CHANTIER, value: OBJECTTYPE_CONSTANTS.CHANTIER },
                { label: OBJECTTYPE_CONSTANTS.OPPORTUNITY, value: OBJECTTYPE_CONSTANTS.OPPORTUNITY },
                { label: OBJECTTYPE_CONSTANTS.QUOTE, value: OBJECTTYPE_CONSTANTS.QUOTE }
            ];
        }
        return result;
    }
}