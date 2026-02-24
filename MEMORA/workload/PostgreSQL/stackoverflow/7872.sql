WITH UserBadges AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(b.Id) AS BadgeCount,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostSummary AS (
    SELECT p.OwnerUserId,
           COUNT(p.Id) AS PostCount,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           SUM(p.Score) AS TotalScore,
           SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
FinalSummary AS (
    SELECT ub.UserId,
           ub.DisplayName,
           COALESCE(ps.PostCount, 0) AS PostCount,
           COALESCE(ps.Questions, 0) AS Questions,
           COALESCE(ps.Answers, 0) AS Answers,
           COALESCE(ps.TotalScore, 0) AS TotalScore,
           COALESCE(ps.TotalViews, 0) AS TotalViews,
           ub.BadgeCount,
           ub.GoldBadges,
           ub.SilverBadges,
           ub.BronzeBadges
    FROM UserBadges ub
    LEFT JOIN PostSummary ps ON ub.UserId = ps.OwnerUserId
)
SELECT *,
       RANK() OVER (ORDER BY TotalScore DESC, PostCount DESC, BadgeCount DESC) AS UserRank
FROM FinalSummary
WHERE PostCount > 0
ORDER BY UserRank
LIMIT 10;
