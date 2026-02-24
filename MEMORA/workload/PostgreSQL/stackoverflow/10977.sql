
SELECT 
    P.Id AS PostId,
    P.Title,
    PT.Name AS PostType,
    U.DisplayName AS OwnerDisplayName,
    COUNT(C.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS VoteCount,
    COUNT(DISTINCT B.Id) AS BadgeCount,
    COALESCE(NULLIF(P.Score, 0), 0) AS Score,
    P.ViewCount,
    P.CreationDate,
    P.LastActivityDate,
    (SELECT COUNT(*) FROM Posts WHERE ParentId = P.Id) AS AnswerCount
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
GROUP BY 
    P.Id, P.Title, PT.Name, U.DisplayName, P.ViewCount, P.CreationDate, P.LastActivityDate
ORDER BY 
    P.LastActivityDate DESC;
