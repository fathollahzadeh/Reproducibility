WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(coalesce(p.ViewCount, 0)) AS TotalViews,
        SUM(coalesce(p.Score, 0)) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewsPerPost
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopTags AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.Id, t.TagName
    ORDER BY TotalViews DESC
    LIMIT 10
),
UserRankings AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        RANK() OVER (ORDER BY ua.Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY ua.TotalViews DESC) AS ViewsRank,
        RANK() OVER (ORDER BY ua.PostCount DESC) AS PostsRank
    FROM UserActivity ua
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationRank,
    ur.ViewsRank,
    ur.PostsRank,
    tt.TagName,
    tt.TotalViews AS TagTotalViews,
    tt.PostCount AS TagPostCount
FROM UserRankings ur
JOIN TopTags tt ON tt.PostCount > 5  
ORDER BY ur.Reputation DESC, tt.TotalViews DESC;