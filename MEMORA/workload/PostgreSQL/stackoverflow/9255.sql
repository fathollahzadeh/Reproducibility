
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        CreationDate, 
        Score, 
        OwnerDisplayName 
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM 
    TopPosts tp
LEFT JOIN 
    Votes v ON v.PostId = tp.PostId AND v.VoteTypeId = 8  
GROUP BY 
    tp.PostId, tp.Title, tp.ViewCount, tp.CreationDate, tp.Score, tp.OwnerDisplayName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
