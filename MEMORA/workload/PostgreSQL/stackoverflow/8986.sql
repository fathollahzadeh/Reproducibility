WITH UserStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(DISTINCT p.Id) AS PostCount,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           MAX(u.Reputation) AS MaxReputation,
           MIN(u.CreationDate) AS AccountCreated,
           AVG(COALESCE(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AverageUpvotes,
           AVG(COALESCE(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS AverageDownvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
BadgeStats AS (
    SELECT b.UserId,
           COUNT(b.Id) AS BadgeCount,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
FinalStats AS (
    SELECT us.UserId,
           us.DisplayName,
           us.PostCount,
           us.QuestionCount,
           us.AnswerCount,
           us.MaxReputation,
           us.AccountCreated,
           COALESCE(bs.BadgeCount, 0) AS BadgeCount,
           COALESCE(bs.GoldBadges, 0) AS GoldBadges,
           COALESCE(bs.SilverBadges, 0) AS SilverBadges,
           COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
           us.AverageUpvotes,
           us.AverageDownvotes
    FROM UserStats us
    LEFT JOIN BadgeStats bs ON us.UserId = bs.UserId
)
SELECT fs.DisplayName,
       fs.PostCount,
       fs.QuestionCount,
       fs.AnswerCount,
       fs.MaxReputation,
       fs.AccountCreated,
       fs.BadgeCount,
       fs.GoldBadges,
       fs.SilverBadges,
       fs.BronzeBadges,
       fs.AverageUpvotes,
       fs.AverageDownvotes,
       ROW_NUMBER() OVER (ORDER BY fs.MaxReputation DESC) AS Rank
FROM FinalStats fs
WHERE fs.PostCount > 0
ORDER BY fs.MaxReputation DESC, fs.PostCount DESC
LIMIT 10;
