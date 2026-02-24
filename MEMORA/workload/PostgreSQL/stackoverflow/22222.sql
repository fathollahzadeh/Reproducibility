WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.PostTypeId
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), ClosureReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS ClosureReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    CASE 
        WHEN ur.TotalBadges IS NULL THEN 0 
        ELSE ur.TotalBadges 
    END AS UserTotalBadges,
    COALESCE(ur.AvgReputation, 0) AS UserAvgReputation,
    COALESCE(cr.ClosureReasons, 'Not Closed') AS ClosureReasons
FROM RankedPosts rp
LEFT JOIN UserReputation ur ON rp.PostId = ur.UserId
LEFT JOIN ClosureReasons cr ON rp.PostId = cr.PostId
WHERE rp.RecentRank <= 5 
AND (ur.AvgReputation IS NULL OR ur.AvgReputation > 100) 
OR (cr.ClosureReasons IS NOT NULL AND ur.TotalBadges >= 1)
ORDER BY rp.CommentCount DESC, rp.CreationDate DESC
LIMIT 10;