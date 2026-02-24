WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    WHERE
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.PostRank,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount
    FROM
        RankedPosts rp
    WHERE
        rp.PostRank <= 5
),
PostHistoryStats AS (
    SELECT
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS LastDeleted,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 12)) AS CloseEditCount
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
)

SELECT
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    phs.LastClosed,
    phs.LastDeleted,
    phs.CloseEditCount,
    CASE
        WHEN phs.LastClosed IS NOT NULL THEN 'Closed'
        WHEN phs.LastDeleted IS NOT NULL THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus
FROM
    TopPosts tp
LEFT OUTER JOIN
    PostHistoryStats phs ON tp.PostId = phs.PostId
WHERE
    tp.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
ORDER BY
    tp.Score DESC, tp.CommentCount DESC,
    CASE 
        WHEN phs.LastClosed IS NULL THEN 1 
        ELSE 0 
    END, 
    tp.CreationDate DESC
LIMIT 10;