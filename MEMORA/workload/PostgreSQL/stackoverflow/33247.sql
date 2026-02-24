WITH RECURSIVE UserPostSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
BadgeSummary AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(DISTINCT B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
CommentSummary AS (
    SELECT 
        C.UserId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        C.UserId
),
PostHistorySummary AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS PostHistoryCount,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS PostHistoryTypes
    FROM 
        PostHistory PH
    INNER JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.UserId
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.Reputation,
    UPS.PostCount,
    UPS.TotalScore,
    UPS.QuestionCount,
    UPS.AnswerCount,
    COALESCE(BS.BadgeCount, 0) AS BadgeCount,
    COALESCE(BS.BadgeNames, 'None') AS BadgeNames,
    COALESCE(CS.CommentCount, 0) AS CommentCount,
    COALESCE(PH.PostHistoryCount, 0) AS PostHistoryCount,
    COALESCE(PH.PostHistoryTypes, 'None') AS PostHistoryTypes
FROM 
    UserPostSummary UPS
LEFT JOIN 
    BadgeSummary BS ON UPS.UserId = BS.UserId
LEFT JOIN 
    CommentSummary CS ON UPS.UserId = CS.UserId
LEFT JOIN 
    PostHistorySummary PH ON UPS.UserId = PH.UserId
WHERE 
    UPS.Reputation > 1000
ORDER BY 
    UPS.TotalScore DESC
LIMIT 100;