WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS UserReputation,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, u.Reputation
),

PopularPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        AnswerCount,
        UserReputation,
        VoteCount,
        RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY Score DESC) AS ScoreRank
    FROM 
        PostStats
)

SELECT 
    PostId,
    Title,
    ViewCount,
    Score,
    AnswerCount,
    UserReputation,
    VoteCount,
    ViewRank,
    ScoreRank
FROM 
    PopularPosts
WHERE 
    ViewRank <= 10 OR ScoreRank <= 10
ORDER BY 
    ViewRank, ScoreRank;