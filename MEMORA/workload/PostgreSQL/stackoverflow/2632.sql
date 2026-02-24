
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
EligibleUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalBounty,
        us.BadgeCount
    FROM 
        UserStats us
    WHERE 
        us.Reputation > 1000
        AND us.BadgeCount >= 5
)
SELECT 
    eu.DisplayName,
    eu.Reputation,
    eu.TotalBounty,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM 
    RankedPosts rp
JOIN 
    EligibleUsers eu ON rp.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = eu.UserId 
        AND p.ViewCount > 50
    )
WHERE 
    rp.PostRank = 1
ORDER BY 
    eu.Reputation DESC, rp.ViewCount DESC
LIMIT 10;
