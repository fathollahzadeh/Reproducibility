
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName
),
UserActivity AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    GROUP BY 
        u.DisplayName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AvgScore,
        AvgViewCount,
        ActiveUsers,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
)
SELECT 
    pt.TagName,
    pt.PostCount,
    pt.QuestionCount,
    pt.AnswerCount,
    pt.AvgScore,
    pt.AvgViewCount,
    pt.ActiveUsers,
    ua.DisplayName AS TopUser,
    ua.TotalPosts,
    ua.TotalUpVotes,
    ua.TotalDownVotes
FROM 
    PopularTags pt
JOIN 
    UserActivity ua ON ua.TotalPosts = (
        SELECT MAX(TotalPosts) 
        FROM UserActivity
    )
WHERE 
    pt.Rank <= 5
ORDER BY 
    pt.PostCount DESC;
