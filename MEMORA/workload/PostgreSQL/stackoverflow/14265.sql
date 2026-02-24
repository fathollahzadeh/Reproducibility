WITH UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(Id) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        up.TotalPosts,
        up.QuestionCount,
        up.AnswerCount
    FROM 
        Users u
    LEFT JOIN UserPostCounts up ON u.Id = up.OwnerUserId
),
PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    u.UserId,
    u.Reputation,
    u.TotalPosts,
    u.QuestionCount,
    u.AnswerCount,
    ps.PostType,
    ps.PostCount,
    ps.AverageScore,
    ps.AverageViews
FROM 
    UserReputation u
JOIN 
    PostStatistics ps ON u.QuestionCount > 0 AND ps.PostType = 'Question'
ORDER BY 
    u.Reputation DESC, ps.PostCount DESC;