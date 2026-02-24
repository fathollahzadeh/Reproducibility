WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS TotalQuestionScore,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END) AS TotalAnswerScore,
        AVG(COALESCE(CAST(P.Score AS FLOAT), 0)) AS AveragePostScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
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
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        PH.UserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    COALESCE(BC.BadgeCount, 0) AS BadgeCount,
    US.PostCount,
    US.QuestionCount,
    US.AnswerCount,
    US.TotalQuestionScore,
    US.TotalAnswerScore,
    US.AveragePostScore,
    COALESCE(PH.EditCount, 0) AS EditCount
FROM 
    UserStatistics US
LEFT JOIN 
    BadgeCounts BC ON US.UserId = BC.UserId
LEFT JOIN 
    PostHistoryStats PH ON US.UserId = PH.UserId
ORDER BY 
    US.Reputation DESC;