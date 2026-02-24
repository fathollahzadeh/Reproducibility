
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),

PostHistoryAggregate AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, 
        ph.PostHistoryTypeId
),

CombinedData AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        tp.CommentCount,
        COALESCE(pha.ChangeCount, 0) AS TotalChanges
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostHistoryAggregate pha ON tp.PostId = pha.PostId
)

SELECT 
    cd.PostId,
    cd.Title,
    cd.Score,
    cd.ViewCount,
    cd.OwnerDisplayName,
    cd.CommentCount,
    cd.TotalChanges,
    CASE 
        WHEN cd.Score > 100 THEN 'Popular'
        WHEN cd.Score BETWEEN 50 AND 100 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityRating
FROM 
    CombinedData cd
WHERE 
    cd.CommentCount > 5
ORDER BY 
    cd.Score DESC, cd.ViewCount DESC;
