WITH UserBadges AS (
    SELECT U.Id AS UserId, 
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT P.OwnerUserId,
           COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
           COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
           SUM(P.Score) AS TotalScore,
           SUM(P.ViewCount) AS TotalViews,
           COALESCE(MAX(P.AcceptedAnswerId), -1) AS LastAcceptedAnswerId
    FROM Posts P
    GROUP BY P.OwnerUserId
),
RankedUsers AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           COALESCE(UB.GoldBadges, 0) AS GoldBadges,
           COALESCE(UB.SilverBadges, 0) AS SilverBadges,
           COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
           PS.Questions,
           PS.Answers,
           PS.TotalScore,
           PS.TotalViews,
           RANK() OVER (ORDER BY PS.TotalScore DESC) AS ScoreRank
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    WHERE U.Reputation > 1000
)
SELECT R.UserId, 
       R.DisplayName, 
       R.GoldBadges, 
       R.SilverBadges, 
       R.BronzeBadges, 
       R.Questions, 
       R.Answers, 
       R.TotalScore, 
       R.TotalViews,
       CASE 
           WHEN R.GoldBadges >= 5 THEN 'Elite'
           WHEN R.GoldBadges >= 1 THEN 'Gold Member'
           ELSE 'Regular Member'
       END AS MembershipLevel
FROM RankedUsers R
WHERE R.ScoreRank <= 10 
ORDER BY R.TotalScore DESC, R.UserId;
