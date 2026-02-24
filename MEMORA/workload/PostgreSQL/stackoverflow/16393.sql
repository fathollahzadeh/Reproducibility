
SELECT 
    P.Title,
    P.CreationDate,
    U.DisplayName AS Author,
    COUNT(C.Id) AS CommentCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.PostTypeId = 1
GROUP BY 
    P.Title, P.CreationDate, U.DisplayName
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
