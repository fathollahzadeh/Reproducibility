
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '6 MONTH'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        ht.Name AS HistoryTypeName,
        ph.CreationDate AS HistoryCreationDate,
        ph.Comment AS HistoryComment,
        RANK() OVER (ORDER BY rp.Score DESC) AS Rank
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId
    LEFT JOIN 
        PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    tp.HistoryTypeName,
    tp.HistoryCreationDate,
    tp.HistoryComment
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
