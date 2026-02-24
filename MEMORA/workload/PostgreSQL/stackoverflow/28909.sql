WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        COUNT(*) AS BadgeCount
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, B.Name, B.Class
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AvgScore,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AvgScore, 0) AS AvgScore,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS BadgeCount FROM UserBadges GROUP BY UserId) AS UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)

SELECT 
    UP.DisplayName,
    UP.Reputation,
    UP.BadgeCount,
    UP.PostCount,
    UP.TotalViews,
    UP.AvgScore,
    UP.TotalAnswers,
    STRING_AGG(DISTINCT BT.Name, ', ') AS BadgesDetails
FROM 
    UserPerformance UP
LEFT JOIN 
    UserBadges UB ON UP.UserId = UB.UserId
LEFT JOIN 
    PostHistory P ON UP.UserId = P.UserId 
JOIN 
    PostHistoryTypes BT ON P.PostHistoryTypeId = BT.Id
GROUP BY 
    UP.DisplayName, UP.Reputation, UP.BadgeCount, UP.PostCount, UP.TotalViews, UP.AvgScore, UP.TotalAnswers
ORDER BY 
    UP.Reputation DESC, UP.BadgeCount DESC, UP.PostCount DESC
LIMIT 100;