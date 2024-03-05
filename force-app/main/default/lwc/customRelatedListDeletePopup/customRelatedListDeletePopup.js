/* eslint-disable no-console */
import { LightningElement , api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
 
export default class CustomRelatedListDeletePopup extends LightningElement {
    showModal = false
    @api sobjectLabel
    @api recordId
    @api recordName

    @api show() {
        this.showModal = true;
    }

    @api hide() {
        this.showModal = false;
    }

    handleClose() {
        this.showModal = false;     
    }
    handleDialogClose(){
        this.handleClose()
    }

    get body(){
        return `Etes vous sur de supprimer ce ${this.sobjectLabel.toLowerCase()} ?`
    }

    get header(){
        return `Supprimer ${this.sobjectLabel}`
    }    

    handleDelete(){
        deleteRecord(this.recordId)
            .then(() => {    
                this.hide()
                const evt = new ShowToastEvent({
                    title: `${this.sobjectLabel}  "${this.recordName}" a été supprimé.`,
                    variant: "success"
                });
                this.dispatchEvent(evt);
                this.dispatchEvent(new CustomEvent("refreshdata"));  
            }).catch(error => {
                const evt = new ShowToastEvent({
                    title: 'Erreur lors de la suppression',
                    message: error.body.message,
                    variant: 'error'
                })
                this.dispatchEvent(evt)
            });
    }
    
}