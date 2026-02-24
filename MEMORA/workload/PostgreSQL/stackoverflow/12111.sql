
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    PT.Name AS PostType,
    U.Id AS UserId,
    U.DisplayName AS UserDisplayName,
    U.Reputation AS UserReputation,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(DISTINCT V.Id) AS VoteCount
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, PT.Name, U.Id, U.DisplayName, U.Reputation
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
