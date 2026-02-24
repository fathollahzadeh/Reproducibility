
WITH UserVoteSummary AS (
    SELECT
        UserId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        SUM(CASE WHEN VoteTypeId = 8 THEN BountyAmount ELSE 0 END) AS TotalBountyUsed
    FROM Votes
    GROUP BY UserId
),
QualifiedUsers AS (
    SELECT
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COALESCE(Uv.UpVotesCount, 0) AS UpVotesCount,
        COALESCE(Uv.DownVotesCount, 0) AS DownVotesCount,
        COALESCE(Uv.TotalBountyUsed, 0) AS TotalBountyUsed
    FROM Users U
    LEFT JOIN UserVoteSummary Uv ON U.Id = Uv.UserId
    WHERE U.Reputation > 1000 OR U.AboutMe IS NOT NULL
),
PostStats AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserPostSummary AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        P.TotalPosts,
        P.TotalQuestions,
        P.TotalAcceptedAnswers
    FROM QualifiedUsers U
    LEFT JOIN PostStats P ON U.Id = P.OwnerUserId
)
SELECT
    UPS.UserId,
    UPS.DisplayName,
    UPS.Reputation,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAcceptedAnswers,
    UPS.TotalPosts - COALESCE(UPS.TotalQuestions, 0) AS TotalAnswers,
    (CAST(UPS.TotalAcceptedAnswers AS FLOAT) / NULLIF(UPS.TotalQuestions, 0)) * 100 AS AcceptanceRate,
    CASE 
        WHEN UPS.Reputation > 5000 THEN 'Gold User'
        WHEN UPS.Reputation BETWEEN 1000 AND 5000 THEN 'Silver User'
        ELSE 'Bronze User'
    END AS UserTier,
    CONCAT('Reputation:', UPS.Reputation, ', Posts:', UPS.TotalPosts) AS ReputationPostSummary
FROM UserPostSummary UPS
WHERE UPS.TotalPosts > 0
ORDER BY AcceptanceRate DESC, UPS.Reputation DESC
LIMIT 50 OFFSET 0;
