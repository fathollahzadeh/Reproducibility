
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN p.ViewCount ELSE 0 END), 0) AS TotalViews,
        AVG(u.Reputation) AS AverageReputation 
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
        TotalViews,
        AverageReputation,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        UserStats
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalViews,
    tu.AverageReputation,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = tu.UserId) AS BadgeCount,
    (SELECT STRING_AGG(pt.Name, ', ') FROM PostTypes pt JOIN Posts p ON p.PostTypeId = pt.Id WHERE p.OwnerUserId = tu.UserId) AS PostTypeSummary
FROM 
    TopUsers tu
WHERE 
    tu.ViewRank <= 10
ORDER BY 
    tu.ViewRank;
