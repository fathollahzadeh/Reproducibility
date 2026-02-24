
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(U.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, U.DisplayName
),
AverageMetrics AS (
    SELECT 
        AVG(Score) AS AvgScore,
        AVG(ViewCount) AS AvgViewCount,
        AVG(CommentCount) AS AvgCommentCount,
        AVG(UpVoteCount) AS AvgUpVoteCount,
        AVG(DownVoteCount) AS AvgDownVoteCount
    FROM 
        PostMetrics
)
SELECT 
    PM.PostId,
    PM.Title,
    PM.CreationDate,
    PM.Score,
    PM.ViewCount,
    PM.AnswerCount,
    PM.OwnerDisplayName,
    PM.CommentCount,
    PM.UpVoteCount,
    PM.DownVoteCount,
    AM.AvgScore,
    AM.AvgViewCount,
    AM.AvgCommentCount,
    AM.AvgUpVoteCount,
    AM.AvgDownVoteCount
FROM 
    PostMetrics PM
CROSS JOIN 
    AverageMetrics AM
ORDER BY 
    PM.Score DESC;
