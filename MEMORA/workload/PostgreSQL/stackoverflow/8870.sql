
WITH UserBadgeStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS PopularityRank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 AND p.Score > 10
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id
)
SELECT
    uBadge.DisplayName,
    uBadge.BadgeCount,
    uBadge.GoldBadges,
    uBadge.SilverBadges,
    uBadge.BronzeBadges,
    p.Title AS PopularPostTitle,
    p.ViewCount AS PopularPostViews,
    uPost.PostCount,
    uPost.TotalScore
FROM
    UserBadgeStats uBadge
JOIN
    UserPostStats uPost ON uBadge.UserId = uPost.UserId
LEFT JOIN
    PopularPosts p ON uPost.PostCount > 0
WHERE
    uBadge.BadgeCount > 0
ORDER BY
    uBadge.BadgeCount DESC, uPost.TotalScore DESC
FETCH FIRST 10 ROWS ONLY;
