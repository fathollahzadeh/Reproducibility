
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS PopularityRank,
        COALESCE(ut.DisplayName, 'Anonymous') AS OwnerDisplayName,
        p.OwnerUserId
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN
        Users ut ON p.OwnerUserId = ut.Id
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.ViewCount IS NOT NULL
),
ClosedPostHistory AS (
    SELECT
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.CreationDate - LAG(ph.CreationDate) OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS TimeSinceLastEdit
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (10, 11) 
),
BadgedUsers AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
)
SELECT
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    cb.CreationDate AS ClosedDate,
    cb.Comment AS CloseComment,
    bu.GoldBadges,
    bu.SilverBadges,
    bu.BronzeBadges,
    CASE 
        WHEN rp.PopularityRank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS PopularityCategory
FROM
    RankedPosts rp
LEFT JOIN
    ClosedPostHistory cb ON rp.PostId = cb.PostId
LEFT JOIN
    BadgedUsers bu ON rp.OwnerUserId = bu.UserId
WHERE
    (cb.CreationDate IS NULL OR cb.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 MONTH')
ORDER BY
    rp.ViewCount DESC, rp.Score DESC
LIMIT 100;
