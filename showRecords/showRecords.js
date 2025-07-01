import { LightningElement, wire, api, track } from 'lwc';
import getAccountList from '@salesforce/apex/ShowRecordsController.getAccountList';

export default class ShowRecords extends LightningElement {
    @track loader = false;
    @track error = null;
    @track pageSize = 10; 
    @track pageNumber = 1;
    @track totalRecords = 0;
    @track totalPages = 0;
    @track recordEnd = 0;
    @track recordStart = 0;
    @track isPrev = true;
    @track isNext = true;
    @track accounts = [];

    get columns() {
        return [
            { label: 'Name', fieldName: 'Name', type: 'text', sortable: true },
            { label: 'Account Number', fieldName: 'AccountNumber', type: 'text', sortable: true },
            { label: 'Industry', fieldName: 'Industry', type: 'text', sortable: true },
            { 
                label: 'Rating', 
                fieldName: 'Rating', 
                type: 'text', 
                sortable: true,
                cellAttributes: {
                    class: { fieldName: 'ratingClass' }
                }
            }
        ];
    }

    get pageSizeOptions() {
        return [
            { label: '25', value: 25 },
            { label: '50', value: 50 },
            { label: '100', value: 100 },
            { label: '200', value: 200 }
        ];
    }


    connectedCallback() {
        this.getAccounts();
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value);
        this.pageNumber = 1;
        this.getAccounts();
    }

    handleNext() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.getAccounts();
        }
    }

    handlePrev() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.getAccounts();
        }
    }

    getAccounts() {
        this.loader = true;
        this.error = null;
        getAccountList({ 
            pageSize: this.pageSize, 
            pageNumber: this.pageNumber
        })
            .then(result => {
                this.loader = false;
                if (result) {
                    var resultData = JSON.parse(result);
                    // Process accounts to add rating styling
                    this.accounts = resultData.accounts.map(account => {
                        return {
                            ...account,
                            ratingClass: this.getRatingClass(account.Rating)
                        };
                    });
                    this.totalRecords = resultData.totalRecords;
                    this.recordStart = resultData.recordStart;
                    this.recordEnd = resultData.recordEnd;
                    this.totalPages = resultData.totalPages;
                    this.isNext = !resultData.hasNext;
                    this.isPrev = !resultData.hasPrevious;
                }
            })
            .catch(error => {
                this.loader = false;
                this.error = error;
                console.error('Error fetching accounts:', error);
            });
    }

    // Method to determine CSS class based on rating
    getRatingClass(rating) {
        if (!rating) return '';
        
        switch(rating.toLowerCase()) {
            case 'hot':
                return 'rating-hot';
            case 'warm':
                return 'rating-warm';
            case 'cold':
                return 'rating-cold';
            default:
                return '';
        }
    }

    handleRowAction(event) {
    }

    get isDisplayNoRecords() {
        return this.accounts && this.accounts.length === 0;
    }
}