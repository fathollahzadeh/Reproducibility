
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName
    FROM RankedPosts
    WHERE Rank <= 5
)
SELECT 
    tp.Title AS PostTitle,
    tp.CreationDate AS PostCreationDate,
    tp.Score AS PostScore,
    tp.ViewCount AS PostViews,
    tp.AnswerCount AS PostAnswers,
    tp.CommentCount AS PostComments,
    tp.OwnerDisplayName AS PostOwner,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM TopPosts tp
LEFT JOIN Comments c ON tp.PostId = c.PostId
LEFT JOIN Votes v ON tp.PostId = v.PostId
GROUP BY tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.AnswerCount, tp.CommentCount, tp.OwnerDisplayName
ORDER BY tp.Score DESC;
