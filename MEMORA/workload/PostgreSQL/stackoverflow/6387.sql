
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        Score,
        ViewCount
    FROM
        RankedPosts
    WHERE
        Rank <= 10
),
PostDetails AS (
    SELECT
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.OwnerDisplayName,
        tp.Score,
        tp.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM
        TopPosts tp
    LEFT JOIN
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN
        Votes v ON tp.PostId = v.PostId
    GROUP BY
        tp.PostId, tp.Title, tp.CreationDate, tp.OwnerDisplayName, tp.Score, tp.ViewCount
)
SELECT
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.OwnerDisplayName,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    CASE
        WHEN pd.Score > 100 THEN 'Hot'
        WHEN pd.Score BETWEEN 50 AND 100 THEN 'Trending'
        ELSE 'New'
    END AS PopularityLevel
FROM
    PostDetails pd
ORDER BY
    pd.Score DESC, pd.ViewCount DESC;
