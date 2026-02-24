WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(COALESCE(CAST(B.Class AS int), 0)) AS TotalBadges,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalScore,
        TotalBadges,
        TotalComments,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostsRank
    FROM UserStatistics
)
SELECT 
    T.DisplayName,
    T.TotalPosts,
    T.Questions,
    T.Answers,
    T.TotalScore,
    T.TotalBadges,
    T.TotalComments,
    T.ScoreRank,
    T.PostsRank
FROM TopUsers T
WHERE T.ScoreRank <= 10 OR T.PostsRank <= 10
ORDER BY T.ScoreRank, T.PostsRank;
