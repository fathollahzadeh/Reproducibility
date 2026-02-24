WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalBounty,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalAnswers DESC) AS AnswerRank,
        RANK() OVER (ORDER BY TotalBounty DESC) AS BountyRank
    FROM UserStats
),
FilteredUsers AS (
    SELECT *
    FROM TopUsers
    WHERE PostRank <= 10 OR AnswerRank <= 10 OR BountyRank <= 10
)
SELECT 
    DisplayName,
    TotalPosts,
    TotalAnswers,
    TotalQuestions,
    TotalBounty,
    PostRank,
    AnswerRank,
    BountyRank
FROM FilteredUsers
ORDER BY PostRank, AnswerRank, BountyRank;
