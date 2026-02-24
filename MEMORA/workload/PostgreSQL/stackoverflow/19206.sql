SELECT 
    Id, 
    DisplayName, 
    Reputation, 
    CreationDate 
FROM 
    Users 
ORDER BY 
    Reputation DESC 
LIMIT 10;