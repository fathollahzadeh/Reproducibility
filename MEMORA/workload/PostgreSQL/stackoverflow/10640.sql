WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostsByUsers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        COUNT(Id) AS TotalUsers,
        SUM(Reputation) AS TotalReputation,
        AVG(Reputation) AS AverageReputation
    FROM 
        Users
),
CommentStats AS (
    SELECT 
        COUNT(Id) AS TotalComments,
        AVG(Score) AS AverageCommentScore
    FROM 
        Comments
),
VoteStats AS (
    SELECT 
        COUNT(Id) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.PostsByUsers,
    ps.PositiveScorePosts,
    ps.AverageScore,
    ps.TotalViews,
    us.TotalUsers,
    us.TotalReputation,
    us.AverageReputation,
    cs.TotalComments,
    cs.AverageCommentScore,
    vs.TotalVotes,
    vs.UpVotes,
    vs.DownVotes
FROM 
    PostStats ps,
    UserStats us,
    CommentStats cs,
    VoteStats vs
ORDER BY 
    ps.TotalPosts DESC;