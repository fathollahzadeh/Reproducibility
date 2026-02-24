WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score > 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
HighScorePosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerDisplayName,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(pc.CommentCount, 0) AS TotalComments
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
    LEFT JOIN 
        PostComments pc ON rp.Id = pc.PostId
    WHERE 
        rp.RankScore <= 5
)
SELECT 
    hsp.Id,
    hsp.Title,
    hsp.OwnerDisplayName,
    hsp.CloseCount,
    hsp.TotalComments,
    CASE 
        WHEN hsp.CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM 
    HighScorePosts hsp
WHERE 
    hsp.CloseCount < 3
ORDER BY 
    hsp.TotalComments DESC, 
    hsp.CloseCount ASC;