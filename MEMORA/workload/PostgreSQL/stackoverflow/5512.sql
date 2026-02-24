WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.CreationDate
    FROM RankedPosts rp
    WHERE rp.Rank <= 5
),
PostCommentCounts AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount
    FROM Votes v
    GROUP BY v.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.CreationDate,
    COALESCE(pcc.CommentCount, 0) AS CommentCount,
    COALESCE(pvc.VoteCount, 0) AS VoteCount
FROM TopPosts tp
LEFT JOIN PostCommentCounts pcc ON tp.PostId = pcc.PostId
LEFT JOIN PostVoteCounts pvc ON tp.PostId = pvc.PostId
ORDER BY tp.Score DESC, tp.CreationDate DESC;