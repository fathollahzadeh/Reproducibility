SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    PH.CreationDate AS HistoryDate,
    P.Score AS PostScore,
    C.Score AS CommentScore
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.CreationDate >= '2023-01-01'
ORDER BY 
    PH.CreationDate DESC, C.Score DESC;
