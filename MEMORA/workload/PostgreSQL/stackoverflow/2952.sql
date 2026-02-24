WITH UserReputation AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           u.Reputation, 
           COUNT(DISTINCT p.Id) AS PostCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes, 
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
           SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS TotalAnswers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopBadgedUsers AS (
    SELECT UserId,
           COUNT(*) AS BadgeCount,
           MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
           MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
           MAX(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge
    FROM Badges b
    GROUP BY UserId
),
RankedUsers AS (
    SELECT ur.UserId, 
           ur.DisplayName, 
           ur.Reputation, 
           ur.PostCount, 
           ur.Upvotes, 
           ur.Downvotes, 
           ur.TotalAnswers,
           tb.BadgeCount,
           tb.GoldBadge,
           tb.SilverBadge,
           tb.BronzeBadge,
           ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS Rank
    FROM UserReputation ur
    LEFT JOIN TopBadgedUsers tb ON ur.UserId = tb.UserId
)
SELECT r.UserId,
       r.DisplayName,
       r.Reputation,
       r.PostCount,
       r.Upvotes,
       r.Downvotes,
       r.TotalAnswers,
       r.BadgeCount,
       r.GoldBadge,
       r.SilverBadge,
       r.BronzeBadge
FROM RankedUsers r
WHERE r.Rank <= 50
AND (r.BadgeCount IS NOT NULL OR r.Upvotes > 100)
ORDER BY r.Reputation DESC;