
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
)
SELECT 
    tp.UserId,
    tp.DisplayName,
    tp.Reputation,
    tp.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.AnswerCount,
    rp.Score
FROM 
    TopUsers tp
JOIN 
    RankedPosts rp ON tp.UserId = rp.OwnerUserId
WHERE 
    rp.rn = 1
ORDER BY 
    tp.Reputation DESC, 
    rp.Score DESC;
