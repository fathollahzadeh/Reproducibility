
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCreated,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCreated
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= '2022-01-01'
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostsCreated, 
        TotalViews, 
        AnswersCreated, 
        QuestionsCreated,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        UserActivity
)
SELECT 
    tu.UserId, 
    tu.DisplayName, 
    tu.PostsCreated, 
    tu.TotalViews, 
    tu.AnswersCreated, 
    tu.QuestionsCreated,
    b.Name AS BadgeName,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
LEFT JOIN 
    Comments c ON c.UserId = tu.UserId
WHERE 
    tu.ViewRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.PostsCreated, tu.TotalViews, tu.AnswersCreated, tu.QuestionsCreated, b.Name
ORDER BY 
    tu.TotalViews DESC;
