SELECT 
    PH.PostHistoryTypeId,
    COUNT(PH.Id) AS HistoryCount,
    MIN(PH.CreationDate) AS FirstOccurrence,
    MAX(PH.CreationDate) AS LastOccurrence,
    U.DisplayName AS UserDisplayName
FROM 
    PostHistory PH
JOIN 
    Users U ON PH.UserId = U.Id
GROUP BY 
    PH.PostHistoryTypeId, U.DisplayName
ORDER BY 
    HistoryCount DESC;
