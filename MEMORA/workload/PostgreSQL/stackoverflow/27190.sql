
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) / 60) AS AvgPostAgeMinutes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation >= 1000
    GROUP BY 
        u.Id, u.DisplayName
),

PopularTags AS (
    SELECT 
        tag.TagName,
        COUNT(p.Id) AS TagPostCount
    FROM 
        Tags tag
    JOIN Posts p ON p.Tags LIKE CONCAT('%', tag.TagName, '%')
    GROUP BY 
        tag.TagName
    HAVING 
        COUNT(p.Id) > 10
),

RecentPostHistory AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId, ph.PostId
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.AvgPostAgeMinutes,
    ua.Upvotes,
    ua.Downvotes,
    pt.TagName,
    pt.TagPostCount,
    rph.LastEditDate
FROM 
    UserActivity ua
LEFT JOIN PopularTags pt ON ua.TotalPosts > 0  
LEFT JOIN RecentPostHistory rph ON ua.UserId = rph.UserId
ORDER BY 
    ua.TotalPosts DESC, ua.Upvotes DESC
FETCH FIRST 50 ROWS ONLY;
