WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 2 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostHistoryCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        Users U
    LEFT JOIN 
        PostHistory PH ON U.Id = PH.UserId
    GROUP BY 
        U.Id
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    US.QuestionCount,
    US.AnswerCount,
    US.AcceptedAnswerCount,
    US.PositiveScoreCount,
    COALESCE(BC.BadgeCount, 0) AS BadgeCount,
    COALESCE(PHC.HistoryCount, 0) AS PostHistoryCount
FROM 
    UserStats US
LEFT JOIN 
    BadgeCounts BC ON US.UserId = BC.UserId
LEFT JOIN 
    PostHistoryCounts PHC ON US.UserId = PHC.UserId
ORDER BY 
    US.Reputation DESC, US.PostCount DESC;
