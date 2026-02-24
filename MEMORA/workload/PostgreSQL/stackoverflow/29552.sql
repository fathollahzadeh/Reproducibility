WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostLinksCount AS (
    SELECT 
        pl.PostId,
        COUNT(*) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),
CombinedResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.CommentCount,
        COALESCE(plc.LinkCount, 0) AS LinkCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostLinksCount plc ON tp.PostId = plc.PostId
)
SELECT 
    c.*
FROM 
    CombinedResults c
JOIN 
    Users u ON u.Id = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = c.PostId)
WHERE 
    u.Reputation >= 100
ORDER BY 
    c.Score DESC, c.ViewCount DESC;