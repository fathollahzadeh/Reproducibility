
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.CreationDate >= DATE '2020-01-01'
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName, 
        COUNT(*) AS TagUsageCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        unnest(string_to_array(Tags, ','))
)
SELECT 
    ua.UserId, 
    ua.DisplayName, 
    ua.PostCount, 
    ua.UpvoteCount, 
    ua.DownvoteCount, 
    ua.BadgeCount, 
    ua.CommentCount,
    pt.TagName,
    pt.TagUsageCount
FROM 
    UserActivity ua
CROSS JOIN 
    PopularTags pt
ORDER BY 
    ua.PostCount DESC, 
    pt.TagUsageCount DESC
LIMIT 100;
