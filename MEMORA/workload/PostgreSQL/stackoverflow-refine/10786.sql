SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    COUNT(CASE WHEN C.PostId = P.Id THEN 1 END) AS CommentCount,
    COUNT(CASE WHEN V.PostId = P.Id THEN 1 END) AS VoteCount,
    T.TagName,
    PT.Name AS PostType,
    BH.UserDisplayName AS LastEditedBy,
    BH.CreationDate AS LastEditedDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Tags T ON T.ExcerptPostId = P.Id
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    PostHistory BH ON P.Id = BH.PostId 
WHERE 
    P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
GROUP BY 
    P.Id, U.DisplayName, P.Title, P.CreationDate, P.ViewCount, P.Score, T.TagName, PT.Name, BH.UserDisplayName, BH.CreationDate
ORDER BY 
    P.CreationDate DESC;