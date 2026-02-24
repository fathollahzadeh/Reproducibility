
WITH RecursiveUsers AS (
    SELECT Id, Reputation, CreationDate, DisplayName, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
    WHERE Reputation > 0
),
UserBadges AS (
    SELECT U.Id AS UserId, 
           COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT P.OwnerUserId, 
           COUNT(*) AS TotalPosts,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           AVG(P.Score) AS AvgScore, 
           MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CloseReasons AS (
    SELECT PH.UserId, 
           COUNT(*) AS CloseReasonCount,
           STRING_AGG(DISTINCT CRT.Name, ', ') AS CloseReasonNames
    FROM PostHistory PH 
    JOIN CloseReasonTypes CRT ON CAST(PH.Comment AS INTEGER) = CRT.Id
    WHERE PH.PostHistoryTypeId = 10 
    GROUP BY PH.UserId
),
AggregateStats AS (
    SELECT U.Id AS UserId,
           COALESCE(B.GoldBadges, 0) AS GoldBadges,
           COALESCE(B.SilverBadges, 0) AS SilverBadges,
           COALESCE(B.BronzeBadges, 0) AS BronzeBadges,
           COALESCE(PS.TotalPosts, 0) AS TotalPosts,
           COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
           COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
           COALESCE(PS.AvgScore, 0.0) AS AvgScore,
           COALESCE(CR.CloseReasonCount, 0) AS CloseReasonCount,
           COALESCE(CR.CloseReasonNames, 'None') AS CloseReasonNames
    FROM Users U
    LEFT JOIN UserBadges B ON U.Id = B.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN CloseReasons CR ON U.Id = CR.UserId
)
SELECT A.UserId, 
       A.GoldBadges, 
       A.SilverBadges, 
       A.BronzeBadges, 
       A.TotalPosts,
       A.TotalQuestions,
       A.TotalAnswers,
       A.AvgScore,
       A.CloseReasonCount,
       A.CloseReasonNames,
       RANK() OVER (ORDER BY A.TotalPosts DESC, A.AvgScore DESC) AS OverallRank
FROM AggregateStats A
ORDER BY OverallRank, A.UserId
LIMIT 100;
