SELECT 
    U.DisplayName AS UserDisplayName,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    PH.CreationDate AS HistoryCreationDate,
    P.Body AS PostBody,
    COUNT(C.ID) AS CommentCount
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    PH.PostHistoryTypeId IN (4, 6) 
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate, PH.CreationDate, P.Body
ORDER BY 
    PH.CreationDate DESC;