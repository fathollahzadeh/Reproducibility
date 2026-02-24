
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.Score > 0 AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1' YEAR
),
UserBadges AS (
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
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT rp.Id) AS NumberOfPosts,
    COALESCE(SUM(uc.BadgeCount), 0) AS TotalBadges,
    SUM(pc.CommentCount) AS TotalComments,
    ARRAY_AGG(DISTINCT rp.Title) AS LatestPostTitles,
    MAX(rp.Score) AS MaxPostScore,
    AVG(rp.ViewCount) AS AvgPostViews
FROM Users u
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN UserBadges uc ON u.Id = uc.UserId
LEFT JOIN PostComments pc ON rp.Id = pc.PostId
WHERE u.Reputation IS NOT NULL AND u.Reputation > 100
GROUP BY u.Id, u.DisplayName
HAVING COUNT(DISTINCT rp.Id) > 5
ORDER BY TotalBadges DESC, MaxPostScore DESC
LIMIT 10;
