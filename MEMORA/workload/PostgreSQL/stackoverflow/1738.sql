WITH UserBadges AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AvgScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.TotalBadges, 0) AS TotalBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.AvgScore, 0) AS AvgScore
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
),
RankedUsers AS (
    SELECT 
        UA.*,
        ROW_NUMBER() OVER (ORDER BY UA.Reputation DESC, UA.TotalBadges DESC) AS UserRank
    FROM UserActivity UA
)
SELECT 
    R.UserId,
    R.DisplayName,
    R.Reputation,
    R.TotalBadges,
    R.TotalPosts,
    R.Questions,
    R.Answers,
    R.AvgScore,
    COALESCE((SELECT COUNT(*) 
               FROM Votes V 
               WHERE V.UserId = R.UserId AND V.VoteTypeId IN (2, 3)), 0) AS TotalVotes
FROM RankedUsers R
WHERE R.UserRank <= 10
ORDER BY R.UserRank;
