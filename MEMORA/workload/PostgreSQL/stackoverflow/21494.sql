
WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                            WHEN U.Reputation > 1000 THEN 'High' 
                                            WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium' 
                                            ELSE 'Low' 
                                         END 
                          ORDER BY U.Reputation DESC) AS Rank,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        CASE 
            WHEN U.Views IS NULL THEN 'No Views' 
            ELSE 'Has Views' 
        END AS ViewStatus
    FROM 
        Users U
),

UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),

PostSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewCount,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    R.ViewStatus,
    R.Rank,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.BadgeNames, 'No Badges') AS BadgeNames,
    PS.TotalPosts,
    PS.TotalViewCount,
    PS.TotalAnswers,
    CASE 
        WHEN PS.TotalPosts > 50 THEN 'Veteran' 
        WHEN PS.TotalPosts > 20 THEN 'Regular' 
        ELSE 'Newcomer' 
    END AS UserStatus,
    PHT.Name AS PostHistoryType,
    PHT.Id AS PostHistoryTypeId
FROM 
    RankedUsers R
JOIN 
    Users U ON U.Id = R.Id
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostSummary PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    PostHistoryTypes PHT ON PHT.Id IN (1, 2, 10, 12) 
WHERE 
    R.Rank <= 10
    AND R.Reputation > 500
ORDER BY 
    R.Reputation DESC, 
    PS.TotalViewCount DESC NULLS LAST
LIMIT 100;
