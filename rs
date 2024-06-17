<template>
    <lightning-card>
        <div style="padding: 1rem;">
            <lightning-input 
                label="Issue" 
                value={issue} 
                onchange={handleInputChange} 
                name="issue"
                required>
            </lightning-input>
            
            <lightning-record-picker
                label="Part Code"
                placeholder="Search Products..."
                object-api-name="Product2"
                onchange={handleProductChange}
                required>
            </lightning-record-picker>
            
            <lightning-input 
                label="Model Number" 
                value={modelNumber} 
                onchange={handleInputChange} 
                name="modelNumber"
                required>
            </lightning-input>
            
            <lightning-input 
                label="Reason for Replacement" 
                value={reasonForReplacement} 
                onchange={handleInputChange} 
                name="reasonForReplacement"
                required>
            </lightning-input>
            
            <lightning-input 
                label="Quantity" 
                type="number" 
                value={quantity} 
                onchange={handleInputChange} 
                name="quantity"
                required>
            </lightning-input>
            
            <lightning-combobox 
                label="Address of Material Delivery" 
                options={deliveryOptions} 
                value={selectedDeliveryOption} 
                onchange={handleInputChange} 
                name="selectedDeliveryOption"
                required>
            </lightning-combobox>
            
            <lightning-input 
                label="Upload Photo with Serial Number" 
                type="file" 
                onchange={handleFileChange} 
                name="serialNumberFile">
            </lightning-input>
            
            <lightning-input 
                label="Customer Invoice Photograph" 
                type="file" 
                onchange={handleFileChange} 
                name="invoiceFile">
            </lightning-input>
            
            <lightning-button 
                label="Save" 
                variant="brand" 
                onclick={handleSave}
                style="margin-top: 1rem;">
            </lightning-button>

            <!-- Spinner -->
            <template if:true={isLoading}>
                <lightning-spinner alternative-text="Saving..." size="medium" style="margin-top: 1rem;"></lightning-spinner>
            </template>
        </div>
    </lightning-card>
</template>




import { LightningElement, track, api } from 'lwc';
import saveFormData from '@salesforce/apex/RequestSparesController.saveFormData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RequestSpare extends LightningElement {
    @track issue;
    @track partCode; // Will store the selected product ID
    @track modelNumber;
    @track reasonForReplacement;
    @track quantity;
    @track selectedDeliveryOption;
    @track serialNumberFile;
    @track invoiceFile;
    @api recordId; // Assume this is the work order ID or related record ID
    @track isLoading = false; // Track loading state

    deliveryOptions = [
        { label: 'ASP', value: 'ASP' },
        { label: 'Customer', value: 'Customer' }
    ];

    handleInputChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
    }

    handleProductChange(event) {
        // Assuming the event provides the record ID of the selected product
        this.partCode = event.detail.recordId;
    }

    handleFileChange(event) {
        const field = event.target.name;
        const file = event.target.files[0];
        
        const reader = new FileReader();
        reader.onload = () => {
            this[field] = reader.result.split(',')[1]; // Get base64 string
        };
        reader.onerror = () => {
            this.showToast('Error', `Error reading file: ${file.name}`, 'error');
        };
        reader.readAsDataURL(file);
    }

    handleSave() {
        if (!this.validateFields()) {
            this.showToast('Error', 'Please fill in all required fields.', 'error');
            return;
        }

        this.isLoading = true; // Show spinner
        try {
            saveFormData({
                issue: this.issue,
                partCode: this.partCode,
                modelNumber: this.modelNumber,
                reasonForReplacement: this.reasonForReplacement,
                quantity: parseInt(this.quantity, 10),
                selectedDeliveryOption: this.selectedDeliveryOption,
                workOrderId: this.recordId,
                serialNumberFile: this.serialNumberFile,
                invoiceFile: this.invoiceFile
            })
            .then(result => {
                this.showToast('Success', 'Form data saved successfully.', 'success');
                this.isLoading = false; // Hide spinner
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false; // Hide spinner
            });
        } catch (error) {
            this.showToast('Error', `An unexpected error occurred: ${error.message}`, 'error');
            this.isLoading = false; // Hide spinner
        }
    }

    validateFields() {
        const requiredFields = ['issue', 'partCode', 'modelNumber', 'reasonForReplacement', 'quantity', 'selectedDeliveryOption'];
        return requiredFields.every(field => {
            return this[field] && this[field].trim() !== '';
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}



public class RequestSparesController {
    
    @AuraEnabled
    public static String saveFormData(
        String issue,
        String partCode,
        String modelNumber,
        String reasonForReplacement,
        Integer quantity,
        String selectedDeliveryOption,
        String workOrderId,
        String serialNumberFile,
        String invoiceFile
    ) {
        try {
            // Create a new ProductRequest record
            ProductRequest productRequest = new ProductRequest();
            productRequest.Status = 'Draft';
          //  productRequest.RequestedQuantity = quantity;
          //  productRequest.DeliveryOption = selectedDeliveryOption;
            productRequest.WorkOrderId = workOrderId;
            System.debug('PArtCode-->' + partCode);
            // Insert the ProductRequest record
            insert productRequest;
            
            // Create a new ProductRequestLineItem record
            ProductRequestLineItem productRequestLineItem = new ProductRequestLineItem();
            productRequestLineItem.ParentId = productRequest.Id;
            productRequestLineItem.QuantityRequested = quantity;
            productRequestLineItem.Product2Id = partCode;
            //productRequestLineItem.ReasonForReplacement = reasonForReplacement;
            //productRequestLineItem.PartCode = partCode;
            //productRequestLineItem.ModelNumber = modelNumber;
            
            // Insert the ProductRequestLineItem record
            insert productRequestLineItem;

            // Handle file uploads (if provided)
            if (serialNumberFile != null && serialNumberFile != '') {
                saveFile(serialNumberFile, productRequest.Id, 'Serial_Number_Photo');
            }
            if (invoiceFile != null && invoiceFile != '') {
                saveFile(invoiceFile, productRequest.Id, 'Invoice_Photo');
            }
            
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static void saveFile(String base64File, Id parentId, String fileNamePrefix) {
        if (base64File != null && base64File != '') {
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = fileNamePrefix + '_' + parentId;
            contentVersion.PathOnClient = fileNamePrefix + '.jpg'; // Assuming a jpg file, adjust as needed
            contentVersion.VersionData = EncodingUtil.base64Decode(base64File);
            contentVersion.FirstPublishLocationId = parentId;
            insert contentVersion;
        }
    }
}




