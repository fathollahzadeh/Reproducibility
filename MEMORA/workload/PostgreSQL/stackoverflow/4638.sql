
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS ScoreRank
    FROM Posts p
    WHERE p.OwnerUserId IS NOT NULL AND p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users)
    GROUP BY u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        us.DisplayName AS TopUser,
        us.BadgeCount,
        us.TotalBounties
    FROM RankedPosts rp
    JOIN UserStats us ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId)
    WHERE rp.ScoreRank <= 5
)
SELECT 
    tp.Title,
    tp.Score,
    tp.TopUser,
    tp.BadgeCount,
    tp.TotalBounties,
    COALESCE(GREATEST(
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = tp.PostId),
        (SELECT COUNT(pl.RelatedPostId) FROM PostLinks pl WHERE pl.PostId = tp.PostId)
    ), 0) AS EngagementCount,
    CASE 
        WHEN tp.TotalBounties > 0 THEN 'Has Bounties'
        ELSE 'No Bounties'
    END AS BountyStatus
FROM TopPosts tp
ORDER BY tp.Score DESC, tp.BadgeCount DESC;
