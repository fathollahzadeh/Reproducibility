
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE('2024-10-01') - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
DetailedPostInfo AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.CreationDate,
        trp.Score,
        trp.ViewCount,
        trp.OwnerDisplayName,
        trp.CommentCount,
        COALESCE(pht.Name, 'No History') AS PostHistoryType
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        PostHistory ph ON trp.PostId = ph.PostId
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    ORDER BY 
        trp.Score DESC
)
SELECT 
    dpi.Title,
    dpi.OwnerDisplayName,
    dpi.Score,
    dpi.ViewCount,
    dpi.CommentCount,
    STRING_AGG(DISTINCT dpi.PostHistoryType, ', ') AS PostHistoryTypes
FROM 
    DetailedPostInfo dpi
GROUP BY 
    dpi.Title, dpi.OwnerDisplayName, dpi.Score, dpi.ViewCount, dpi.CommentCount
ORDER BY 
    dpi.Score DESC;
