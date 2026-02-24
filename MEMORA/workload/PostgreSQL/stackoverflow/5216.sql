
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 AND ph.Id IS NOT NULL THEN 1 ELSE 0 END) AS ClosedQuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        ClosedQuestionCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
)
SELECT 
    t.DisplayName,
    t.Reputation,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.ClosedQuestionCount,
    CASE 
        WHEN t.ReputationRank <= 10 THEN 'Top User'
        WHEN t.ReputationRank <= 50 THEN 'Moderately Active User'
        ELSE 'New User'
    END AS UserCategory
FROM 
    TopUsers t
WHERE 
    t.Reputation > 1000
ORDER BY 
    t.Reputation DESC, t.PostCount DESC;
