
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount,
        AVG(p.AnswerCount) AS AverageAnswerCount,
        AVG(p.CommentCount) AS AverageCommentCount
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(u.Reputation) AS AverageReputation,
        MAX(u.LastAccessDate) AS MostRecentAccessDate
    FROM 
        Users u
),
VoteStats AS (
    SELECT 
        v.VoteTypeId,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.VoteTypeId
)

SELECT 
    ps.PostTypeId,
    ps.TotalPosts,
    ps.TotalScore,
    ps.AverageViewCount,
    ps.AverageAnswerCount,
    ps.AverageCommentCount,
    us.TotalUsers,
    us.AverageReputation,
    us.MostRecentAccessDate,
    vs.VoteTypeId,
    vs.TotalVotes
FROM 
    PostStats ps
JOIN 
    UserStats us ON TRUE  
JOIN 
    VoteStats vs ON TRUE  
ORDER BY 
    ps.PostTypeId, vs.VoteTypeId;
