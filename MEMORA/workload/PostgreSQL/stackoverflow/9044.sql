
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN b.Id IS NOT NULL THEN 1 END), 0) AS BadgeCount,
        COALESCE(SUM(CASE WHEN v.UserId IS NOT NULL THEN 1 END), 0) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.BadgeCount,
        us.VoteCount,
        RANK() OVER (ORDER BY us.VoteCount DESC, us.BadgeCount DESC) AS UserRank
    FROM 
        UserStats us
    WHERE 
        us.BadgeCount >= 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    tu.DisplayName,
    tu.BadgeCount,
    tu.VoteCount
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;
