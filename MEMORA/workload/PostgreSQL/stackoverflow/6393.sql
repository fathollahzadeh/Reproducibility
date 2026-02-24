
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE p.PostTypeId IN (1, 2) 
    GROUP BY p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.OwnerDisplayName, 
        rp.Score, 
        rp.ViewCount, 
        rp.AnswerCount
    FROM RankedPosts rp
    WHERE rp.Rank <= 5 
),
CommentCounts AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS TotalComments
    FROM Comments c
    GROUP BY c.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    COALESCE(cc.TotalComments, 0) AS TotalComments
FROM TopPosts tp
LEFT JOIN CommentCounts cc ON tp.PostId = cc.PostId
ORDER BY tp.Score DESC, tp.ViewCount DESC;
