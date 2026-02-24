
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalClosedPosts
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
RecentActivity AS (
    SELECT 
        OwnerUserId, 
        MAX(LastActivityDate) AS LastActivity
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ps.TotalPosts,
        ps.TotalViews,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.TotalClosedPosts,
        ra.LastActivity,
        CASE 
            WHEN ub.GoldBadges > 0 THEN 'Gold Member' 
            WHEN ub.SilverBadges > 0 THEN 'Silver Member'
            WHEN ub.BronzeBadges > 0 THEN 'Bronze Member'
            ELSE 'Regular Member' 
        END AS MembershipType
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        RecentActivity ra ON u.Id = ra.OwnerUserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.MembershipType,
    up.TotalPosts,
    up.TotalViews,
    up.TotalClosedPosts,
    CONCAT('Last active on: ', COALESCE(CAST(up.LastActivity AS VARCHAR), 'No activity recorded')) AS LastActivityInfo,
    (SELECT COUNT(*) FROM (
        SELECT DISTINCT c.PostId 
        FROM Comments c 
        WHERE c.UserId = up.UserId
    ) AS CommentedPosts) AS TotalCommentedPosts,
    (SELECT AVG(ps.Score) 
     FROM Posts ps 
     WHERE ps.OwnerUserId = up.UserId 
     AND ps.Score IS NOT NULL) AS AvgPostScore
FROM 
    UserPerformance up
WHERE 
    up.TotalPosts > 0
ORDER BY 
    up.TotalPosts DESC, 
    up.TotalViews DESC;
