WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) 
),
UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.Reputation
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    ph.PostId,
    p.Title AS PostTitle,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    COALESCE(b.BadgeCount, 0) AS UserBadgeCount,
    ph.CreationDate AS HistoryDate,
    CASE 
        WHEN ph.PostHistoryTypeId = 10 THEN 'Closed' 
        WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened' 
        WHEN ph.PostHistoryTypeId = 12 THEN 'Deleted' 
        ELSE 'Undeleted' 
    END AS Action,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ph.PostId) AS CommentCount,
    (SELECT AVG(v.BountyAmount) FROM Votes v WHERE v.PostId = ph.PostId AND v.VoteTypeId IN (9, 10)) AS AverageBounty
FROM 
    RecursivePostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    Users u ON ph.UserId = u.Id
LEFT JOIN 
    UserReputation b ON u.Id = b.Id
WHERE 
    ph.rn = 1 
    AND (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ph.PostId) > 0 
    AND u.Reputation > 100 
ORDER BY 
    ph.CreationDate DESC
LIMIT 100;