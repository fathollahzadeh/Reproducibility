WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(MAX(ph.CreationDate), '1900-01-01') AS LastEditDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY Score DESC, CommentCount DESC) AS Rank
    FROM RankedPosts
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.AnswerCount,
    tp.LastEditDate,
    COALESCE(u.DisplayName, 'Deleted User') AS OwnerName,
    COALESCE(u.Reputation, 0) AS OwnerReputation
FROM TopPosts tp
LEFT JOIN Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE tp.Rank <= 10
ORDER BY tp.Score DESC;