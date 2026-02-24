WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END), 0) AS TagWikiCount,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViewCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        BadgeCount, 
        QuestionCount, 
        AnswerCount, 
        TotalViewCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY TotalViewCount DESC) AS ViewCountRank
    FROM 
        UserStats
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.BadgeCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalViewCount,
    CASE 
        WHEN TU.ReputationRank <= 10 THEN 'Top Reputation User'
        WHEN TU.ViewCountRank <= 10 THEN 'Top Viewed User'
        ELSE 'Regular User'
    END AS UserType
FROM 
    TopUsers TU
WHERE 
    TU.QuestionCount > 10 OR TU.AnswerCount > 10
ORDER BY 
    TU.Reputation DESC, TU.TotalViewCount DESC
LIMIT 50;
