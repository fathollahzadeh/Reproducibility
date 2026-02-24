WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
PostSummaries AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        MAX(p.LastActivityDate) AS LastActive
    FROM Posts p
    GROUP BY p.OwnerUserId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    ps.TotalPosts,
    ps.Questions,
    ps.Answers,
    ps.LastActive,
    CASE 
        WHEN us.Reputation > 1000 THEN 'High Reputation'
        WHEN us.Reputation > 500 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationLevel
FROM UserStats us
JOIN PostSummaries ps ON us.UserId = ps.OwnerUserId
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS TotalVotes
    FROM Votes
    WHERE VoteTypeId = 2 
    GROUP BY UserId
) v ON us.UserId = v.UserId
ORDER BY us.Reputation DESC, ps.TotalPosts DESC
LIMIT 10;