
SELECT 
    P.Id AS PostId,
    P.Title,
    P.Body,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    COUNT(CM.Id) AS CommentCount,
    COUNT(V.Id) AS VoteCount,
    P.Score,
    P.ViewCount,
    B.Name AS BadgeName,
    COUNT(DISTINCT PH.Id) AS EditHistoryCount
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments CM ON P.Id = CM.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    P.PostTypeId = 1 
    AND P.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
GROUP BY 
    P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName, P.Score, P.ViewCount, B.Name
ORDER BY 
    P.Score DESC, P.ViewCount DESC
LIMIT 100;
