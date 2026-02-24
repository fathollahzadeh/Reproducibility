SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.AnswerCount,
    U.DisplayName AS OwnerDisplayName,
    PH.PostHistoryTypeId,
    PH.CreationDate AS HistoryCreationDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    PH.CreationDate >= '2023-01-01' 
ORDER BY 
    P.ViewCount DESC, 
    PH.CreationDate DESC
LIMIT 100;
