WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.AnswerCount) AS AvgAnswerCount,
        AVG(p.CommentCount) AS AvgCommentCount,
        MIN(p.CreationDate) AS FirstPostDate,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

UserStats AS (
    SELECT 
        COUNT(u.Id) AS TotalUsers,
        AVG(u.Reputation) AS AvgReputation,
        MIN(u.CreationDate) AS FirstUserDate,
        MAX(u.CreationDate) AS LastUserDate
    FROM 
        Users u
),

VoteStats AS (
    SELECT 
        vt.Name AS VoteType,
        COUNT(v.Id) AS TotalVotes,
        AVG(v.BountyAmount) AS AvgBountyAmount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        vt.Name
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.PositiveScorePosts,
    ps.NegativeScorePosts,
    ps.AvgViewCount,
    ps.AvgAnswerCount,
    ps.AvgCommentCount,
    ps.FirstPostDate,
    ps.LastPostDate,
    us.TotalUsers,
    us.AvgReputation,
    us.FirstUserDate,
    us.LastUserDate,
    vs.VoteType,
    vs.TotalVotes,
    vs.AvgBountyAmount
FROM 
    PostStats ps,
    UserStats us,
    VoteStats vs
ORDER BY 
    ps.TotalPosts DESC;