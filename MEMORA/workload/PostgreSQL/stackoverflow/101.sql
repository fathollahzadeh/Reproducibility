
WITH UserReputationStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId IN (1, 2) THEN P.ViewCount ELSE 0 END) AS TotalViews,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
ActivePostHistory AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PH.UserId,
        PH.UserDisplayName,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS ActivityRank
    FROM PostHistory PH
    WHERE PH.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
)
SELECT 
    UPS.DisplayName,
    UPS.Reputation,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalViews,
    PH.UserDisplayName AS RecentModifier,
    COUNT(DISTINCT PH.PostId) AS RecentPostModifications,
    MAX(PH.CreationDate) AS LastModificationDate,
    CASE 
        WHEN UPS.TotalPosts > 0 THEN (UPS.TotalViews / CAST(UPS.TotalPosts AS FLOAT))
        ELSE 0 
    END AS AvgViewsPerPost
FROM UserReputationStatistics UPS
LEFT JOIN ActivePostHistory PH ON UPS.UserId = PH.UserId
WHERE UPS.ReputationRank <= 100
GROUP BY UPS.DisplayName, UPS.Reputation, UPS.TotalPosts, UPS.TotalQuestions, UPS.TotalAnswers, UPS.TotalViews, PH.UserDisplayName
ORDER BY UPS.Reputation DESC, RecentPostModifications DESC;
