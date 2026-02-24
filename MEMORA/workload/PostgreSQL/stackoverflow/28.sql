WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1  
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(b.Class), 0) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8  
    GROUP BY u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
),
AggregatedResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ur.BadgeCount,
        ur.TotalBounties,
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM RankedPosts rp
    LEFT JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN PostComments pc ON rp.PostId = pc.PostId
    WHERE rp.Rank = 1  
)
SELECT 
    ar.PostId,
    ar.Title,
    ar.CreationDate,
    ar.Score,
    ar.BadgeCount,
    ar.TotalBounties,
    ar.CommentCount,
    CASE
        WHEN ar.Score > 10 THEN 'Highly Active'
        WHEN ar.Score BETWEEN 5 AND 10 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM AggregatedResults ar
WHERE ar.BadgeCount > 0
ORDER BY ar.Score DESC, ar.CreationDate DESC
LIMIT 50;