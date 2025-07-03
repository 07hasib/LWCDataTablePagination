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
    @track firstRecordId = null;
    @track lastRecordId = null;
    @track currentDirection = null; 

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
        this.firstRecordId = null;
        this.lastRecordId = null;
        this.currentDirection = null;
        this.getAccounts();
    }

    handleNext() {
        if (!this.isNext) {
            this.pageNumber++;
            this.currentDirection = 'next';
            this.getAccountsWithDirection('next', this.lastRecordId);
        }
    }

    handlePrev() {
        if (!this.isPrev) {
            this.pageNumber--;
            this.currentDirection = 'previous';
            this.getAccountsWithDirection('previous', this.firstRecordId);
        }
    }

    getAccounts() {
        this.currentDirection = null;
        this.getAccountsWithDirection(null, null);
    }

    getAccountsWithDirection(direction, boundaryRecordId) {
        this.loader = true;
        this.error = null;
        getAccountList({ 
            pageSize: this.pageSize, 
            pageNumber: this.pageNumber,
            direction: direction,
            boundaryRecordId: boundaryRecordId
        })
            .then(result => {
                this.loader = false;
                if (result) {
                    var resultData = JSON.parse(result);
                    
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
                    this.firstRecordId = resultData.firstRecordId;
                    this.lastRecordId = resultData.lastRecordId;
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