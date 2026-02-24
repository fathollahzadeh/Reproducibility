
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1 AND 
        p.ViewCount > 25 
),

UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),

UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ubc.BadgeCount, 0) AS TotalBadges,
        COALESCE(upc.PostCount, 0) AS TotalPosts,
        COALESCE(upc.AnswerCount, 0) AS TotalAnswers,
        COALESCE(pb.PostId, 0) AS PopularPostId,
        CASE 
            WHEN COALESCE(ubc.BadgeCount, 0) > 10 THEN 'Expert'
            WHEN COALESCE(upc.PostCount, 0) > 20 THEN 'Active Contributor'
            ELSE 'Newbie'
        END AS UserCategory
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCounts ubc ON u.Id = ubc.UserId
    LEFT JOIN 
        UserPostCounts upc ON u.Id = upc.UserId
    LEFT JOIN 
        PopularPosts pb ON u.Id = pb.OwnerUserId AND pb.PostRank = 1
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalBadges,
    us.TotalPosts,
    us.TotalAnswers,
    (SELECT COUNT(DISTINCT p.Id)
     FROM Posts p
     WHERE p.OwnerUserId = us.UserId AND p.ClosedDate IS NULL) AS ActivePostCount,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Posts p
     JOIN Tags t ON t.WikiPostId = p.Id
     WHERE p.OwnerUserId = us.UserId) AS AssociatedTags,
    us.UserCategory
FROM 
    UserStatistics us
LEFT JOIN 
    Users u ON us.UserId = u.Id
WHERE 
    us.PopularPostId > 0 AND
    (us.TotalBadges > 0 OR us.TotalPosts > 0)
ORDER BY 
    us.TotalBadges DESC, us.TotalPosts DESC;
