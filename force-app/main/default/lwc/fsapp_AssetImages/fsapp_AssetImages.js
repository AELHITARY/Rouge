import { LightningElement, track, api,wire  } from 'lwc';  
import getAssetList from "@salesforce/apex/fsapp_AssetImages.getAssetRecords";

 export default class lWCComponent extends LightningElement{
  @track assets;
  @api recordId;  
  @wire(getAssetList, { serviceAppointmentId: '$recordId' }) assets
  columns = [
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'action', type: 'button', typeAttributes: { label: 'Photo Avant', name: 'photoAvant' }},
    { label: 'action', type: 'button', typeAttributes: { label: 'Photo Apres', name: 'photoApres' }}
];
  DisplayText = false;
  textValue='LWC Function Invoked through Aura Component'  
  @api LWCFunction(){
    
    console.log('assets ===1=====', JSON.stringify(this.assets));
    console.log('assets ===1====='+this.assets);
  this.assets.data.forEach(asset => {
    console.log(asset);
  });
  }
  @api handleRowAction(event){
    const recordId = event.detail.row.Id
    const actionName = event.detail.action.name;
    console.log('handleRowAction ===2=====');
    console.log('recordId ===2=====',recordId);
    console.log('actionName ===1=====',actionName);
    alert('recordId ===2====='+recordId);
    alert('actionName ===2====='+actionName);
    this.handleNavigate();
    
  }
  handleNavigate() {
    var compDetails = {
        componentDef: "c:secondNavigationLWC",
        attributes: {
            //Value you want to pass to the next lwc component
            propertyValue: "500"
        }
    };
    // Base64 encode the compDefinition JS object
    var encodedCompDetails = btoa(JSON.stringify(compDetails));
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: '/one/one.app⌗' + encodedCompDetails
        }
    });
  
}
handleNavigate() {
    var compDetails = {
        componentDef: "c:imageCapture",
        attributes: {
            //Value you want to pass to the next lwc component
            recordId: this.recordId
        }
    };
    // Base64 encode the compDefinition JS object
    var encodedCompDetails = btoa(JSON.stringify(compDetails));
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: '/one/one.app⌗' + encodedCompDetails
        }
    });
  
}

}