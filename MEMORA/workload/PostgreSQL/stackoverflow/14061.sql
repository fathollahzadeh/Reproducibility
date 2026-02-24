SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.Score,
    P.ViewCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    COUNT(C.Id) AS CommentCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
    T.TagName AS PostTag,
    PT.Name AS PostTypeName
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
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName, U.Reputation, T.TagName, PT.Name
ORDER BY 
    P.CreationDate DESC
LIMIT 100;