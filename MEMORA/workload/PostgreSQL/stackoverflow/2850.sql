WITH UserBadges AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Badges b
    GROUP BY
        b.UserId
),
RecentPosts AS (
    SELECT
        p.Id,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.Score AS RecentPostScore,
    CASE
        WHEN rp.Score >= 10 THEN 'Highly Rated'
        WHEN rp.Score < 0 THEN 'Not Well Received'
        ELSE 'Average'
    END AS PostRating
FROM
    Users u
LEFT JOIN
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN
    RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
WHERE
    u.Reputation > 100
    AND (u.Location IS NOT NULL OR u.WebsiteUrl IS NOT NULL)
ORDER BY
    u.Reputation DESC
FETCH FIRST 10 ROWS ONLY;