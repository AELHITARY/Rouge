import { LightningElement, track, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import RelatedListHelper from "./relatedListHelper";
import initDataMethod from "@salesforce/apex/LWC_CustomRelatedList.initData";

export default class CustomRelatedList extends NavigationMixin(LightningElement) {
    // Current object api name
    @api sobjectApiName;
    // Current record's id
    @api recordId;
    @api relatedFieldApiName;
    @api numberOfRecords = 10;
    @api sortedBy;
    @api sortedDirection = "ASC";
    @api rowActionHandler;
    @api fields;
    @api columns;
    @api customActions = [];
    @api showNewButton = false;
    @api hideNoRecords = false;
    @api iconeName;
    @api filter;

    @track state = {};
    @track data;
    @track showLoadingSpinner = false;
    @track showAllRecordsButton = true;
    @track showAllRecords = false;
    @track error;
    @track hasRendered = true;

    helper = new RelatedListHelper();

    get hasRecords() {
        return this.data != null && this.data.length;
    }

    get displayCompenent() {
        let result = false;
        if((this.hasRecords) || (this.hasRecords == false && this.hideNoRecords == false)) {
            result = true;
        } 
        return result;
    }

    /**
     * Constructor of the LWC.
     * @constructor
     */
    constructor() {
        super();        
        this.showLoadingSpinner = true;        
    }
    
    /**
     * renderedCallback of the LWC.
     * @renderedCallback
     */
    renderedCallback() {
        console.debug("CustomRelatedList : renderedCallback : " + this.sobjectApiName);
        // Guarding code inside the renderedCallback using boolean property
        if (this.hasRendered) {
            this.hasRendered = false;
            // Parse the data  of the columns infos on JSON
            this.columns = this.columns.trim();
            this.columns = JSON.parse(this.columns);
            // Execute functions
            this.getNumberRecordsMax();
            this.initDatatable();
        }
    }

    /**
     * Async Method to get datas of child records and update the datatable.
     */
     async initDatatable() {
        try {
            this.state.showRelatedList = this.recordId != null;
            if (! (this.recordId
                && this.sobjectApiName
                && this.relatedFieldApiName
                && this.fields
                && this.columns)) {
                this.data = [];
                this.showLoadingSpinner = false;
                return;
            }
            console.debug("CustomRelatedList : initDatatable : " +this.sobjectApiName);

            this.state.fields = this.fields;
            this.state.relatedFieldApiName= this.relatedFieldApiName;
            this.state.recordId= this.recordId;
            this.state.numberOfRecords= this.numberOfRecords;
            this.state.sobjectApiName= this.sobjectApiName;
            this.state.sortedBy= this.sortedBy;
            this.state.sortedDirection= this.sortedDirection;
            this.state.customActions= this.customActions;
            this.state.showAllRecords = this.showAllRecords;
            this.state.iconName = this.iconeName;
            this.state.filter = this.filter;
            
            // Process data by calling APEX
            //const data = await this.helper.fetchData(this.state);
              
            let jsonData = Object.assign({}, this.state)
            jsonData = JSON.stringify(jsonData)
            initDataMethod({ jsonData })
            .then(response => {
                let data = JSON.parse(response)
                data = this.helper.processData(data, this.state)
                // Define the datas of the related list
                if(data && data.records) {
                    this.generateLinks(data.records);
                    this.state.iconName = data.iconName;
                    this.state.sobjectLabel = data.sobjectLabel;
                    this.state.sobjectLabelPlural = data.sobjectLabelPlural;
                    this.state.parentRelationshipApiName = data.parentRelationshipApiName;
                    this.state.columns = this.helper.initColumnsWithActions(this.columns, this.customActions);
                }
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                console.log(error);
            });
                /*
            // Define the datas of the related list
            if(data && data.records) {
                this.generateLinks(data.records)
                this.state.records = data.records;
                this.state.iconName = data.iconName;
                this.state.sobjectLabel = data.sobjectLabel;
                this.state.sobjectLabelPlural = data.sobjectLabelPlural;
                this.state.parentRelationshipApiName = data.parentRelationshipApiName;
                this.state.columns = this.helper.initColumnsWithActions(this.columns, this.customActions);
            }
            this.showLoadingSpinner = false;
            */
        } catch (ex) {
            this.processErrorMessage(ex, false);
        }
    }

    /**
     * Async Method to get the total of child records and update the title.
     */
     getNumberRecordsMax() {
        try {
            if (! (this.recordId
                && this.sobjectApiName
                && this.relatedFieldApiName
                && this.fields)) {
                return;
            }

            this.state.fields = this.fields;
            this.state.relatedFieldApiName= this.relatedFieldApiName;
            this.state.recordId= this.recordId;
            this.state.sobjectApiName= this.sobjectApiName;
            this.state.sortedBy= this.sortedBy;
            this.state.sortedDirection= this.sortedDirection;
            this.state.showAllRecords = true;
            this.state.iconName = this.iconeName;
            this.state.filter = this.filter;

            // Process data by calling APEX
            /*const data = await this.helper.fetchData(this.state);
            if(data) {
                // Define the title
                this.state.title = data.title;
                // Display of not the "All records" button depends on the size
                if(data.records && (data.records.length > this.numberOfRecords)) {
                    this.showAllRecordsButton = true;
                } else {
                    this.showAllRecordsButton = false;
                }
            }*/
            
            
            let jsonData = Object.assign({}, this.state)
            jsonData = JSON.stringify(jsonData)
            initDataMethod({ jsonData })
            .then(response => {
                let data = JSON.parse(response)
                data = this.helper.processData(data, this.state)
                // Define the datas of the related list
                if(data) {
                    // Define the title
                    this.state.title = data.title;
                    // Display of not the "All records" button depends on the size
                    if(data.records && (data.records.length > this.numberOfRecords)) {
                        this.showAllRecordsButton = true;
                    } else {
                        this.showAllRecordsButton = false;
                    }
                }
            })
            .catch(error => {
                console.log(error);
            });
        } catch (ex) {
            this.processErrorMessage(ex, false);
        }
    }
    
    /* ========== EVENT METHODS ========== */

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (this.rowActionHandler) {
            this.rowActionHandler.call()
        } else {
            switch (actionName) {
                case "delete":
                    this.handleDeleteRecord(row);
                    break;
                case "edit":
                    this.handleEditRecord(row);
                    break;
                default:
            }
        }
    }

    handleDisplayAllRecords() {
        this.showAllRecordsButton = false;
        this.showAllRecords = true;
        this.initDatatable();
    }

    handleCreateRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.sobjectApiName,
                actionName: 'new'
            }
        });
    }

    handleEditRecord(row) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                actionName: 'edit'
            }
        });
    }

    handleDeleteRecord(row) {
        const newEditPopup = this.template.querySelector("c-custom-related-list-delete-popup");
        newEditPopup.recordId = row.Id;
        newEditPopup.recordName = row.Name;
        newEditPopup.sobjectLabel = this.state.sobjectLabel;
        newEditPopup.show();
    }

    handleRefreshData() {
        this.showLoadingSpinner = true;
        this.getNumberRecordsMax();
        this.initDatatable();
    }

    /* ========== JS METHODS ========== */

    /**
     * Method to generate link for the datatable (property "LinkName").
     */
    generateLinks(records) {
        records.forEach(record => {
            // Generate a URL to the record page
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: record.Id,
                    actionName: 'view',
                },
            }).then(url => {
                record.LinkName = url
                for (const propertyName in record) {
                    const propertyValue = record[propertyName];
                    if (typeof propertyValue === 'object') {
                        const newValue = propertyValue.Id ? ('/' + propertyValue.Id) : null;
                        this.helper.flattenStructure(record, propertyName + '_', propertyValue);
                        if (newValue !== null) {
                            record[propertyName + '_LinkName'] = newValue;
                        }
                    }
                }
                this.data = records; 
            });
        });
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
        console.error(message);
        this.showLoadingSpinner = false;
        this.state.showRelatedList = false;
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