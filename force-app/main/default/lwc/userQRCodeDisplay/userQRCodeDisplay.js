import { LightningElement, track, api, wire } from 'lwc';
import Id from '@salesforce/user/Id';

import getUserData from '@salesforce/apex/LWC_UserQRCodeDisplay.getUserData';
import getMagasinsName from '@salesforce/apex/LWC_UserQRCodeDisplay.getMagasinsName';
import getMagasinData from '@salesforce/apex/LWC_UserQRCodeDisplay.getMagasinData';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class UserQRCodeDisplay extends LightningElement {
    //Variables
    showLoadingSpinner = true;
    userId=Id;
    @track userData=null;
    @track hasUserData=false;

    @track selectedMagasin;

    @track magasinData=null;
    @track hasCustplaceData=false;
    
    @track listeMagasins;
    @track picklistNomMagasins;
    @track listeNumMagasins;

    @track error;

    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        // Init body
    }

    connectedCallback(){
        this.getUserData();
        this.getMagasinsName();
    }

    /* ========== EVENT METHODS ========== */

    handleMagasinList(event) {
        this.resetErrorMessage();
        this.selectedMagasin = event.detail.value;
        this.getMagasinData();
    }
    
    /* ========== JS METHODS ========== */

    getUserData(){
        this.showLoadingSpinner = true;

        try {
            // Appel à la méthode APEX    
            getUserData({ userId: this.userId})
            .then(result => {                
                if (result) {  
                    if(result!=null){
                        this.userData=result;
                        if(this.userData.autoQuoteRequestQRCodeURL__c==null || this.userData.autoQuoteRequestURL__c==null){
                            this.hasUserData=false;
                        }
                        else{
                            this.hasUserData=true;
                        }
                    }
                } else {
                    this.userData=null;
                    this.hasUserData=false;
                } 
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this.processErrorMessage(error,false);
            }); 
        }
        catch(error) {
            this.processErrorMessage(error.message,false);
        }
    }

    getMagasinsName(){
        try {
            this.showLoadingSpinner = true;
            // Reinitialisation des variables
            this.listeNumMagasins=[];
            this.picklistNomMagasins=[];   
            // Appel à la méthode APEX          
            getMagasinsName({ userId: this.userId})
            .then(result => {                
                if (result) {  
                    this.listeMagasins=result;
                    let firstMagasin = true;
                    //listeMagasins => Liste de : numMagasin|nomMagasin
                    for(const magasin of this.listeMagasins){
                        // Séparation de la chaine : numMagasin|nomMagasin
                        const splittedMagasin = magasin.split('|');
                        this.listeNumMagasins.push(splittedMagasin[0]);
                        this.picklistNomMagasins.push({label : splittedMagasin[1], value : splittedMagasin[0]});
                        // Premier magasin en tant que magasin par défaut dans la liste de sélection
                        if(firstMagasin){
                            this.selectedMagasin = splittedMagasin[0];
                            firstMagasin = false;
                        }
                    }   
                    //Appel APEX : Données du magasin
                    this.getMagasinData();
                }
                this.showLoadingSpinner = false;    
            })
            .catch(error => {
                this.processErrorMessage(error,false);
            }); 
        }
        catch(error) {
            this.processErrorMessage(error.message,false);
        }
    }

    getMagasinData(){
        try {
            this.showLoadingSpinner = true;
            // Appel à la méthode APEX                
            getMagasinData({ codeMagasin: this.selectedMagasin})
            .then(result => {                
                if (result) {  
                    this.magasinData=result;
                    if(this.magasinData.CustplaceSatisfactionQRCodeURL__c==null || this.magasinData.CustplaceSatisfactionURL__c==null) {
                        this.hasCustplaceData=false;
                    }
                    else{
                        this.hasCustplaceData=true;
                    }  
                }
                this.showLoadingSpinner = false;  
            })
            .catch(error => {
                this.processErrorMessage(error,false);
            }); 
        }
        catch(error) {
            this.processErrorMessage(error.message,false);
        }
    }

    /* ========== UTILITY METHODS ========== */   

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
        console.error(error);
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