SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    U.Id AS UserId,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation,
    U.CreationDate AS UserCreationDate,
    U.LastAccessDate,
    U.Views AS UserViews,
    U.UpVotes,
    U.DownVotes
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId IN (1, 2)  
ORDER BY 
    P.CreationDate DESC
LIMIT 
    100;