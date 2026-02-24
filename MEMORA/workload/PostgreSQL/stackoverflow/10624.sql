
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AverageReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    ORDER BY p.ViewCount DESC
    LIMIT 10
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.TotalViews,
    us.QuestionCount,
    us.AnswerCount,
    us.AverageReputation,
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount AS TopPostViewCount,
    tp.OwnerDisplayName
FROM UserStats us
LEFT JOIN TopPosts tp ON us.DisplayName = tp.OwnerDisplayName 
ORDER BY us.TotalViews DESC
LIMIT 50;
