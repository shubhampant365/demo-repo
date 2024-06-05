<template>
    <lightning-card title="Sending for Approval" icon-name="utility:approval">
        <div class="slds-m-around_medium">
            <template if:true={isProcessing}>
                <lightning-spinner alternative-text="Processing" size="medium"></lightning-spinner>
                <p>Sending record for approval...</p>
            </template>
            <template if:false={isProcessing}>
                <p>{message}</p>
            </template>
        </div>
    </lightning-card>
</template>



import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import submitForApproval from '@salesforce/apex/SubmitForApprovalController.submitForApproval';

export default class SubmitForApproval extends LightningElement {
    @api recordId;
    message;
    messageClass;

    handleSubmit() {
        submitForApproval({ recordId: this.recordId })
            .then(() => {
                this.message = 'Record submitted for approval successfully';
                this.messageClass = 'slds-text-color_success';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: this.message,
                        variant: 'success',
                    }),
                );
            })
            .catch(error => {
                this.message = 'Error in submitting for approval: ' + error.body.message;
                this.messageClass = 'slds-text-color_error';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.message,
                        variant: 'error',
                    }),
                );
            });
    }
}



public with sharing class SubmitForApprovalController {
    @AuraEnabled
    public static void submitForApproval(Id recordId) {
        // Query the active approval process for the ServiceAppointment object
        List<ProcessDefinition> processDefs = [
            SELECT Id 
            FROM ProcessDefinition 
            WHERE TableEnumOrId = 'ServiceAppointment' 
            AND IsActive = true 
            LIMIT 1
        ];

        if (processDefs.isEmpty()) {
            throw new AuraHandledException('No active approval process found for ServiceAppointment.');
        }

        // Create an approval request
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitted for approval');
        req.setObjectId(recordId);
        req.setProcessDefinitionId(processDefs[0].Id);  // Set the approval process ID

        // Submit the approval request
        Approval.ProcessResult result = Approval.process(req);
        if (result.isSuccess()) {
            System.debug('Successfully submitted for approval.');
        } else {
            throw new
