SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    PH.CreationDate AS EditDate,
    PH.Comment AS EditComment
FROM 
    Posts P
JOIN 
    PostHistory PH ON P.Id = PH.PostId
JOIN 
    Users U ON PH.UserId = U.Id
WHERE 
    PH.PostHistoryTypeId IN (4, 5, 6) 
ORDER BY 
    PH.CreationDate DESC
LIMIT 10;