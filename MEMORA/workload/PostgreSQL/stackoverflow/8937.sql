WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Location,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.AnswerCount > 0 THEN 1 ELSE 0 END) AS QuestionsWithAnswers,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Location
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Location,
        PostCount,
        AnswerCount,
        QuestionsWithAnswers
    FROM 
        RankedUsers
    WHERE 
        ReputationRank <= 10
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.Location,
    tu.PostCount,
    tu.AnswerCount,
    tu.QuestionsWithAnswers,
    b.Name AS BadgeName,
    bh.Date AS BadgeDate
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
LEFT JOIN 
    (SELECT UserId, MAX(Date) AS Date FROM Badges GROUP BY UserId) bh ON tu.UserId = bh.UserId
ORDER BY 
    tu.Reputation DESC, 
    tu.DisplayName;
