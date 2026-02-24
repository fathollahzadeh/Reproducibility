
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RankPerUser
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= '2023-01-01'
        AND P.Score IS NOT NULL
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
CloseReasonCounts AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 
        AND PH.CreationDate >= '2023-01-01'
    GROUP BY 
        PH.UserId
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)

SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    COALESCE(UP.BadgeNames, 'No Badges') AS Badges,
    R.PostId,
    R.Title,
    R.Score AS PostScore,
    R.RankPerUser,
    C.CloseReasonCount,
    US.TotalQuestions,
    US.TotalAnswers,
    US.AcceptedAnswers,
    CASE 
        WHEN R.Score > 0 THEN 'Active'
        WHEN R.Score <= 0 AND C.CloseReasonCount > 0 THEN 'Inactive - Closed Post'
        ELSE 'Inactive'
    END AS UserActivityStatus
FROM 
    UserStats US
LEFT JOIN 
    RankedPosts R ON US.UserId = R.OwnerUserId AND R.RankPerUser = 1
LEFT JOIN 
    CloseReasonCounts C ON US.UserId = C.UserId
LEFT JOIN 
    UserBadges UP ON US.UserId = UP.UserId
WHERE 
    (R.PostId IS NOT NULL OR (US.TotalQuestions + US.TotalAnswers) > 0)
ORDER BY 
    US.Reputation DESC,
    R.Score DESC NULLS LAST,
    US.UserId;
