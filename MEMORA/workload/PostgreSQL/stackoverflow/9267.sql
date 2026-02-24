
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount,
        QuestionCount,
        AnswerCount,
        AcceptedAnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY AcceptedAnswerCount DESC) AS AcceptedAnswerRank
    FROM 
        UserPostStats
)
SELECT 
    tu.DisplayName, 
    tu.PostCount, 
    tu.QuestionCount, 
    tu.AnswerCount, 
    tu.AcceptedAnswerCount,
    CASE 
        WHEN tu.PostRank <= 10 THEN 'Top Contributors'
        ELSE 'Other Contributors'
    END AS ContributorType,
    COALESCE(b.Name, 'No Badge') AS TopBadge
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId AND b.Class = 1
WHERE 
    tu.QuestionCount > 0
ORDER BY 
    tu.PostCount DESC, 
    tu.AcceptedAnswerCount DESC;
