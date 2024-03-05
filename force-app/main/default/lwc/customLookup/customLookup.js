/* eslint-disable vars-on-top */
/* eslint-disable eqeqeq */
/* eslint-disable no-console */
import { LightningElement, api, track } from 'lwc';
import getResults from '@salesforce/apex/LWC_CustomLookup.getResults';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

const MINIMAL_SEARCH_TERM_LENGTH = 2; // Min number of chars required to search
const SEARCH_DELAY = 300; // Wait 300 ms after user stops typing then, peform search

export default class LwcCustomLookup extends LightningElement {
    @api label;
    @api selection = [];
    @api placeholder = '';
    @api isMultiEntry = false;
    @api errors = [];
    @api scrollAfterNItems;
    @api customKey;

    @api selectRecordId;
    @api selectRecordName;
    @api objectName;
    @api objectTypeRecordName;
    @api fieldName;
    @api fieldNameSearch;
    @api subtitleField;
    @api customFilter;
    @api orderBy;
    @api required = false;
    @api iconName;

    @track searchTerm = '';
    @track searchResults = [];
    @track loading = false;

    _hasFocus = false;
    _isDirty = false;
    _cleanSearchTerm;
    blurTimeout;
    searchThrottlingTimeout;

    // EXPOSED FUNCTIONS

    @api
    getSelection() {
        return this.selection;
    }

    @api
    getkey() {
        return this.customKey;
    }
   
    connectedCallback() {
        // initialize component
        if(this.selectRecordName != null) {
            let selectedItem = {
                id: this.selectRecordId, 
                sObjectType: this.objectName, 
                title: this.selectRecordName, 
                subtitle: this.selectRecordName
            };
            const newSelection = [];
            newSelection.push(selectedItem);
            this.selection = newSelection;
        }
    }

    // INTERNAL FUNCTIONS

    updateSearchTerm(newSearchTerm) {
        this.searchTerm = newSearchTerm;

        // Compare clean new search term with current one and abort if identical
        const new_cleanSearchTerm = newSearchTerm
            .trim()
            .replace(/\*/g, '')
            .toLowerCase();
        if (this._cleanSearchTerm === new_cleanSearchTerm) {
            return;
        }

        // Save clean search term
        this._cleanSearchTerm = new_cleanSearchTerm;

        // Ignore search terms that are too small
        if (new_cleanSearchTerm.length < MINIMAL_SEARCH_TERM_LENGTH) {
            this.searchResults = [];
            return;
        }

        // Apply search throttling (prevents search if user is still typing)
        if (this.searchThrottlingTimeout) {
            clearTimeout(this.searchThrottlingTimeout);
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.searchThrottlingTimeout = setTimeout(() => {
            // Send search event if search term is long enougth
            if (this._cleanSearchTerm.length >= MINIMAL_SEARCH_TERM_LENGTH) {
                // Display spinner until results are returned
                this.loading = true;

                // Call APEX method to search
                getResults({ objectName: this.objectName, 
                            objectTypeRecordName: this.objectTypeRecordName, 
                            fld_API_Val: this.fieldName, 
                            fld_API_Search: this.fieldNameSearch,
                            subtitleField : this.subtitleField,
                            searchText: this.searchTerm,
                            customFilter: this.customFilter,
                            orderBy: this.orderBy  })
                .then(result => {
                    this.setSearchResults(result);
                })
                .catch(error => {
                    console.log('### ERROR : '+error.body.message);
                });
            }
            this.searchThrottlingTimeout = null;
        }, SEARCH_DELAY);
    }

    setSearchResults(results) {
        // Reset the spinner
        this.loading = false;

        this.searchResults = results.map(result => {
            // Clone and complete search result if icon is missing
            /*if (typeof result.icon === 'undefined') {
                const { id, sObjectType, title, subtitle } = result;
                return {
                    id,
                    sObjectType,
                    icon: 'standard:default',
                    title,
                    subtitle
                };
            }*/
            return result;
        });
    }

    isSelectionAllowed() {
        if (this.isMultiEntry) {
            return true;
        }
        return !this.hasSelection();
    }

    hasResults() {
        return this.searchResults.length > 0;
    }

    hasSelection() {
        return this.selection.length > 0;
    }

    /*processSelectionUpdate(isUserInteraction) {
        // Reset search
        this._cleanSearchTerm = '';
        this.searchTerm = '';
        // Remove selected items from default search results
        const selectedIds = this._curSelection.map((sel) => sel.id);
        let defaultResults = [...this._defaultSearchResults];
        defaultResults = defaultResults.filter((result) => selectedIds.indexOf(result.id) === -1);
        this.setSearchResults(defaultResults);
        // Indicate that component was interacted with
        this._isDirty = isUserInteraction;
        // If selection was changed by user, notify parent components
        if (isUserInteraction) {
            this.dispatchEvent(new CustomEvent('selectionchange', { detail: selectedIds }));
        }
    }*/

    @api
    validate() {
        // Validation logic to pass back to the Flow
        if(!this.required || this.hasSelection()) { 
            this.setIsInvalidFlag(false);
            return { isValid: true }; 
        } 
        else { 
            // If the component is invalid, return the isValid parameter 
            // as false and return an error message. 
            this.setIsInvalidFlag(true);
            return { 
                isValid: false, 
                errorMessage: 'Au moins 1 enregistrement doit être sélectionné.' 
            }; 
        }
    }

    setIsInvalidFlag(value) {
        this.isInvalid = value;
    }

    // EVENT HANDLING

    handleInput(event) {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed()) {
            return;
        }
        this.updateSearchTerm(event.target.value);
    }

