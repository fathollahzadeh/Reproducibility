WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
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
        TotalScore,
        AverageViewCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.TotalScore,
    u.AverageViewCount,
    pt.Name AS PostType,
    pt.Id AS PostTypeId,
    COUNT(c.Id) AS CommentCount
FROM 
    TopUsers u
LEFT JOIN 
    Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
INNER JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    u.ScoreRank <= 10
GROUP BY 
    u.UserId, 
    u.DisplayName, 
    u.PostCount, 
    u.QuestionCount, 
    u.AnswerCount, 
    u.TotalScore, 
    u.AverageViewCount, 
    pt.Name, 
    pt.Id
ORDER BY 
    u.TotalScore DESC;
