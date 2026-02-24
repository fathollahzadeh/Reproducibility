
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Tags) AS UniqueTags
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalComments,
        UA.TotalUpVotes,
        UA.TotalDownVotes,
        UA.GoldBadges,
        UA.SilverBadges,
        UA.BronzeBadges,
        PS.Questions,
        PS.Answers,
        PS.AverageScore,
        PS.TotalViews,
        PS.UniqueTags
    FROM UserActivity UA
    LEFT JOIN PostStatistics PS ON UA.UserId = PS.OwnerUserId
)
SELECT * 
FROM CombinedStats
ORDER BY TotalPosts DESC, TotalUpVotes DESC, AverageScore DESC
LIMIT 100;
