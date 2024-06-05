<template>
    <lightning-card title="Send for Approval" icon-name="action:approval">
        <div class="slds-m-around_medium">
            <lightning-button 
                label="Send for Approval" 
                onclick={handleSendForApproval} 
                style="margin-bottom: 1rem;"></lightning-button>
            <template if:true={successMessage}>
                <div style="padding: 1rem; margin-bottom: 1rem; background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; border-radius: 0.25rem;">
                    <p>{successMessage}</p>
                </div>
            </template>
            <template if:true={errorMessage}>
                <div style="padding: 1rem; margin-bottom: 1rem; background-color: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; border-radius: 0.25rem;">
                    <p>{errorMessage}</p>
                </div>
            </template>
        </div>
    </lightning-card>
</template>





import { LightningElement, api, track } from 'lwc';
import submitForApproval from '@salesforce/apex/ApprovalController.submitForApproval';

export default class SendForApproval extends LightningElement {
    @api recordId;
    @track successMessage = '';
    @track errorMessage = '';

    handleSendForApproval() {
        this.successMessage = '';
        this.errorMessage = '';
        
        submitForApproval({ recordId: this.recordId })
            .then(result => {
                this.successMessage = 'Record submitted for approval successfully!';
            })
            .catch(error => {
                this.errorMessage = error.body.message;
            });
    }
}



public with sharing class ApprovalController {
    @AuraEnabled
    public static void submitForApproval(Id recordId) {
        try {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitted for approval from LWC');
            req.setObjectId(recordId);
            Approval.ProcessResult result = Approval.process(req);
            
            if (!result.isSuccess()) {
                throw new AuraHandledException('Failed to submit for approval.');
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error during approval submission: ' + e.getMessage());
        }
    }
}
