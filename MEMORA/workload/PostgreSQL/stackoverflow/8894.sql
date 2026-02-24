WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 500
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        QuestionCount,
        AnswerCount,
        TotalViews
    FROM 
        UserReputation
    WHERE 
        Rank <= 10
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.BadgeCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalViews,
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    tu.DisplayName, tu.Reputation, tu.BadgeCount, tu.QuestionCount, tu.AnswerCount, tu.TotalViews, pt.Name
ORDER BY 
    tu.Reputation DESC, TotalPosts DESC;
