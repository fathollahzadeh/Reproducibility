WITH RecursiveUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS ActivityRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE P.CreationDate IS NOT NULL
),
UserVotes AS (
    SELECT 
        V.UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT V.PostId) AS TotalVotes
    FROM Votes V
    GROUP BY V.UserId
),
UserBadgeSummary AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
PostsStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UA.UpVotesCount, 0) AS UpVotesCount,
    COALESCE(UA.DownVotesCount, 0) AS DownVotesCount,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(PS.AverageScore, 0.0) AS AverageScore,
    COALESCE(RUA.ActivityRank, 0) AS LatestActivityRank
FROM Users U
LEFT JOIN UserVotes UA ON U.Id = UA.UserId
LEFT JOIN UserBadgeSummary UB ON U.Id = UB.UserId
LEFT JOIN PostsStatistics PS ON U.Id = PS.OwnerUserId
LEFT JOIN RecursiveUserActivity RUA ON U.Id = RUA.UserId
WHERE U.Reputation >= 1000
ORDER BY U.Reputation DESC, LatestActivityRank
LIMIT 100;
