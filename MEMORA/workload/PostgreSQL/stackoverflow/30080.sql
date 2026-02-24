
WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostRanks AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
),
CloseReasons AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastClosedDate,
        CR.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CR ON CAST(PH.Comment AS INTEGER) = CR.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId, CR.Name
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UR.BadgeCount,
    P.Title,
    P.ViewCount,
    PR.ScoreRank,
    COALESCE(CR.CloseReason, 'Not Closed') AS CloseReason,
    CR.LastClosedDate
FROM 
    Users U
JOIN 
    UserReputation UR ON U.Id = UR.UserId
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostRanks PR ON P.Id = PR.PostId
LEFT JOIN 
    CloseReasons CR ON P.Id = CR.PostId
WHERE 
    UR.Reputation > 1000 
    AND UR.BadgeCount > 0 
ORDER BY 
    UR.Reputation DESC,
    PR.ScoreRank
LIMIT 10;
