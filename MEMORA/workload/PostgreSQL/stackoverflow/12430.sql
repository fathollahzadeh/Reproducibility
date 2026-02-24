SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    V.Count AS VoteCount,
    T.TagName,
    BH.Date AS BadgeDate,
    BH.Name AS BadgeName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS Count FROM Votes GROUP BY PostId) V ON P.Id = V.PostId
LEFT JOIN 
    PostLinks PL ON P.Id = PL.PostId
LEFT JOIN 
    Tags T ON PL.RelatedPostId = T.Id
LEFT JOIN 
    Badges BH ON U.Id = BH.UserId
WHERE 
    P.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    P.Score DESC, P.CreationDate ASC
LIMIT 100;