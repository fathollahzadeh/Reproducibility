SELECT 
    P.Id AS PostId,
    P.Title,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    (SELECT COUNT(*) 
     FROM Comments C 
     WHERE C.PostId = P.Id) AS TotalComments,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVotes
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
ORDER BY 
    P.CreationDate DESC
LIMIT 100;