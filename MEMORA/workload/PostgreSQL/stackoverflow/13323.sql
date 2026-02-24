SELECT 
    PH.PostHistoryTypeId, 
    P.Title, 
    COUNT(*) AS ChangeCount, 
    MIN(PH.CreationDate) AS FirstChangeDate, 
    MAX(PH.CreationDate) AS LastChangeDate
FROM 
    PostHistory PH
JOIN 
    Posts P ON PH.PostId = P.Id
WHERE 
    PH.CreationDate BETWEEN '2023-01-01' AND '2023-10-31'
GROUP BY 
    PH.PostHistoryTypeId, P.Title
ORDER BY 
    ChangeCount DESC, FirstChangeDate DESC;
