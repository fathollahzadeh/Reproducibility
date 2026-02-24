SELECT 
    PH.PostHistoryTypeId,
    COUNT(*) AS TotalChanges,
    MIN(PH.CreationDate) AS FirstChangeDate,
    MAX(PH.CreationDate) AS LastChangeDate,
    P.Title AS PostTitle,
    U.DisplayName AS UserDisplayName
FROM 
    PostHistory PH
JOIN 
    Posts P ON PH.PostId = P.Id
JOIN 
    Users U ON PH.UserId = U.Id
WHERE 
    PH.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    PH.PostHistoryTypeId, P.Title, U.DisplayName
ORDER BY 
    TotalChanges DESC
LIMIT 10;
