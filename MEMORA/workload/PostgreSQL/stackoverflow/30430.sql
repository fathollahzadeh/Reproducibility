
WITH RECURSIVE UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 500
    GROUP BY 
        u.Id, u.DisplayName, b.Name, b.Class
),
PostViews AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COUNT(c.Id) AS CommentCount,
        MAX(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(AVG(p.Score), 0) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    u.DisplayName,
    ub.BadgeName,
    ub.BadgeCount,
    ps.TotalPosts,
    ps.TotalBounty,
    ps.AvgScore,
    COALESCE(pv.TotalViews, 0) AS TotalViews,
    COALESCE(pv.CommentCount, 0) AS CommentCount,
    COALESCE(pv.HasAcceptedAnswer, 0) AS HasAcceptedAnswer
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId AND ub.BadgeCount > 0
LEFT JOIN 
    UserPostStats ps ON u.Id = ps.UserId
LEFT JOIN 
    PostViews pv ON pv.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.DisplayName, ub.BadgeCount DESC
LIMIT 50;
