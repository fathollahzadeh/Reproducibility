SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    PH.CreationDate AS HistoryCreationDate,
    P.Score AS PostScore,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    Comments c ON P.Id = c.PostId
WHERE 
    PH.PostHistoryTypeId = 24 
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate, PH.CreationDate, P.Score
ORDER BY 
    PH.CreationDate DESC
LIMIT 10;