SELECT 
    U.DisplayName AS UserDisplayName,
    P.Title AS PostTitle,
    PH.CreationDate AS HistoryCreationDate,
    P.Score AS PostScore
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    PostHistory PH ON PH.PostId = P.Id
WHERE 
    PH.PostHistoryTypeId = 4 
ORDER BY 
    PH.CreationDate DESC
LIMIT 10;