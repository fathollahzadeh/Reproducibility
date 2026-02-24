WITH RECURSIVE UserPostHierarchy AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score <= 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY PostCount DESC, TotalViews DESC) AS UserRank
    FROM UserPostHierarchy
),
PostScoreHistory AS (
    SELECT 
        PH.CreationDate,
        P.Id AS PostId,
        PH.Comment AS CloseReason,
        PH.UserDisplayName AS Editor,
        PH.PostHistoryTypeId,
        CASE 
            WHEN PH.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN PH.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Other'
        END AS Action,
        P.Score
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
AggregatePostHistory AS (
    SELECT 
        PostId,
        COUNT(*) AS HistoryCount,
        COUNT(DISTINCT CloseReason) AS DistinctCloseReasons,
        SUM(CASE WHEN Action = 'Closed' THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN Action = 'Reopened' THEN 1 ELSE 0 END) AS ReopenCount
    FROM PostScoreHistory
    GROUP BY PostId
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.PostCount,
    RU.PositivePosts,
    RU.NegativePosts,
    RU.TotalViews,
    RU.TotalAnswers,
    APH.PostId,
    APH.HistoryCount,
    APH.DistinctCloseReasons,
    APH.CloseCount,
    APH.ReopenCount,
    CASE 
        WHEN RU.PostCount > 10 THEN 'Active Contributor'
        WHEN RU.PostCount BETWEEN 5 AND 10 THEN 'Moderately Active'
        ELSE 'Occasional User'
    END AS UserActivityLevel
FROM RankedUsers RU
LEFT JOIN AggregatePostHistory APH ON RU.UserId = APH.PostId
WHERE RU.UserRank <= 50
ORDER BY RU.UserRank, RU.TotalViews DESC;