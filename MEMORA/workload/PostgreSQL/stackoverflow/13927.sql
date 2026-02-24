
WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.ViewCount) AS AverageViewCount,
        AVG(p.Score) AS AverageScore,
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
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.CreationDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.DisplayName
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AverageViewCount,
    ps.AverageScore,
    ps.TotalAcceptedAnswers,
    us.DisplayName,
    us.TotalBadges,
    us.TotalBounty,
    us.TotalVotes
FROM 
    PostStats ps
JOIN 
    UserStats us ON us.TotalVotes > 0
ORDER BY 
    ps.AverageViewCount DESC, ps.TotalPosts DESC;
