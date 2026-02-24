
WITH TagStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts 
    GROUP BY 
        TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS PostsClosed,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS PostsReopened
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TagUserEngagement AS (
    SELECT 
        ts.TagName,
        ua.UserId,
        ua.DisplayName,
        SUM(ua.PostsCreated) AS TotalPosts,
        SUM(ua.PostsClosed) AS TotalClosed,
        SUM(ua.PostsReopened) AS TotalReopened
    FROM 
        TagStats ts
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', ts.TagName, '%')
    JOIN 
        UserActivity ua ON p.OwnerUserId = ua.UserId
    GROUP BY 
        ts.TagName, ua.UserId, ua.DisplayName
)
SELECT 
    t.TagName,
    COUNT(DISTINCT ua.UserId) AS UniqueUsersEngaged,
    SUM(tu.TotalPosts) AS PostsEngaged,
    SUM(tu.TotalClosed) AS TotalPostsClosed,
    SUM(tu.TotalReopened) AS TotalPostsReopened
FROM 
    TagUserEngagement tu
JOIN 
    TagStats t ON tu.TagName = t.TagName
JOIN 
    UserActivity ua ON tu.UserId = ua.UserId
GROUP BY 
    t.TagName
ORDER BY 
    PostsEngaged DESC;
