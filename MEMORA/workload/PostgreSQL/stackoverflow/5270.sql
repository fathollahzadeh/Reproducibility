
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.CreationDate,
        tp.ViewCount,
        tp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(MAX(b.Name), 'No Badge') AS TopBadge
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    LEFT JOIN 
        Badges b ON tp.OwnerDisplayName = (SELECT u.DisplayName FROM Users u WHERE b.UserId = u.Id)
    GROUP BY 
        tp.PostId, tp.Title, tp.Score, tp.CreationDate, tp.ViewCount, tp.OwnerDisplayName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.CreationDate,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.VoteCount,
    pd.TopBadge
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
