WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.Id, 
        rp.Title, 
        rp.Score, 
        rp.CreationDate, 
        rp.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High Reputation' 
            ELSE 'Low Reputation' 
        END AS ReputationCategory
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.Rank = 1
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.ReputationCategory,
    COALESCE(cp.CloseReason, 'Not Closed') AS CloseStatus
FROM 
    TopPosts tp
LEFT JOIN 
    ClosedPosts cp ON tp.Id = cp.PostId
WHERE 
    tp.Score > (SELECT AVG(Score) FROM Posts)
ORDER BY 
    tp.Score DESC
LIMIT 10;