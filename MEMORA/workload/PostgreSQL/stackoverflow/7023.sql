
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        Author,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        VoteCount
    FROM
        RankedPosts
    WHERE
        Rank <= 10
)
SELECT
    tp.*,
    pt.Name AS PostType
FROM
    TopPosts tp
JOIN
    PostTypes pt ON pt.Id = (SELECT p.PostTypeId FROM Posts p WHERE p.Id = tp.PostId)
ORDER BY
    tp.Score DESC, tp.ViewCount DESC;
