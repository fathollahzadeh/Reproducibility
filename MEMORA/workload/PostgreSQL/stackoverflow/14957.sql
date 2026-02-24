SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    COUNT(DISTINCT C.Id) AS CommentCount,
    COUNT(DISTINCT V.Id) AS VoteCount,
    COUNT(DISTINCT B.Id) AS BadgeCount,
    P.Score,
    P.ViewCount
FROM Posts P
LEFT JOIN Comments C ON P.Id = C.PostId
LEFT JOIN Votes V ON P.Id = V.PostId
LEFT JOIN Badges B ON P.OwnerUserId = B.UserId
GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
ORDER BY P.CreationDate DESC;