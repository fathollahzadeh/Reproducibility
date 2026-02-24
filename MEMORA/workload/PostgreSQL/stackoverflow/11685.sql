SELECT 
    PH.PostHistoryTypeId, 
    COUNT(*) AS TotalChanges,
    MIN(PH.CreationDate) AS FirstChangeDate,
    MAX(PH.CreationDate) AS LastChangeDate,
    U.DisplayName AS EditorName
FROM 
    PostHistory PH
JOIN 
    Users U ON PH.UserId = U.Id
GROUP BY 
    PH.PostHistoryTypeId, U.DisplayName
ORDER BY 
    TotalChanges DESC;
