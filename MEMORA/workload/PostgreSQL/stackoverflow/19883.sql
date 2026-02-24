SELECT 
    U.DisplayName AS UserDisplayName,
    P.Title AS PostTitle,
    PH.CreationDate AS HistoryCreationDate,
    P.CreationDate AS PostCreationDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    PH.PostHistoryTypeId IN (1, 2, 4, 5) 
ORDER BY 
    PH.CreationDate DESC
LIMIT 100;