WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM Posts p
    WHERE p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpvoteCount,
        rp.DownvoteCount
    FROM RankedPosts rp
    WHERE rp.rn <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        pht.Name AS HistoryType,
        ph.Comment,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS history_rank
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.UpvoteCount,
    tp.DownvoteCount,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = tp.Id) AS TotalLinks,
    ph.HistoryType,
    ph.CreationDate as HistoryDate,
    ph.Comment AS HistoryComment
FROM TopPosts tp
LEFT JOIN PostComments pc ON tp.Id = pc.PostId
LEFT JOIN PostHistoryDetails ph ON tp.Id = ph.PostId AND ph.history_rank = 1
ORDER BY tp.Score DESC, tp.ViewCount DESC;
