
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) OVER() AS AvgReputation
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
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM 
        UserPostStats
    WHERE 
        PostCount > 0
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
    CASE 
        WHEN tu.QuestionCount > 10 AND tu.AnswerCount > 20 THEN 'Active Contributor'
        WHEN tu.QuestionCount > 5 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributionLevel
FROM 
    TopUsers tu
LEFT JOIN 
    Votes v ON v.UserId = tu.UserId
WHERE 
    tu.PostRank <= 10
GROUP BY 
    tu.DisplayName, tu.PostCount, tu.QuestionCount, tu.AnswerCount
ORDER BY 
    tu.PostCount DESC;
