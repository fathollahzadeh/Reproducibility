
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
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
        TotalScore,
        TotalViews,
        QuestionCount,
        AnswerCount,
        DENSE_RANK() OVER (ORDER BY TotalScore DESC) AS RankByScore
    FROM 
        UserPostStats
),
TopQuestions AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
    ORDER BY 
        VoteCount DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.TotalScore,
    tu.TotalViews,
    tq.Title AS TopQuestionTitle,
    tq.ViewCount AS QuestionViews,
    tq.VoteCount AS QuestionVoteCount,
    tq.CreationDate
FROM 
    TopUsers tu
JOIN 
    TopQuestions tq ON tq.OwnerName = tu.DisplayName
WHERE 
    tu.RankByScore <= 5
ORDER BY 
    tu.TotalScore DESC, tq.VoteCount DESC;
