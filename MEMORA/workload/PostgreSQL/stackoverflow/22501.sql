
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    WHERE
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '1 year'
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT v.PostId) AS VoteCount
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        us.VoteCount,
        COALESCE(pd.ViewCount, 0) AS ViewCount,
        pd.Tags,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, COALESCE(pd.ViewCount, 0) DESC) AS TopPostRank
    FROM
        RankedPosts rp
    LEFT JOIN
        Posts pd ON rp.PostId = pd.Id
    LEFT JOIN
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN
        UserStats us ON us.UserId = u.Id
    WHERE
        rp.PostRank = 1
)
SELECT
    tp.Title,
    tp.PostId,
    tp.ViewCount,
    tp.VoteCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
    COALESCE(NULLIF(tp.Tags, ''), 'No tags') AS Tags, 
    CASE WHEN tp.ViewCount < 50 THEN 'Low view count'
         WHEN tp.ViewCount BETWEEN 50 AND 100 THEN 'Moderate view count'
         ELSE 'High view count' END AS ViewLevel
FROM
    TopPosts tp
WHERE
    tp.TopPostRank <= 50
ORDER BY
    tp.ViewCount DESC;
