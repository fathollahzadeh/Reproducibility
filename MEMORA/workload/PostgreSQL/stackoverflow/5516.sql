
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        u.DisplayName AS OwnerDisplayName, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 10
),
PostWithComments AS (
    SELECT 
        tp.PostId, 
        tp.Title, 
        tp.OwnerDisplayName, 
        tp.CreationDate, 
        tp.Score, 
        tp.ViewCount, 
        COUNT(c.Id) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerDisplayName, tp.CreationDate, tp.Score, tp.ViewCount
),
FinalResults AS (
    SELECT 
        pwc.*, 
        RANK() OVER (ORDER BY pwc.Score DESC, pwc.ViewCount DESC) AS PopularityRank
    FROM 
        PostWithComments pwc
)
SELECT 
    f.PostId,
    f.Title,
    f.OwnerDisplayName,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.CommentCount,
    f.PopularityRank
FROM 
    FinalResults f
WHERE 
    f.PopularityRank <= 5
ORDER BY 
    f.PopularityRank;
