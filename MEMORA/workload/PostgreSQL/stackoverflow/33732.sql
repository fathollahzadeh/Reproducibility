WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        MAX(v.BountyAmount) AS MaxBounty
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id AND v.VoteTypeId = 9  
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    AND p.Score > 0  
    GROUP BY p.Id, p.OwnerUserId, p.Title, p.ViewCount, p.Score, p.CreationDate
),
BountyDetails AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalBounties,
        SUM(BountyAmount) AS TotalBountyAmount
    FROM Votes
    WHERE VoteTypeId = 8  
    GROUP BY PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.PostRank,
        bd.TotalBounties,
        bd.TotalBountyAmount,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName
    FROM RankedPosts rp
    LEFT JOIN BountyDetails bd ON rp.PostId = bd.PostId
    LEFT JOIN Users u ON rp.OwnerUserId = u.Id
), 
ClosedPosts AS (
    SELECT DISTINCT 
        p.Id, 
        p.Title
    FROM Posts p
    JOIN PostHistory ph ON ph.PostId = p.Id 
    WHERE ph.PostHistoryTypeId = 10  
    AND ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.PostRank,
    tp.TotalBounties,
    tp.TotalBountyAmount,
    CASE 
        WHEN cp.Id IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM TopPosts tp
LEFT JOIN ClosedPosts cp ON tp.PostId = cp.Id
WHERE tp.PostRank <= 5  
ORDER BY tp.OwnerUserId, tp.Score DESC;