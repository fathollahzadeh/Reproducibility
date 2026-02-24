
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        PT.Name AS PostType,
        COALESCE(MAX(Vote.UserId), -1) AS LastVoterId
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Votes Vote ON P.Id = Vote.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName, PT.Name
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.OwnerDisplayName,
    PS.PostType,
    PS.CommentCount,
    PS.AnswerCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PS.PostId) AS TotalVotes
FROM 
    PostStatistics PS
ORDER BY 
    PS.CreationDate DESC
LIMIT 100;
