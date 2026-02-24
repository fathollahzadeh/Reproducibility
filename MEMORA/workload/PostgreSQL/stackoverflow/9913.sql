WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.Score > 0
),
TopUserPosts AS (
    SELECT 
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        COUNT(rp.Id) AS PostCount,
        SUM(rp.Score) AS TotalScore
    FROM RankedPosts rp
    WHERE rp.Rank <= 5
    GROUP BY rp.OwnerUserId, rp.OwnerDisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
UserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(tp.PostCount, 0) AS TopPostsCount,
        COALESCE(tp.TotalScore, 0) AS TopPostsScore,
        COALESCE(ub.BadgeCount, 0) AS UserBadges
    FROM Users u
    LEFT JOIN TopUserPosts tp ON u.Id = tp.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE u.Reputation > 1000
)
SELECT 
    us.DisplayName,
    us.TopPostsCount,
    us.TopPostsScore,
    us.UserBadges
FROM UserStats us
WHERE us.UserBadges > 0
ORDER BY us.TopPostsScore DESC, us.TopPostsCount DESC;
