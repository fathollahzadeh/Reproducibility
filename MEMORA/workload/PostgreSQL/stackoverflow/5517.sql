WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserBadges ub
    JOIN Users u ON ub.UserId = u.Id
),
TopPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
    GROUP BY p.OwnerUserId
),
FinalBenchmark AS (
    SELECT 
        tu.UserId,
        tu.Reputation,
        tu.CreationDate,
        tu.LastAccessDate,
        tu.BadgeCount,
        tu.GoldBadges,
        tu.SilverBadges,
        tu.BronzeBadges,
        tp.PostCount,
        tp.TotalScore,
        tp.AvgViewCount
    FROM TopUsers tu
    JOIN TopPosts tp ON tu.UserId = tp.OwnerUserId
    WHERE tu.Rank <= 10
)
SELECT 
    *,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = fb.UserId) AS TotalPostsCreated
FROM FinalBenchmark fb
ORDER BY Reputation DESC;