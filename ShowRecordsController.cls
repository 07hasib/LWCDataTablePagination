public class ShowRecordsController {
    @AuraEnabled
    public static String getAccountList(Integer pageSize, Integer pageNumber) {
        try {
            String jsonDT = '';
            
            if (pageSize == null || pageSize <= 0 || pageSize > 2000) {
                pageSize = 10; 
            }
            if (pageNumber == null || pageNumber <= 0) {
                pageNumber = 1;
            }
            
            Integer totalRecords = [SELECT COUNT() FROM Account];
            
            Integer offset = (pageNumber - 1) * pageSize;
            List<Account> accounts = [
                SELECT Id, Name, AccountNumber, Industry, Rating 
                FROM Account 
                ORDER BY Id ASC 
                LIMIT :pageSize 
                OFFSET :offset
            ];
            
            AccountDTWrapper objDT = new AccountDTWrapper();
            objDT.pageSize = pageSize;
            objDT.pageNumber = pageNumber;
            objDT.totalRecords = totalRecords;
            objDT.recordStart = (pageNumber - 1) * pageSize + 1;
            objDT.recordEnd = Math.min(pageSize * pageNumber, totalRecords);
            objDT.accounts = accounts;
            
            // Calculate total pages using integer arithmetic to avoid Decimal issues
            if (totalRecords == 0) {
                objDT.totalPages = 0;
            } else {
                Integer quotient = totalRecords / pageSize;
                Integer remainder = Math.mod(totalRecords, pageSize);
                objDT.totalPages = quotient + (remainder > 0 ? 1 : 0);
            }
            
            objDT.hasNext = pageNumber < objDT.totalPages;
            objDT.hasPrevious = pageNumber > 1;
            
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
    }
}