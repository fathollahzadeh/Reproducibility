
WITH RECURSIVE UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PHT.Name = 'Post Closed' THEN 1 ELSE 0 END) AS HasBeenClosed,
        MAX(CASE WHEN PHT.Name = 'Post Reopened' THEN 1 ELSE 0 END) AS HasBeenReopened,
        COUNT(CASE WHEN PHT.Name IN ('Edit Title', 'Edit Body', 'Edit Tags') THEN 1 END) AS EditCount
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY PH.PostId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    WHERE U.Reputation > 1000
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.AcceptedAnswers,
    PHS.HasBeenClosed,
    PHS.HasBeenReopened,
    PHS.EditCount,
    TU.UserRank
FROM UserPostStats UPS
LEFT JOIN PostHistoryStats PHS ON UPS.TotalPosts > 0 AND PHS.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = UPS.UserId)
JOIN TopUsers TU ON UPS.UserId = TU.UserId
WHERE (UPS.TotalQuestions > 0 AND UPS.AcceptedAnswers > 0)
  OR (UPS.TotalAnswers > 5 AND UPS.TotalPosts >= 10)
ORDER BY UPS.TotalPosts DESC, UPS.AcceptedAnswers DESC;
