/* eslint-disable guard-for-in */
/* eslint-disable no-console */
import initDataMethod from "@salesforce/apex/LWC_CustomRelatedList.initData";

export default class RelatedListHelper {

    /*fetchData(state) {
        let jsonData = Object.assign({}, state)
        jsonData = JSON.stringify(jsonData)
        return initDataMethod({ jsonData })
            .then(response => {
                const data = JSON.parse(response)
                return this.processData(data, state)
            })
            .catch(error => {
                console.log(error);
            });
    }*/

    processData(data, state){
        const records = data.records;
        if (records.length > state.numberOfRecords) {
            //records.pop()
            data.title = `${data.sobjectLabelPlural} (${records.length})`
        } else {
            data.title = `${data.sobjectLabelPlural} (${Math.min(state.numberOfRecords, records.length)})`
        }     
        return data
    }

    initColumnsWithActions(columns, customActions) {
        if (!customActions.length) {
            customActions = [
                { label: 'Modifier', name: 'edit' },
                { label: 'Supprimer', name: 'delete' }
            ]
        }
        return [...columns, { type: 'action', typeAttributes: { rowActions: customActions } }]
    }

    flattenStructure(topObject, prefix, toBeFlattened) {
        for (const propertyName in toBeFlattened) {
            const propertyValue = toBeFlattened[propertyName];
            if (typeof propertyValue === 'object') {
                this.flattenStructure(topObject, prefix + propertyName + '_', propertyValue);
            } else {
                topObject[prefix + propertyName] = propertyValue;
            }
        }
    }
}