
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Posts.Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        UNNEST(string_to_array(Posts.Tags, '><'))
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserPostCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        p.TotalPosts,
        p.TotalQuestions,
        p.TotalAnswers
    FROM 
        Users u
    JOIN 
        UserPostCounts p ON u.Id = p.OwnerUserId
    WHERE 
        u.LastAccessDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TagEngagement AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    au.UserId,
    au.DisplayName,
    au.Reputation,
    ub.TotalBadges,
    ub.LastBadgeDate,
    tg.TagName,
    tg.TagCount,
    pe.PostType,
    pe.VoteCount,
    pe.Upvotes,
    pe.Downvotes
FROM
    ActiveUsers au
LEFT JOIN 
    UserBadges ub ON au.UserId = ub.UserId
LEFT JOIN 
    PopularTags tg ON TRUE 
LEFT JOIN 
    TagEngagement pe ON TRUE 
ORDER BY 
    au.Reputation DESC, 
    tg.TagCount DESC, 
    pe.VoteCount DESC;
