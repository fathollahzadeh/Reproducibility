WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT v.PostId) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
VoteStats AS (
    SELECT 
        vt.Name AS VoteType,
        COUNT(v.Id) AS TotalVotes,
        AVG(v.BountyAmount) AS AvgBounty
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
    ps.AvgScore,
    ps.TotalViews,
    ps.TotalAcceptedAnswers,
    us.DisplayName AS UserDisplayName,
    us.TotalBounty,
    us.TotalVotes,
    vs.VoteType,
    vs.TotalVotes AS VoteCount,
    vs.AvgBounty
FROM 
    PostStats ps
JOIN 
    UserStats us ON us.TotalVotes > 0  
JOIN 
    VoteStats vs ON vs.TotalVotes > 0  
ORDER BY 
    ps.TotalPosts DESC;