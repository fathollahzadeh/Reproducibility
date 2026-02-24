WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        rp.OwnerName
    FROM
        RankedPosts rp
    WHERE
        rp.Rank <= 10
),
PostDetails AS (
    SELECT
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.CreationDate,
        tp.OwnerName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount
    FROM
        TopPosts tp
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS CommentCount
        FROM
            Comments
        GROUP BY
            PostId
    ) c ON tp.PostId = c.PostId
    LEFT JOIN (
        SELECT
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM
            Votes
        GROUP BY
            PostId
    ) v ON tp.PostId = v.PostId
)
SELECT
    pd.Title,
    pd.OwnerName,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.CreationDate,
    EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - pd.CreationDate)) / 3600 AS HoursSincePosted
FROM
    PostDetails pd
ORDER BY
    pd.ViewCount DESC;