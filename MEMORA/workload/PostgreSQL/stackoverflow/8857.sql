WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
        AND p.PostTypeId IN (1, 2) 
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC, ub.BadgeCount DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 0
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.Author,
    rp.CreationDate,
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.BadgeCount 
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.Author = tu.DisplayName
WHERE 
    rp.Rank <= 5
    AND tu.UserRank <= 10
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;