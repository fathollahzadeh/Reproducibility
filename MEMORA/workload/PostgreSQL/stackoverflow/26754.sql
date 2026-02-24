
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),

PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.OwnerUserId
)

SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.BadgeCount,
    ru.GoldBadges,
    ru.SilverBadges,
    ru.BronzeBadges,
    ps.TotalPosts,
    ps.Questions,
    ps.Answers,
    ps.TotalViews,
    ps.CommentCount,
    CASE 
        WHEN ru.BadgeCount > 10 THEN 'Highly Acclaimed'
        WHEN ru.Reputation > 1000 THEN 'Expert Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorLevel
FROM RankedUsers ru
LEFT JOIN PostStats ps ON ru.UserId = ps.OwnerUserId
WHERE ru.UserRank <= 100
ORDER BY ru.Reputation DESC, ru.BadgeCount DESC;
