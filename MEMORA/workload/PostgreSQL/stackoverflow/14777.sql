WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.OwnerUserId) AS UniquePosters,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews,
        AVG(p.AnswerCount) AS AverageAnswers
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
        u.Reputation,
        COUNT(b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.UniquePosters,
    ps.TotalScore,
    ps.AverageViews,
    ps.AverageAnswers,
    us.DisplayName,
    us.Reputation,
    us.TotalBadges,
    us.TotalBounties
FROM 
    PostStats ps
JOIN 
    UserStats us ON us.Reputation > 1000 
ORDER BY 
    ps.TotalPosts DESC, us.Reputation DESC;