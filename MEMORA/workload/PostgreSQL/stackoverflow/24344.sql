
WITH UserBadgeSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
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
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AverageViewCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
TopUsersByBadges AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.TotalBadges,
        ps.PostCount,
        ps.TotalScore,
        ps.AverageViewCount,
        ROW_NUMBER() OVER (ORDER BY u.TotalBadges DESC, ps.TotalScore DESC) AS BadgeRank
    FROM 
        UserBadgeSummary u
    JOIN 
        PostStatistics ps ON u.UserId = ps.OwnerUserId
)
SELECT
    u.UserId,
    u.DisplayName,
    COALESCE(u.TotalBadges, 0) AS TotalBadges,
    COALESCE(ps.PostCount, 0) AS PostCount,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    ROUND(COALESCE(ps.AverageViewCount, 0), 2) AS AverageViewCount,
    u.BadgeRank
FROM 
    TopUsersByBadges u
LEFT JOIN 
    PostStatistics ps ON u.UserId = ps.OwnerUserId
WHERE 
    COALESCE(u.TotalBadges, 0) > 0
ORDER BY 
    u.BadgeRank DESC, u.TotalBadges DESC
LIMIT 10;
