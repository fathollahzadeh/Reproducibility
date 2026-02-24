
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(COUNT(A.Id), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(C.Id), 0) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND P.PostTypeId = 1  
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= '2023-01-01'  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
),
AverageMetrics AS (
    SELECT 
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        AVG(AnswerCount) AS AvgAnswerCount,
        AVG(CommentCount) AS AvgCommentCount,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
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
    PM.UpVotes,
    PM.DownVotes,
    AM.AvgViewCount,
    AM.AvgScore,
    AM.AvgAnswerCount,
    AM.AvgCommentCount,
    AM.TotalUpVotes,
    AM.TotalDownVotes
FROM 
    PostMetrics PM, 
    AverageMetrics AM
ORDER BY 
    PM.ViewCount DESC;
