
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes
    FROM 
        RankedPosts rp
    INNER JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    WHERE 
        rp.Rank <= 5 
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.OwnerDisplayName,
    tp.Reputation,
    tp.NetVotes,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    CASE 
        WHEN tp.Reputation >= 1000 THEN 'Active'
        ELSE 'New'
    END AS UserStatus
FROM 
    TopPosts tp
LEFT JOIN 
    ClosedPosts cp ON tp.PostId = cp.PostId
WHERE 
    tp.NetVotes > 0 OR cp.CloseCount IS NOT NULL
ORDER BY 
    tp.Score DESC, tp.Reputation DESC;
