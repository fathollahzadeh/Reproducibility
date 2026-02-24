
WITH UserPostMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
ClosedQuestionCounts AS (
    SELECT 
        Ph.UserId,
        COUNT(DISTINCT Ph.PostId) AS ClosedQuestions
    FROM PostHistory Ph
    WHERE Ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY Ph.UserId
),
UserReputationIncrease AS (
    SELECT 
        U.Id AS UserId,
        (SUM(CASE WHEN B.Class = 1 THEN 3 WHEN B.Class = 2 THEN 2 WHEN B.Class = 3 THEN 1 ELSE 0 END) + 
        COALESCE(SUM(CASE WHEN Ph.PostHistoryTypeId = 33 THEN 1 ELSE 0 END), 0)) AS ReputationBonus
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN PostHistory Ph ON U.Id = Ph.UserId
    GROUP BY U.Id
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalScore,
    U.AverageViews,
    U.LastPostDate,
    COALESCE(CQC.ClosedQuestions, 0) AS ClosedQuestions,
    COALESCE(RI.ReputationBonus, 0) AS ReputationBonus,
    ROW_NUMBER() OVER (ORDER BY U.TotalScore DESC) AS Rank
FROM UserPostMetrics U
LEFT JOIN ClosedQuestionCounts CQC ON U.UserId = CQC.UserId
LEFT JOIN UserReputationIncrease RI ON U.UserId = RI.UserId
WHERE U.TotalPosts > 0 AND U.AverageViews IS NOT NULL
ORDER BY Rank, U.DisplayName;
