WITH RankedUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    WHERE u.Reputation > 1000
),

RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),

UserPostStats AS (
    SELECT 
        ru.UserId,
        ru.DisplayName,
        COUNT(rp.PostId) AS PostCount,
        COALESCE(SUM(rp.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(rp.Score), 0) AS TotalScore
    FROM RankedUsers ru
    LEFT JOIN RecentPosts rp ON ru.UserId = rp.OwnerUserId
    GROUP BY ru.UserId, ru.DisplayName
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.TotalViews,
    ups.TotalScore,
    ru.Rank
FROM UserPostStats ups
JOIN RankedUsers ru ON ups.UserId = ru.UserId
ORDER BY ups.TotalScore DESC, ups.TotalViews DESC, ups.PostCount DESC;