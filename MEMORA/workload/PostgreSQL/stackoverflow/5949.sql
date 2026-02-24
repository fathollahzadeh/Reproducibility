WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation, u.DisplayName
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.DisplayName,
        ur.BadgeCount
    FROM UserReputation ur
    WHERE ur.Reputation > 1000 
    ORDER BY ur.Reputation DESC
    LIMIT 10 
)
SELECT 
    tp.UserId,
    tp.DisplayName,
    tp.Reputation,
    tp.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.ViewCount
FROM TopUsers tp
JOIN RankedPosts rp ON tp.UserId = rp.OwnerUserId
WHERE rp.PostRank <= 3 
ORDER BY tp.Reputation DESC, rp.Score DESC;