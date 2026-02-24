
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AvgScore,
        MAX(p.ViewCount) AS MaxViews,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopAuthors
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
PostTypeStats AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.CommentCount) AS TotalComments,
        AVG(p.Score) AS AverageScore,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedCount
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserReputation AS (
    SELECT 
        u.DisplayName,
        SUM(b.Class) AS BadgeScore,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.DisplayName, u.Reputation, u.Views
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgScore,
    ts.MaxViews,
    ts.TopAuthors,
    pt.PostTypeName,
    pt.TotalPosts,
    pt.TotalComments,
    pt.AverageScore,
    pt.ClosedCount,
    ur.DisplayName AS TopUser,
    ur.BadgeScore,
    ur.Reputation AS UserReputation,
    ur.Views AS UserViews,
    ur.TotalPosts AS UserTotalPosts
FROM 
    TagStats ts
JOIN 
    PostTypeStats pt ON ts.PostCount > 0
JOIN 
    UserReputation ur ON ur.TotalPosts = (SELECT MAX(TotalPosts) FROM UserReputation)
ORDER BY 
    ts.PostCount DESC, 
    pt.TotalPosts DESC
FETCH FIRST 10 ROWS ONLY;
