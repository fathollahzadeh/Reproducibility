WITH UserReputation AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           u.Reputation,
           RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStats AS (
    SELECT p.OwnerUserId,
           COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
           COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
           SUM(COALESCE(p.Score, 0)) AS TotalScore,
           SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserBadges AS (
    SELECT b.UserId, 
           COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostHistorySummary AS (
    SELECT ph.UserId, 
           COUNT(ph.Id) AS TotalChanges,
           MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    GROUP BY ph.UserId
)
SELECT ur.UserId,
       ur.DisplayName,
       ur.Reputation,
       us.QuestionCount,
       us.AnswerCount,
       us.TotalScore,
       us.TotalViews,
       ub.GoldBadges,
       ub.SilverBadges,
       ub.BronzeBadges,
       COALESCE(phs.TotalChanges, 0) AS TotalPostHistoryChanges,
       phs.LastEditDate,
       RANK() OVER (ORDER BY ur.Reputation DESC) AS RankByReputation
FROM UserReputation ur
LEFT JOIN PostStats us ON ur.UserId = us.OwnerUserId
LEFT JOIN UserBadges ub ON ur.UserId = ub.UserId
LEFT JOIN PostHistorySummary phs ON ur.UserId = phs.UserId
WHERE ur.Reputation > 1000
  AND (ub.GoldBadges + ub.SilverBadges + ub.BronzeBadges) >= 5
ORDER BY ur.Reputation DESC, TotalPostHistoryChanges DESC;
