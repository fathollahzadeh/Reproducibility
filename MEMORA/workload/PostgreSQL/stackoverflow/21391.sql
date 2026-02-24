WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostComments AS (
    SELECT
        c.PostId,
        COUNT(*) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM Comments c
    GROUP BY c.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS TotalChanges
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    ur.DisplayName,
    ur.Reputation,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    pc.LastCommentDate,
    COALESCE(phd.TotalChanges, 0) AS TotalChanges,
    CASE 
        WHEN rp.Score > 10 THEN 'Hot' 
        WHEN rp.Score BETWEEN 1 AND 10 THEN 'Warm' 
        ELSE 'Cool' 
    END AS PostTemperature
FROM RecentPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
JOIN UserReputation ur ON u.Id = ur.UserId
LEFT JOIN PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    ur.Reputation > 1000 
    OR (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) > 5
ORDER BY 
    rp.CreationDate DESC, 
    ur.Reputation DESC
LIMIT 100;