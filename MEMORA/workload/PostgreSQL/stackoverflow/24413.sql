WITH CTE_UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
CTE_PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CTE_BadgeSummary AS (
    SELECT 
        UserId,
        BadgeCount,
        BadgeNames,
        RANK() OVER (ORDER BY BadgeCount DESC) AS BadgeRank
    FROM CTE_UserBadges
),
CTE_FullStats AS (
    SELECT 
        U.DisplayName AS UserDisplayName,
        U.Reputation,
        PS.QuestionCount,
        PS.TotalViews,
        PS.AverageScore,
        BS.BadgeCount,
        BS.BadgeNames,
        CASE WHEN BS.BadgeCount IS NULL THEN 'None' ELSE BS.BadgeNames END AS BadgeSummary
    FROM Users U
    LEFT JOIN CTE_PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN CTE_BadgeSummary BS ON U.Id = BS.UserId
)
SELECT 
    UserDisplayName,
    Reputation,
    COALESCE(QuestionCount, 0) AS Questions,
    COALESCE(TotalViews, 0) AS Views,
    COALESCE(AverageScore, 0) AS AvgScore,
    BadgeSummary,
    CASE 
        WHEN Reputation > 1000 THEN 'High'
        WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS ReputationCategory,
    ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
FROM CTE_FullStats
WHERE Reputation IS NOT NULL
  AND BadgeSummary IS NOT NULL
ORDER BY Reputation DESC, UserDisplayName
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;