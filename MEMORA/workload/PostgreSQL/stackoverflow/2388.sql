
WITH TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        COALESCE(MAX(B.Date), DATE '1900-01-01') AS LastBadgeDate
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(CLOSED.CloseCount, 0) AS ClosedCount,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PH.PostId,
            COUNT(PH.Id) AS CloseCount
        FROM 
            PostHistory PH
        WHERE 
            PH.PostHistoryTypeId = 10
        GROUP BY 
            PH.PostId
    ) AS CLOSED ON P.Id = CLOSED.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    PS.QuestionCount,
    PS.AnswerCount,
    PS.TotalScore,
    UB.BadgeCount,
    UB.GoldBadges,
    AP.PostId,
    AP.Title,
    AP.CreationDate,
    AP.ViewCount,
    AP.ClosedCount,
    CASE 
        WHEN COALESCE(AP.ClosedCount, 0) > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    TopUsers U
JOIN 
    PostStats PS ON U.UserId = PS.OwnerUserId
JOIN 
    UserBadges UB ON U.UserId = UB.UserId
JOIN 
    ActivePosts AP ON U.UserId = AP.OwnerUserId
WHERE 
    AP.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
ORDER BY 
    U.Reputation DESC, 
    PS.TotalScore DESC
LIMIT 50;
