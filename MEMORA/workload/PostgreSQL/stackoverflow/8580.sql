WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViewCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users U
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
        PostCount,
        AnswerCount,
        QuestionCount,
        TotalViewCount,
        AcceptedAnswers,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStatistics
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.AnswerCount,
    TU.QuestionCount,
    TU.TotalViewCount,
    TU.AcceptedAnswers,
    CASE 
        WHEN TU.UserRank <= 10 THEN 'Top User'
        WHEN TU.UserRank <= 50 THEN 'Top Contributor'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    TopUsers TU
WHERE 
    TU.QuestionCount > 0
    AND TU.AcceptedAnswers > 0
ORDER BY 
    TU.UserRank
LIMIT 20;
