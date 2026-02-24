
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        U.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, U.DisplayName, p.Score, p.ViewCount, a.AcceptedAnswerId
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    COALESCE(pa.Id, -1) AS SuggestedAnswerId,
    CASE 
        WHEN tp.AcceptedAnswerId = 0 THEN NULL 
        ELSE (SELECT a.Title FROM Posts a WHERE a.Id = tp.AcceptedAnswerId) 
    END AS AcceptedAnswerTitle
FROM 
    TopPosts tp
LEFT JOIN 
    Posts pa ON tp.PostId = pa.ParentId AND pa.PostTypeId = 2 
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
