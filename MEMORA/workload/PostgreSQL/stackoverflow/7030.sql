
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        u.DisplayName AS OwnerDisplayName, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        pt.Name AS PostTypeName,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.Score, p.ViewCount, pt.Name
), 
PostHistories AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Id, 
    rp.Title, 
    rp.OwnerDisplayName, 
    rp.CreationDate, 
    rp.Score, 
    rp.ViewCount, 
    rp.Rank, 
    rp.PostTypeName, 
    COALESCE(ph.EditCount, 0) AS EditCount,
    ph.LastEditDate,
    rp.CommentCount,
    rp.AvgBounty
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistories ph ON rp.Id = ph.PostId
WHERE 
    rp.Rank <= 5 AND rp.CommentCount > 10
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
