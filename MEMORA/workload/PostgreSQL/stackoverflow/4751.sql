
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        p.OwnerUserId
    FROM Posts p
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
)
SELECT 
    up.UserId,
    up.Reputation,
    up.BadgeCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.Id AS PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount
FROM UserReputation up
INNER JOIN RankedPosts rp ON up.UserId = rp.OwnerUserId
WHERE rp.Rank <= 5
AND EXISTS (
    SELECT 1 FROM Votes v
    WHERE v.PostId = rp.Id
    AND v.UserId = up.UserId
    AND v.VoteTypeId = 2
)
ORDER BY up.Reputation DESC, rp.Score DESC;
