WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostActivity AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.AnswerCount) AS AvgAnswerCount
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
UserEngagement AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(PA.PostCount, 0) AS PostCount,
        COALESCE(PA.TotalViews, 0) AS TotalViews,
        COALESCE(PA.TotalScore, 0) AS TotalScore,
        COALESCE(PA.AvgAnswerCount, 0) AS AvgAnswerCount,
        U.BadgeCount
    FROM UserReputation U
    LEFT JOIN PostActivity PA ON U.UserId = PA.OwnerUserId
),
FinalReport AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        U.BadgeCount,
        U.PostCount,
        U.TotalViews,
        U.TotalScore,
        U.AvgAnswerCount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM UserEngagement U
)
SELECT 
    DisplayName,
    Reputation,
    BadgeCount,
    PostCount,
    TotalViews,
    TotalScore,
    AvgAnswerCount,
    ReputationRank
FROM FinalReport
WHERE ReputationRank <= 100
ORDER BY Reputation DESC;