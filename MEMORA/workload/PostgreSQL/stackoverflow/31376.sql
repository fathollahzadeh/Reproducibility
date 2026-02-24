
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM
        Posts p
    LEFT JOIN
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, p.OwnerUserId
),
PopularUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        AVG(p.Score) AS AvgScore
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
    HAVING
        COUNT(DISTINCT p.Id) >= 5 
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM
        Badges b
    GROUP BY
        b.UserId
),
PostHistoryStats AS (
    SELECT
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY
        ph.PostId
)

SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    pu.DisplayName AS UserDisplayName,
    pu.Reputation,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    phs.EditCount,
    phs.LastEditDate
FROM
    RankedPosts rp
JOIN
    Users pu ON pu.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
JOIN
    PopularUsers pou ON pou.UserId = pu.Id
LEFT JOIN
    UserBadges ub ON ub.UserId = pu.Id
LEFT JOIN
    PostHistoryStats phs ON phs.PostId = rp.PostId
WHERE
    rp.Rank <= 3 
ORDER BY
    pu.Reputation DESC,
    rp.Score DESC;
