<template>
    <!-- Optional: Minimal UI, can be left empty if only toast messages are used -->
    <template if:true={isProcessing}>
        <lightning-spinner alternative-text="Processing" size="medium"></lightning-spinner>
    </template>
</template>



import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendRecordForApproval from '@salesforce/apex/ApprovalProcessHandler.sendRecordForApproval';

export default class SendForApproval extends LightningElement {
    @api recordId;
    isProcessing = true;  // To show a spinner or similar indicator

    connectedCallback() {
        this.initiateApprovalProcess();
    }

    initiateApprovalProcess() {
        sendRecordForApproval({ recordId: this.recordId })
            .then(() => {
                this.showToast('Success', 'Record sent for approval successfully.', 'success');
            })
            .catch(error => {
                this.showToast('Error', 'Failed to send record for approval: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isProcessing = false;
                this.closeQuickAction();
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    closeQuickAction() {
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}




public with sharing class ApprovalProcessHandler {
    @AuraEnabled
    public static void sendRecordForApproval(Id recordId) {
        try {
            // Initialize the approval request
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Automatically sending for approval.');
            req.setObjectId(recordId);

            // Optionally specify the next approver if required
            // req.setNextApproverIds(new List<Id>{ someUserId });

            // Send the approval request
            Approval.ProcessResult result = Approval.process(req);
            
            // You could log the result or handle it based on your business needs
            System.debug('Approval request has been sent with the following result: ' + result);
        } catch (Exception e) {
            // Handle the exception
            System.debug('Error while sending record for approval: ' + e.getMessage());
            throw new AuraHandledException('Approval Process Error: ' + e.getMessage());
        }
    }
}
