
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY BadgeCount DESC) AS UserRank
    FROM 
        UserBadges
    WHERE 
        BadgeCount > 0
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(p.ViewCount) AS AverageViews,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ps.PostCount, 0) AS PostCount,
    COALESCE(ps.PositivePosts, 0) AS PositivePosts,
    COALESCE(ps.AverageViews, 0) AS AverageViews,
    COALESCE(ps.TotalComments, 0) AS TotalComments,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    tu.UserRank
FROM 
    Users u
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    TopUsers tu ON u.Id = tu.UserId
WHERE 
    (u.Reputation > 100 OR u.Views > 1000)
    AND (EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = u.Id HAVING COUNT(p.Id) > 5) 
         OR NOT EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = u.Id))
ORDER BY 
    tu.UserRank, u.DisplayName
LIMIT 100 OFFSET 0;
