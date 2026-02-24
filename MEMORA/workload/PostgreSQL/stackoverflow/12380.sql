
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    COALESCE(C.CommentCount, 0) AS CommentCount,
    COALESCE(V.UpVotes, 0) AS UpVotes,
    COALESCE(V.DownVotes, 0) AS DownVotes,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    COALESCE(PT.Name, 'N/A') AS PostTypeName
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) C ON P.Id = C.PostId
LEFT JOIN 
    (SELECT PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
     FROM Votes 
     GROUP BY PostId) V ON P.Id = V.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount 
     FROM Badges 
     GROUP BY UserId) B ON U.Id = B.UserId
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
WHERE 
    P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
ORDER BY 
    P.CreationDate DESC;
