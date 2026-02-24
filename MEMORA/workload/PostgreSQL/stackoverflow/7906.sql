WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.CommentCount) AS TotalComments
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.PostCount,
    COALESCE(bc.TotalBadges, 0) AS TotalBadges,
    ur.AcceptedAnswers,
    ur.TotalScore,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ps.TotalComments, 0) AS TotalComments
FROM 
    UserReputation ur
LEFT JOIN 
    BadgeCounts bc ON ur.UserId = bc.UserId
LEFT JOIN 
    PostStats ps ON ur.UserId = ps.OwnerUserId
ORDER BY 
    ur.Reputation DESC, 
    ur.PostCount DESC, 
    ur.TotalScore DESC
LIMIT 100;
