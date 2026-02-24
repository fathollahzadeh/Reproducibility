WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        U.Reputation AS OwnerReputation
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'  
    GROUP BY 
        P.Id, U.Reputation
)

SELECT 
    *,
    ROUND((ViewCount::decimal / NULLIF(VoteCount, 0)), 2) AS ViewsPerVote,
    ROUND((ViewCount::decimal / NULLIF(CommentCount, 0)), 2) AS ViewsPerComment,
    ROUND((Score::decimal / NULLIF(CommentCount, 0)), 2) AS ScorePerComment,
    ROUND((Score::decimal / NULLIF(VoteCount, 0)), 2) AS ScorePerVote
FROM 
    PostStats
ORDER BY 
    ViewCount DESC
LIMIT 10;