
WITH UserBadgeCounts AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostWithDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerDisplayName,
        CommentCount,
        PostRank,
        OwnerUserId
    FROM PostWithDetails
    WHERE PostRank = 1
)
SELECT 
    tb.OwnerDisplayName,
    COUNT(*) AS TopPostCount,
    SUM(COALESCE(ubc.GoldBadges, 0)) AS TotalGoldBadges,
    SUM(COALESCE(ubc.SilverBadges, 0)) AS TotalSilverBadges,
    SUM(COALESCE(ubc.BronzeBadges, 0)) AS TotalBronzeBadges
FROM TopPosts tb
LEFT JOIN UserBadgeCounts ubc ON tb.OwnerUserId = ubc.UserId
GROUP BY tb.OwnerDisplayName
HAVING COUNT(*) > 5
ORDER BY TopPostCount DESC
LIMIT 10;
