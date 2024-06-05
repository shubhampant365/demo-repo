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



import { LightningElement, api, track } from 'lwc';
import sendRecordForApproval from '@salesforce/apex/ApprovalProcessHandler.sendRecordForApproval';

export default class SendForApproval extends LightningElement {
    @api recordId;
    @track isProcessing = true;
    @track message = '';

    connectedCallback() {
        if (!this.recordId) {
            this.message = 'Record ID is not available.';
            this.isProcessing = false;
            return;
        }
        this.sendForApproval();
    }

    sendForApproval() {
        sendRecordForApproval({ recordId: this.recordId })
            .then(() => {
                this.message = 'Record sent for approval successfully.';
                this.isProcessing = false;
            })
            .catch(error => {
                this.message = 'Failed to send record for approval: ' + error.body.message;
                this.isProcessing = false;
            });
    }
}


public with sharing class ApprovalProcessHandler {
    @AuraEnabled
    public static void sendRecordForApproval(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('The recordId is null.');
        }

        try {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Automatically sending for approval.');
            req.setObjectId(recordId);
            req.setProcessDefinitionNameOrId('Your_Process_Developer_Name'); // Replace with the actual name

            Approval.ProcessResult result = Approval.process(req);
            if (!result.isSuccess()) {
                throw new AuraHandledException('Approval process failed to complete successfully.');
            }
        } catch (Exception e) {
            throw new AuraHandledException('Approval Process Error: ' + e.getMessage());
        }
    }
}<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata" fqn="sendForApproval">
    <apiVersion>52.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordPage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects>
                <object>ServiceAppointment</object>
            </objects>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>



