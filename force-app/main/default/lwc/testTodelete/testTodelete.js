import { LightningElement, track, api,wire  } from 'lwc';  
import getAssetList from "@salesforce/apex/fsapp_AssetImages.getAssetRecords";

 export default class lWCComponent extends LightningElement{
  @track assets;
  @api recordId;  
  @wire(getAssetList, { serviceAppointmentId: '$recordId' }) assets
  

  DisplayText = false;
  textValue='LWC Function Invoked through Aura Component'  
  @api LWCFunction(){
    console.log('assets ===1=====', JSON.stringify(this.assets));
    console.log('assets ===1====='+this.assets);
  this.assets.data.forEach(asset => {
    console.log(asset);
  });
  }
/*
  handleLoad() {
    getAssetList()
      .then((result) => {
        console.log('result ===2====='+result);
        this.assets = result;
        console.log(this.assets);
        this.assets.data.forEach(asset => {
          console.log(asset);
        });
      })
      .catch((error) => {
        console.log('error ===2====='+error);
        this.error = error;
      });
  }*/

}