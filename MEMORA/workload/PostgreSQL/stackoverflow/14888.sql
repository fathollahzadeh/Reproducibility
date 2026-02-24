SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    COALESCE(A.AcceptedAnswerId, 0) AS AcceptedAnswerId,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    C.CommentCount,
    B.BadgeCount,
    T.TagName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) B ON U.Id = B.UserId
LEFT JOIN 
    (SELECT PostId, STRING_AGG(TagName, ', ') AS TagName FROM PostLinks PL 
     JOIN Tags T ON PL.RelatedPostId = T.Id 
     GROUP BY PL.PostId) T ON P.Id = T.PostId
LEFT JOIN 
    (SELECT AcceptedAnswerId FROM Posts WHERE PostTypeId = 1) A ON P.Id = A.AcceptedAnswerId
WHERE 
    P.PostTypeId = 1 
ORDER BY 
    P.CreationDate DESC
LIMIT 100;