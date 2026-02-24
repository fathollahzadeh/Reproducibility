
WITH RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Badges b ON p.OwnerUserId = b.UserId
    WHERE
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount, p.Score
),
PostScoreRanked AS (
    SELECT
        rp.*,
        RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS ScoreRank
    FROM
        RecentPosts rp
),
TopPosts AS (
    SELECT
        ps.*
    FROM
        PostScoreRanked ps
    WHERE
        ScoreRank <= 10
)
SELECT
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    u.DisplayName AS OwnerName,
    tp.ViewCount,
    tp.Score,
    COALESCE(tp.CommentCount, 0) AS CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(MAX(CASE WHEN bt.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadge,
    COALESCE(MAX(CASE WHEN bt.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadge,
    COALESCE(MAX(CASE WHEN bt.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadge
FROM
    TopPosts tp
JOIN
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN
    Badges bt ON u.Id = bt.UserId
GROUP BY
    tp.PostId, tp.Title, tp.CreationDate, u.DisplayName, tp.ViewCount, tp.Score, tp.CommentCount, tp.UpVotes, tp.DownVotes
HAVING 
    SUM(bt.Class) IS NOT NULL
ORDER BY
    tp.Score DESC, tp.ViewCount DESC
LIMIT 5;
