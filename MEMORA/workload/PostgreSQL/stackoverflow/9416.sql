WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS PositiveScore,
        SUM(CASE WHEN p.Score < 0 THEN p.Score ELSE 0 END) AS NegativeScore,
        AVG(COALESCE(CAST(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)) AS FLOAT), 0)) AS AvgTimeToActivity
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
        AnswerCount,
        QuestionCount,
        PositiveScore,
        NegativeScore,
        AvgTimeToActivity,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserPostStats
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.PositiveScore,
    tu.NegativeScore,
    tu.AvgTimeToActivity
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
