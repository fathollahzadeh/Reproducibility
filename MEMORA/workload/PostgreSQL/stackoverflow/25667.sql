
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        o.Id AS OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COUNT(DISTINCT p.Tags) AS UniqueTags
    FROM Posts p
    JOIN Users o ON p.OwnerUserId = o.Id
    GROUP BY o.Id
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.BadgeCount,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.UniqueTags,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC, us.BadgeCount DESC) AS Rank
    FROM UserStats us
    JOIN PostStats ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    Rank,
    DisplayName,
    Reputation,
    BadgeCount,
    TotalPosts,
    Questions,
    Answers,
    UniqueTags
FROM TopUsers
WHERE Rank <= 10
ORDER BY Rank;
