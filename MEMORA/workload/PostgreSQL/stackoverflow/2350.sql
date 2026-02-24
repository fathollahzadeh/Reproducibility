WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.Score) AS AverageScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostHistoryRank AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS EditCount,
        RANK() OVER (PARTITION BY ph.UserId ORDER BY COUNT(*) DESC) AS UserEditRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY ph.UserId
)
SELECT 
    us.DisplayName,
    us.PostCount,
    us.PositivePosts,
    us.NegativePosts,
    COALESCE(bc.GoldBadges, 0) AS GoldBadges,
    COALESCE(bc.SilverBadges, 0) AS SilverBadges,
    COALESCE(bc.BronzeBadges, 0) AS BronzeBadges,
    us.AverageScore,
    COALESCE(phr.EditCount, 0) AS EditCount,
    phr.UserEditRank
FROM UserStats us
LEFT JOIN BadgeCounts bc ON us.UserId = bc.UserId
LEFT JOIN PostHistoryRank phr ON us.UserId = phr.UserId
WHERE us.PostCount > 0
ORDER BY us.AverageScore DESC, us.PostCount DESC
FETCH FIRST 10 ROWS ONLY;