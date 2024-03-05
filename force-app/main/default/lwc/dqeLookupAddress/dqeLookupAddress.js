/* eslint-disable no-console */
import { LightningElement, api, track } from 'lwc';

// Apex class methods
import executeDQERequest from '@salesforce/apex/LWC_DQEFormAddress.executeDQERequest';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
// Import label
import placeholderLabel from '@salesforce/label/c.cartographie_msg_SearchPlaceholder';
// Import utility variables for state and country
import { STATE_NAME, DOMTOM, REGION_NAME, REGION } from './stateUtils';
import { PAYS_NAME_MAP, PAYS_CODE_MAP } from './countryUtils';

const DELAY = 500; // The delay used when debouncing event handlers before firing the event
const SEARCH_LENGTH_MIN = 3; // The min of the length of the search text

export default class DQELookUpAddress extends LightningElement {

    //@track icon = 'account';
    //@track label = 'Search for Address...';
    @track isEmptySelItem;
    @track showLoadingSpinner = false;
    @track object;
    
    @track search = '';
    @track lastSearchText;
    
    // Variables of the API result
    @track serverResultList;
    @track displayServerResult;
    @track lastServerResult;
    @track noResult;

    @track idv;
    @track idn;
    @track selItem = [];
    @track error;
    @api label;
    @api placeholder = placeholderLabel;
    @api icon;
    @api street;
	@api zip;
	@api state;
    @api city;
    @api country;
    @api countryCode;
    @api lat;
    @api lng;
    
