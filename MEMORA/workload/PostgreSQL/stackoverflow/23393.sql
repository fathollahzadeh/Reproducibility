
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
RecentPostActivities AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        P.Title,
        PT.Name AS PostTypeName,
        PH.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM 
        PostHistory PH
    INNER JOIN 
        Posts P ON PH.PostId = P.Id
    INNER JOIN 
        PostHistoryTypes PT ON PH.PostHistoryTypeId = PT.Id
    WHERE 
        PH.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    UB.BadgeCount,
    UB.BadgeNames,
    PS.QuestionCount,
    PS.AnswerCount,
    PS.TotalViews,
    PS.AvgScore,
    RP.PostId,
    RP.Title,
    RP.PostTypeName,
    RP.CreationDate AS RecentActivityDate,
    CASE 
        WHEN RP.PostTypeName IS NULL THEN 'No recent activity'
        ELSE 'Active'
    END AS ActivityStatus,
    COALESCE(RP.PostHistoryTypeId, 0) AS LastActivityType,
    CASE 
        WHEN RP.PostHistoryTypeId IN (10, 11, 12) THEN 'Closed/Reopened/Deleted'
        ELSE 'Other Action'
    END AS LastActivityDescription
FROM 
    Users U
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostStatistics PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    RecentPostActivities RP ON U.Id = RP.UserId AND RP.rn = 1
WHERE 
    U.Reputation >= (
        SELECT 
            AVG(Reputation) * 0.5
        FROM 
            Users
    )
ORDER BY 
    U.Reputation DESC
LIMIT 100;
