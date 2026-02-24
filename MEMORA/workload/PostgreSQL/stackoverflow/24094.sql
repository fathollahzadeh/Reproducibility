
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rnk
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ph.CreationDate AS CloseDate,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed'
            ELSE 'Reopened'
        END AS CloseStatus
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
),
HighRepUsers AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation
    FROM 
        Users 
    WHERE 
        Reputation > (SELECT AVG(Reputation) FROM Users)
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.OwnerDisplayName,
    rp.CommentCount,
    cp.CloseDate,
    cp.CloseStatus,
    ur.Reputation AS OwnerReputation,
    (SELECT COUNT(DISTINCT v.PostId) 
     FROM Votes v 
     WHERE v.UserId IN (SELECT Id FROM HighRepUsers)
     AND v.PostId = rp.PostId) AS HighRepVotesCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
JOIN 
    Users ur ON rp.OwnerDisplayName = ur.DisplayName
WHERE 
    rp.CommentCount > 10 
    OR (cp.CloseStatus IS NOT NULL AND cp.CloseDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months')
    AND ur.Reputation IS NOT NULL
ORDER BY 
    rp.Score DESC, 
    rp.PostId ASC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM Posts) / 10;
