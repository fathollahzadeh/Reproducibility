WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.RankScore <= 10 THEN 'Top 10'
            ELSE 'Other'
        END AS RankCategory
    FROM 
        RankedPosts rp
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        ARRAY_AGG(DISTINCT cr.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.RankCategory,
    COALESCE(cp.CloseCount, 0) AS ClosePostCount,
    COALESCE(cp.CloseReasons, '{}') AS CloseReasons
FROM 
    TopPosts tp
LEFT JOIN 
    ClosedPosts cp ON tp.PostId = cp.PostId
WHERE 
    tp.ViewCount > 100
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;