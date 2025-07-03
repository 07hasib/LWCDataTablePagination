public class ShowRecordsController {
    @AuraEnabled
    public static String getAccountList(Integer pageSize, Integer pageNumber, String direction, String boundaryRecordId) {
        try {
            String jsonDT = '';
            
            System.debug('getAccountList called with pageSize: ' + pageSize + ', pageNumber: ' + pageNumber + ', direction: ' + direction + ', boundaryRecordId: ' + boundaryRecordId);
            
            if (pageSize == null || pageSize <= 0 || pageSize > 2000) {
                pageSize = 10; 
            }
            if (pageNumber == null || pageNumber <= 0) {
                pageNumber = 1;
            }
            
            Integer totalRecords = [SELECT COUNT() FROM Account];
            
            List<Account> accounts = new List<Account>();
            
            if (direction == 'next' && String.isNotBlank(boundaryRecordId)) {
                accounts = [
                    SELECT Id, Name, AccountNumber, Industry, Rating 
                    FROM Account 
                    WHERE Id > :boundaryRecordId
                    ORDER BY Id ASC 
                    LIMIT :pageSize
                ];
            } else if (direction == 'previous' && String.isNotBlank(boundaryRecordId)) {
                List<Account> tempAccounts = [
                    SELECT Id, Name, AccountNumber, Industry, Rating 
                    FROM Account 
                    WHERE Id < :boundaryRecordId
                    ORDER BY Id DESC 
                    LIMIT :pageSize
                ];
                for (Integer i = tempAccounts.size() - 1; i >= 0; i--) {
                    accounts.add(tempAccounts[i]);
                }
            } else {
                accounts = [
                    SELECT Id, Name, AccountNumber, Industry, Rating 
                    FROM Account 
                    ORDER BY Id ASC 
                    LIMIT :pageSize
                ];
            }
            
            System.debug('Query executed, returned ' + accounts.size() + ' records');
            System.debug('First record Id: ' + (accounts.size() > 0 ? accounts[0].Id : 'none'));
            System.debug('Last record Id: ' + (accounts.size() > 0 ? accounts[accounts.size() - 1].Id : 'none'));
            
            AccountDTWrapper objDT = new AccountDTWrapper();
            objDT.pageSize = pageSize;
            objDT.pageNumber = pageNumber;
            objDT.totalRecords = totalRecords;
            

            if (direction == null) {
                objDT.recordStart = 1;
                objDT.recordEnd = Math.min(accounts.size(), totalRecords);
            } else {
                objDT.recordStart = (pageNumber - 1) * pageSize + 1;
                objDT.recordEnd = objDT.recordStart + accounts.size() - 1;
            }
            
            objDT.accounts = accounts;
            objDT.firstRecordId = accounts.size() > 0 ? accounts[0].Id : null;
            objDT.lastRecordId = accounts.size() > 0 ? accounts[accounts.size() - 1].Id : null;
            
            if (totalRecords == 0) {
                objDT.totalPages = 0;
            } else {
                Integer quotient = totalRecords / pageSize;
                Integer remainder = Math.mod(totalRecords, pageSize);
                objDT.totalPages = quotient + (remainder > 0 ? 1 : 0);
            }
            
            Boolean hasNext = false;
            Boolean hasPrevious = false;
            
            if (accounts.size() > 0) {
                List<Account> nextCheck = [
                    SELECT Id FROM Account 
                    WHERE Id > :objDT.lastRecordId 
                    ORDER BY Id ASC 
                    LIMIT 1
                ];
                hasNext = nextCheck.size() > 0;
                
                List<Account> prevCheck = [
                    SELECT Id FROM Account 
                    WHERE Id < :objDT.firstRecordId 
                    ORDER BY Id DESC 
                    LIMIT 1
                ];
                hasPrevious = prevCheck.size() > 0;
            }
            
            objDT.hasNext = hasNext;
            objDT.hasPrevious = hasPrevious;
            
            System.debug('Navigation flags - hasNext: ' + hasNext + ', hasPrevious: ' + hasPrevious);
            System.debug('Page info - pageNumber: ' + pageNumber + ', recordStart: ' + objDT.recordStart + ', recordEnd: ' + objDT.recordEnd);
            
            jsonDT = JSON.serialize(objDT);
            return jsonDT;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving accounts: ' + e.getMessage());
        }
    }
    
    public class AccountDTWrapper {
        public Integer pageSize { get; set; }
        public Integer pageNumber { get; set; }
        public Integer totalRecords { get; set; }
        public Integer totalPages { get; set; }
        public Integer recordStart { get; set; }
        public Integer recordEnd { get; set; }
        public List<Account> accounts { get; set; }
        public Boolean hasNext { get; set; }
        public Boolean hasPrevious { get; set; }
        public String firstRecordId { get; set; }
        public String lastRecordId { get; set; }
    }
}
