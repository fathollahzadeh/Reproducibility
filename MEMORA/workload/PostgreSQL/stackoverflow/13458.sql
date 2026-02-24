
SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
    (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = P.Id) AS HistoryCount,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = P.OwnerUserId) AS BadgeCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    P.Id, P.Title, U.DisplayName, P.CreationDate, P.Score, P.ViewCount
ORDER BY 
    P.Score DESC, P.CreationDate DESC
LIMIT 100;
