
WITH UserReputationHistory AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS rn
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Posts p
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ur.BadgeCount, 0) AS BadgeCount,
        COALESCE(pa.PostCount, 0) AS PostCount,
        COALESCE(pa.TotalViews, 0) AS TotalViews,
        COALESCE(pa.AverageScore, 0) AS AverageScore,
        pa.LastActivity
    FROM 
        Users u
    LEFT JOIN 
        UserReputationHistory ur ON u.Id = ur.UserId AND ur.rn = 1
    LEFT JOIN 
        PostActivity pa ON u.Id = pa.OwnerUserId
)
SELECT 
    a.UserId,
    a.DisplayName,
    a.Reputation,
    a.BadgeCount,
    a.PostCount,
    a.TotalViews,
    a.AverageScore,
    a.LastActivity,
    CASE 
        WHEN a.Reputation > 1000 AND a.BadgeCount > 5 THEN 'Active Contributor'
        WHEN a.TotalViews > 10000 THEN 'Popular User'
        WHEN a.LastActivity IS NULL THEN 'Inactive'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    ActiveUsers a
LEFT JOIN 
    PostHistory ph ON a.UserId = ph.UserId
WHERE 
    ph.UserId IS NULL OR ph.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
ORDER BY 
    a.Reputation DESC, a.PostCount DESC;
