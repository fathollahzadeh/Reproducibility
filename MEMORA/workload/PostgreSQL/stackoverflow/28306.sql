WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore,
        MAX(p.CreationDate) AS RecentPostDate
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserActivity AS (
    SELECT 
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.DisplayName
),
PostTrends AS (
    SELECT 
        p.OwnerDisplayName,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts
    FROM 
        Posts p
    GROUP BY 
        p.OwnerDisplayName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgViewCount,
    ts.AvgScore,
    ts.RecentPostDate,
    ua.DisplayName AS ActiveUser,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.TotalComments,
    ua.TotalBadges,
    pt.TotalPosts,
    pt.PositivePosts,
    pt.PopularPosts
FROM 
    TagStats ts
JOIN 
    UserActivity ua ON ua.TotalUpVotes > 0
JOIN 
    PostTrends pt ON pt.TotalPosts > 5
ORDER BY 
    ts.PostCount DESC, ua.TotalUpVotes DESC, pt.TotalPosts DESC;
