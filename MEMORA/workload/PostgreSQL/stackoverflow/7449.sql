
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes vt ON p.Id = vt.PostId
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.Author,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM
        RankedPosts rp
    WHERE
        rp.RankScore <= 100 
)
SELECT
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.Author,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    CASE 
        WHEN fp.Score > 100 THEN 'High'
        WHEN fp.Score BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS Popularity
FROM
    FilteredPosts fp
ORDER BY
    fp.Score DESC, fp.CreationDate DESC;
