
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        p.OwnerUserId
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostHistorySummary AS (
    SELECT
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM
        PostHistory ph
    JOIN
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY
        ph.PostId
)
SELECT
    u.DisplayName AS Owner,
    u.Reputation AS OwnerReputation,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    phs.EditCount,
    phs.LastEditDate,
    phs.HistoryTypes
FROM
    RankedPosts rp
JOIN
    Users u ON u.Id = rp.OwnerUserId
JOIN
    UserBadges ub ON ub.UserId = u.Id
LEFT JOIN
    PostHistorySummary phs ON phs.PostId = rp.PostId
WHERE
    rp.RankScore <= 3  
    AND (u.Reputation IS NOT NULL AND u.Reputation > 100)  
ORDER BY
    u.DisplayName, rp.Score DESC;
