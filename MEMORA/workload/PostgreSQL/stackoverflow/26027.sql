
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS TotalWikiPosts,
        SUM(p.ViewCount) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS TagName,
        COUNT(*) AS TagUsageCount
    FROM Posts
    WHERE Tags IS NOT NULL
    GROUP BY unnest(string_to_array(Tags, '>'))
),
TopTags AS (
    SELECT 
        TagName,
        TagUsageCount
    FROM PopularTags
    ORDER BY TagUsageCount DESC
    LIMIT 10
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsUsed
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Tags t ON t.TagName = ANY(string_to_array(p.Tags, '>'))
    GROUP BY p.Id
)
SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalWikiPosts,
    ups.TotalViews,
    t.TagName,
    t.TagUsageCount,
    pi.CommentCount,
    pi.VoteCount,
    pi.TagsUsed
FROM UserPostStats ups
JOIN PostInteractions pi ON ups.UserId = pi.PostId
JOIN TopTags t ON t.TagName = ANY(pi.TagsUsed)
ORDER BY ups.TotalPosts DESC, t.TagUsageCount DESC;
