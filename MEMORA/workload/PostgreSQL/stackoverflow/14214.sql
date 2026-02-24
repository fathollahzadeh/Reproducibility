
SELECT 
    P.Id AS PostId,
    P.Title,
    P.Body,
    P.CreationDate AS PostCreationDate,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    U.Id AS UserId,
    U.DisplayName AS UserDisplayName,
    U.Reputation AS UserReputation,
    T.TagName,
    COUNT(C.Id) AS CommentCountPerPost
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    Tags T ON P.Tags LIKE CONCAT('%,', T.TagName, ',%')
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE
    P.CreationDate >= '2023-01-01'  
GROUP BY 
    P.Id, P.Title, P.Body, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount, P.CommentCount, P.FavoriteCount, 
    U.Id, U.DisplayName, U.Reputation, 
    T.TagName
ORDER BY 
    P.CreationDate DESC
LIMIT 
    100;
