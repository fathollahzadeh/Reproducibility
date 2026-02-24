
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(V.VoteCount, 0)) AS TotalVotes,
        COALESCE(SUM(B.Class), 0) AS TotalBadges,
        CASE 
            WHEN U.Reputation BETWEEN 0 AND 1000 THEN 'Novice'
            WHEN U.Reputation BETWEEN 1001 AND 5000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount 
        FROM Votes 
        GROUP BY PostId
    ) V ON V.PostId = P.Id
    LEFT JOIN Badges B ON B.UserId = U.Id
    GROUP BY U.Id, U.DisplayName, U.Reputation
),

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 52 THEN 1 ELSE 0 END) AS HotCount,
        DENSE_RANK() OVER (ORDER BY SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS VoteRank
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN PostLinks PL ON PL.PostId = P.Id
    LEFT JOIN PostHistory PH ON PH.PostId = P.Id
    LEFT JOIN Votes V ON V.PostId = P.Id
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score
),

UserRanking AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalQuestions,
        UA.TotalAnswers,
        UA.TotalVotes,
        UA.TotalBadges,
        UA.ReputationLevel,
        CASE 
            WHEN UA.TotalVotes > 100 THEN 'Highly Active'
            WHEN UA.TotalPosts >= 10 THEN 'Moderately Active'
            ELSE 'Less Active'
        END AS ActivityLevel
    FROM UserActivity UA
    WHERE UA.TotalPosts > 0
)

SELECT 
    UR.DisplayName AS User,
    UR.ReputationLevel,
    UR.ActivityLevel,
    PS.Title AS PostTitle,
    PS.Score AS PostScore,
    PS.CommentCount,
    PS.RelatedPostCount,
    PS.CloseCount,
    PS.HotCount,
    PS.VoteRank
FROM UserRanking UR
JOIN PostStatistics PS ON PS.VoteRank <= 10
ORDER BY UR.ReputationLevel, UR.ActivityLevel, PS.Score DESC;