    handleResultClick(event) {
        const recordId = event.currentTarget.dataset.recordid;

        // Save selection
        let selectedItem = this.searchResults.filter(
            result => result.id === recordId
        );
        if (selectedItem.length === 0) {
            return;
        }
        selectedItem = selectedItem[0];
        const newSelection = [...this.selection];
        newSelection.push(selectedItem);
        this.selection = newSelection;

        // Reset search
        this.searchTerm = '';
        this.searchResults = [];

        // Notify parent components that selection has changed
        this.dispatchEvent(new CustomEvent('selectionchange'));

        // Update values to be passed back to the Flow
        this.setIsInvalidFlag(false);
        if(this.required && !this.hasSelection()) {
            this.setIsInvalidFlag(true);
        }
        this.dispatchEvent(new FlowAttributeChangeEvent('selectRecordId', this.selection[0].id));
        this.dispatchEvent(new FlowAttributeChangeEvent('selectRecordName', this.selection[0].title));
    }

    handleComboboxClick() {
        // Hide combobox immediatly
        if (this.blurTimeout) {
            window.clearTimeout(this.blurTimeout);
        }
        this._hasFocus = false;
    }

    handleFocus() {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed()) {
            return;
        }
        this._hasFocus = true;
    }

    handleBlur() {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed()) {
            return;
        }
        // Delay hiding combobox so that we can capture selected result
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.blurTimeout = window.setTimeout(() => {
            this._hasFocus = false;
            this.blurTimeout = null;
        }, 300);
    }

    handleRemoveSelectedItem(event) {
        const recordId = event.currentTarget.name;
        this.selection = this.selection.filter(item => item.id !== recordId);
        // Notify parent components that selection has changed
        this.dispatchEvent(new CustomEvent('selectionchange'));
    }

    handleClearSelection() {
        this.selection = [];
        this._hasFocus = false;
        this._cleanSearchTerm = '';
        this.searchTerm = '';
        // Notify parent components that selection has changed
        this.dispatchEvent(new CustomEvent('selectionchange'));
        this.dispatchEvent(new FlowAttributeChangeEvent('selectRecordId', null));
        this.dispatchEvent(new FlowAttributeChangeEvent('selectRecordName', null));
    }

    // STYLE EXPRESSIONS

    get getContainerClass() {
        let css = 'slds-combobox_container slds-has-inline-listbox ';
        if (this._hasFocus && this.hasResults()) {
            css += 'slds-has-input-focus ';
        }
        if (this.errors.length > 0) {
            css += 'has-custom-error';
        }
        return css;
    }

    get getDropdownClass() {
        let css = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ';
        //const isSearchTermValid = this._cleanSearchTerm && this._cleanSearchTerm.length >= MINIMAL_SEARCH_TERM_LENGTH;
        //if (this._hasFocus && this.isSelectionAllowed() && (isSearchTermValid || this.hasResults())) {
        if (this._hasFocus && this.isSelectionAllowed() && (this.hasResults())) {            
            css += 'slds-is-open';
        }
        return css;
    }

    get getInputClass() {
        let css = 'slds-input slds-combobox__input has-custom-height ';
        if (this.errors.length > 0 || (this.required && !this.hasSelection())) {
            css += 'has-custom-error ';
        }
        if (!this.isMultiEntry) {
            css += 'slds-combobox__input-value ' + (this.hasSelection() ? 'has-custom-border' : '');
        }
        return css;
    }

    get getComboboxClass() {
        let css = 'slds-combobox__form-element slds-input-has-icon ';
        if (this.isMultiEntry) {
            css += 'slds-input-has-icon_right';
        } else {
            css += this.hasSelection() ? 'slds-input-has-icon_left-right' : 'slds-input-has-icon_right';
        }
        return css;
    }

    get getSearchIconClass() {
        let css = 'slds-input__icon slds-input__icon_right ';
        if (!this.isMultiEntry) {
            css += this.hasSelection() ? 'slds-hide' : '';
        }
        return css;
    }

    get getClearSelectionButtonClass() {
        return (
            'slds-button slds-button_icon slds-input__icon slds-input__icon_right ' +
            (this.hasSelection() ? '' : 'slds-hide')
        );
    }

    get getSelectIconName() {
        return this.hasSelection() ? this.iconName : 'standard:default';
    }

    get getSelectIconClass() {
        return 'slds-combobox__input-entity-icon ' + (this.hasSelection() ? '' : 'slds-hide');
    }

    get getInputValue() {
        if (this.isMultiEntry) {
            return this.searchTerm;
        }
        return this.hasSelection() ? this.selection[0].title : this.searchTerm;
    }

    get getInputTitle() {
        if (this.isMultiEntry) {
            return '';
        }
        return this.hasSelection() ? this.selection[0].title : '';
    }

    get getListboxClass() {
        return (
            'slds-listbox slds-listbox_vertical slds-dropdown slds-dropdown_fluid ' +
            (this.scrollAfterNItems ? 'slds-dropdown_length-with-icon-' + this.scrollAfterNItems : '')
        );
    }

    get isInputReadonly() {
        if (this.isMultiEntry) {
            return false;
        }
        return this.hasSelection();
    }

    get isExpanded() {
        return this.hasResults();
    }
}