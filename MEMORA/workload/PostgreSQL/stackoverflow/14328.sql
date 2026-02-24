WITH Benchmark AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate
)
SELECT 
    PostId,
    Title,
    CreationDate,
    CommentCount,
    VoteCount,
    UpVoteCount,
    DownVoteCount,
    (CommentCount + VoteCount) AS EngagementScore
FROM 
    Benchmark
ORDER BY 
    EngagementScore DESC
LIMIT 10;
