SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    PT.Name AS PostType,
    U.DisplayName AS OwnerDisplayName,
    COALESCE(V.UpVotesCount, 0) AS UpVotesCount,
    COALESCE(V.DownVotesCount, 0) AS DownVotesCount,
    COALESCE(B.BadgeCount, 0) AS BadgeCount
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT 
         PostId, 
         SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
         SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
     FROM 
         Votes
     GROUP BY 
         PostId) V ON P.Id = V.PostId
LEFT JOIN 
    (SELECT 
         UserId, 
         COUNT(*) AS BadgeCount
     FROM 
         Badges
     GROUP BY 
         UserId) B ON U.Id = B.UserId
ORDER BY 
    P.CreationDate DESC
LIMIT 100;