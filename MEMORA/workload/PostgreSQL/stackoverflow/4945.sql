WITH UserBadgeStats AS (
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
PostStatistics AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPosts
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostPerformance AS (
    SELECT 
        ub.DisplayName,
        ub.BadgeCount,
        ps.PostCount,
        ps.AverageScore,
        ps.TotalViews,
        ps.ClosedPosts,
        RANK() OVER (ORDER BY ps.PostCount DESC) AS PostRank
    FROM 
        UserBadgeStats ub
    JOIN 
        PostStatistics ps ON ub.UserId = ps.OwnerUserId
)
SELECT 
    upp.DisplayName,
    upp.BadgeCount,
    upp.PostCount,
    upp.AverageScore,
    upp.TotalViews,
    upp.ClosedPosts,
    CASE 
        WHEN upp.ClosedPosts > 0 THEN TRUE
        ELSE FALSE
    END AS HasClosedPosts,
    CASE 
        WHEN upp.PostCount > 0 THEN CAST(upp.ClosedPosts AS DECIMAL) / upp.PostCount
        ELSE NULL
    END AS ClosedPostPercentage
FROM 
    UserPostPerformance upp
WHERE 
    upp.BadgeCount > 1 
    AND upp.PostCount > 5
ORDER BY 
    upp.PostRank, upp.DisplayName;
