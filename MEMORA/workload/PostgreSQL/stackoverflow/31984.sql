
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(u.DisplayName, 'Community User') AS OwnerName,
        COALESCE(COUNT(v.Id), 0) AS VoteCount
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Score,
        rp.OwnerName,
        rp.VoteCount
    FROM
        RankedPosts rp
    WHERE
        rp.PostRank = 1
),
ClosedPosts AS (
    SELECT
        p.Id,
        ph.CreationDate AS ClosedDate,
        ph.UserId AS CloserUserId,
        u.DisplayName AS CloserName,
        ph.Comment
    FROM
        PostHistory ph
    JOIN
        Posts p ON ph.PostId = p.Id
    JOIN
        Users u ON ph.UserId = u.Id
    WHERE
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
),
RecentClosedPosts AS (
    SELECT
        cp.Id,
        cp.ClosedDate,
        cp.CloserUserId,
        cp.CloserName,
        cp.Comment,
        tp.Title
    FROM
        ClosedPosts cp
    JOIN
        TopPosts tp ON cp.Id = tp.PostId
)
SELECT
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    tp.Score,
    tp.OwnerName,
    tp.VoteCount,
    rcp.ClosedDate,
    rcp.CloserName,
    rcp.Comment
FROM
    TopPosts tp
LEFT JOIN
    RecentClosedPosts rcp ON tp.PostId = rcp.Id
ORDER BY
    tp.Score DESC, tp.ViewCount DESC;
