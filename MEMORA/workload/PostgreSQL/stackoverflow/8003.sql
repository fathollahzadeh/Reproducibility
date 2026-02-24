
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(v.BountyAmount) AS TotalBountyEarned,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 1000 
        AND u.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        TotalBountyEarned
    FROM 
        UserActivity
    WHERE 
        ActivityRank <= 10
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.AnswerCount,
    tu.QuestionCount,
    tu.TotalBountyEarned,
    AVG(COALESCE(ph.UserId, 0)) AS AveragePostHistoryChanges
FROM 
    TopUsers tu
LEFT JOIN 
    PostHistory ph ON ph.UserId = tu.UserId
GROUP BY 
    tu.UserId, tu.DisplayName, tu.PostCount, tu.AnswerCount, tu.QuestionCount, tu.TotalBountyEarned
ORDER BY 
    tu.TotalBountyEarned DESC;
