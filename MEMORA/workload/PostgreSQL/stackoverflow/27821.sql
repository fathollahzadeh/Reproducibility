
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1 
    GROUP BY TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagCounts
    WHERE PostCount > 5 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    t.TagName,
    COUNT(ua.UserId) AS ActiveUserCount,
    AVG(ua.PostsCount) AS AvgPostsPerUser,
    SUM(ua.Upvotes) AS TotalUpvotes,
    SUM(ua.Downvotes) AS TotalDownvotes
FROM TopTags t
JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
JOIN UserActivity ua ON p.OwnerUserId = ua.UserId
GROUP BY t.TagName
ORDER BY ActiveUserCount DESC, AvgPostsPerUser DESC;