    delayTimeout;

    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();
        // Init body
        this.isEmptySelItem = true;
        this.showLoadingSpinner = false;
        this.serverResultList = [];
        this.displayServerResult = false;
    }

    /* ========== API METHODS ========== */

    connectedCallback() {
        if(this.selItem.length === 0) {
            this.isEmptySelItem = true;
        } else {
            this.isEmptySelItem = false;
        }
    }

    /* ========== EVENT METHODS ========== */

    /**
     * Function executed when a user add a caracter in the input text.
     * @param {object} event - Object of the onChange Event.
     */
    handleKeyUpAutocomplete(event){
        // Check value        
        const keyCode = event.keyCode;
        const value = event.target.value;
        this.search = value;
        // Debouncing this method: Do not actually fire the event as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls in components listening to this event.
        clearTimeout(this.delayTimeout);
        if (keyCode === 27 || !value ||  value.length === 0) {
            // Escape button pressed or no value
            this.clearSelection();
        } else {
            // Call delay method
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.delayTimeout = setTimeout(() => {
                this.delayedFireKeyUpAutocompleteEvent(value);
            }, DELAY);
        }
    }
    
    /**
     * Function executed by "handleKeyUpAutocomplete" function when the delay if reached to avoid a large number of DQE API call.
     * @param {string} value - Value of the input (get by "handleKeyUpAutocomplete").
     */
    delayedFireKeyUpAutocompleteEvent(value) {
        try {
            const searchText = value.trim();
            if(searchText !== this.lastSearchText && searchText.length >= SEARCH_LENGTH_MIN){
                // Call DQE WebService
                this.callDQESINGLE(searchText);
            } else if(searchText && this.lastSearchText && searchText === this.lastSearchText){
                // If the result is identical to the last result, do nothing
                this.serverResultList = this.lastServerResult;
            }
        }catch(error){
            this.processErrorMessage(error.message);
        }
    }

    /**
     * Function executed when a user select an address.
     * @param {object} event - Object of the Event.
     */	
    handleItemSelected(event){
        if(this.noResult === false) {
            let target = event.target;
            let selectedIndex = this.getIndexFrmParent(target, "data-selected-index");
            if(selectedIndex){
                // Get details of the selected item
                this.selItem = this.serverResultList.find(address => address.IDVoie === selectedIndex);
                // Fill all address field
                this.fillAddressFields(this.selItem);             
                if(this.selItem.Pays === 'FRA') {
                    // Call COMPLV2 DQE Service to get Lat/Longitude
                    this.callDQECOMPL(this.selItem.IDVoie, this.selItem.IDLocalite);
                } else {                    
                    // Notify Parent Component
                    this.sendItemSelectedEvent();
                }
                // Reinit values			
                this.search = '';
                this.serverResultList = null;
                this.displayServerResult = false;
            }
        }
    }

    /**
     * Send event message to Parent Components to notify them that item has selected.
     */	
    sendItemSelectedEvent(){
        // Send Event to Parent Components to notify them that item has selected
        const evt = new CustomEvent('selecteditemevent', {
            detail:{
                street: this.street,
                zip: this.zip,
                city: this.city,
                state: this.state,
                country: this.country,
                longitude: this.lng,
                latitude: this.lat
            }
        });
        this.dispatchEvent(evt);
    }

    /* ========== JS METHODS ========== */
    
    /**
     * Function to execute the "SINGLE" service of DQE to get address information with a text.
     * @param {string} searchText - Text of the search (address).
     */
    callDQESINGLE(searchText){
        if(this.country == null) {
            this.country = 'FRANCE';
        }
        let countryCode = (this.countryCode) ? this.countryCode : PAYS_NAME_MAP[this.country.toUpperCase()];
        this.lastSearchText = searchText;
        // Call APEX method to execute the API
        if(countryCode && searchText) {
            executeDQERequest({params : {'Adresse' : searchText, 'Pays' : countryCode},
                                service : 'SINGLEV2'})
            .then(result => {
                this.processDQEResponse(result);
            })
            .catch(error => {
                this.processErrorMessage(error);
            });
        }
    }

    /**
     * Function to execute the "COMPLV2" service of DQE to get longitude/latitude information of an address.
     * @param {object} event - Object of the KeyUp Event.
     */
    callDQECOMPL(idv, idn) {
        executeDQERequest({params : {'IDVoie' : idv, 'IDNum': idn, 'Taille': 38, 'Pays' : 'FRA'},
                            service : 'COMPLV2'})
        .then(result => {
            var retObj = JSON.parse(result);
            this.lat = retObj.Latitude;
            this.lng = retObj.Longitude;            
            console.log('## Longitude : '+this.lng);
            console.log('## Latitude : '+this.lat);

            // Notify Parent Component
            this.sendItemSelectedEvent();
        })
        .catch(error => {
            this.processErrorMessage(error);
        });
    }

    /**
     * Function to process the response of the "SINGLE" service of the DQE API.
     * @param {object} result - Result of the DQE API.
     */
    processDQEResponse(result){
		let resultFormated;

        try {
            let resultDQEObj = JSON.parse(result);            
            if((typeof resultDQEObj === 'object') && Object.keys(resultDQEObj).length > 0) {
                // Address founded
                resultFormated = this.formatDQEResponse(resultDQEObj);
                this.noResult = false;
            } else {
                // No Result
                resultFormated = JSON.parse('[{"label":"Pas d\'adresses trouvée"}]');
                this.noResult = true;
            }
			this.displayServerResult = true;
			this.serverResultList = resultFormated;
			this.lastServerResult = resultFormated;
        }
        catch(error){
            this.processErrorMessage(error.message);
        }
    }

    /**
     * Format the DQE response and limit the result display.
     * @param {object} dqeResponse - The DQE response object.
     */
    formatDQEResponse(dqeResponse){
        let resultList = [];
        // For all element in the array
        for(let i=1; i < 10 ; i++){
            let element = dqeResponse[i];
            if(element){
                // Replace | by , and [] by space
                element.label = element.label.replace('|', ', ').replace('[]', '');
                resultList.push(element);
                console.log('element.label : ' + element.label);
            }
        }
        return resultList;
    }
        
    /**
     * Return the name of the region (région) according to the postal code
     * @param {string} postalCode The postal code
     * @returns {string} The name of the region
     */
    getRegionName(postalCode) {
        let starts = parseInt(postalCode.substr(0, 2), 10);
		if (starts > 95) {
			return "DOM-TOM";
		}
        let index = REGION[starts - 1];
        return REGION_NAME[index];
    }
    
    /**
     * Return the name of the state (département) according to the postal code
     * @param {string} postalCode The postal code
     * @returns {string} The name of the state
     */
    getDeptName(postalCode) {
        //DOM-TOM
        let starts = postalCode.substr(0, 3);
		if (DOMTOM[starts]) {
			return DOMTOM[starts];
		}
        //Métropole
        starts = parseInt(postalCode.substr(0, 2), 10);
        return STATE_NAME[starts - 1];
    }
    
    /**
     * Function to fill all address field of the component.
     * @param {object} selItem - Objet of the address selected.
     */
    fillAddressFields(selItem){
        this.street = selItem.Num + ' ' + selItem.Voie;
        this.zip = selItem.CodePostal;
        this.city = selItem.Localite;
        // Define country
        if(selItem.Pays) {
            this.country = PAYS_CODE_MAP[selItem.Pays];
            this.countryCode =selItem.Pays;
        } else {
            this.country = "";
            this.countryCode = "";
        }
		// Define the state / region
		if(this.zip) {
			if(this.getDeptName(this.zip) && this.getRegionName(this.zip)) {
				let region_dept = this.getDeptName(this.zip).toLocaleUpperCase() + ' / ' + this.getRegionName(this.zip).toLocaleUpperCase();
				this.state = region_dept;
			}
		} 
        console.log('## Street : '+this.street);
        console.log('## PostalCode : '+this.zip);
        console.log('## City : '+this.city);
        console.log('## State : '+this.state);   
        console.log('## Country : '+this.country);   
    }

    /**
     * Get the index of the address selected in the list.
     * @param {object} target - The target object.
     * @param {string} attributeToFind - The html attribute uses to find object.
     */
    getIndexFrmParent(target, attributeToFind){
        //User can click on any child element, so traverse till intended parent found
        let selectedIndex = target.getAttribute(attributeToFind);
        while(!selectedIndex){
            target = target.parentNode ;
            selectedIndex = this.getIndexFrmParent(target, attributeToFind);
        }
        return selectedIndex;
	}

    /* ========== UTILITY METHODS ========== */    

    /**
     * Clear all variables used for the autocomplete input.
     */
    clearSelection(){
        this.search = null;
        this.selItem = null;
        this.serverResultList = null;
        this.displayServerResult = false;
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
        console.error(error);
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
}