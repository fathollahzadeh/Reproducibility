WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounties,
        AVG(P.Score) AS AvgPostScore,
        MAX(P.CreationDate) AS MostRecentPost
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    US.UserId,
    US.Reputation,
    US.PostCount,
    US.QuestionCount,
    US.AnswerCount,
    US.TotalBounties,
    US.AvgPostScore,
    US.MostRecentPost,
    BC.BadgeCount
FROM 
    UserStats US
LEFT JOIN 
    BadgeCounts BC ON US.UserId = BC.UserId
ORDER BY 
    US.Reputation DESC, US.PostCount DESC;