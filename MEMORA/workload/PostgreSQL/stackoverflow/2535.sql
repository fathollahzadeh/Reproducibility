
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS tag,
        COUNT(*) AS tag_count
    FROM 
        Posts
    WHERE 
        CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        tag
    HAVING 
        COUNT(*) > 5
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalViews,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    pt.tag AS PopularTag,
    ra.PostId,
    ra.Title AS RecentPostTitle,
    ra.CreationDate AS RecentPostDate
FROM 
    UserActivity ua
LEFT JOIN 
    PopularTags pt ON ua.TotalPosts > 10
LEFT JOIN 
    RecentActivity ra ON ua.UserId = ra.PostId
WHERE 
    ua.TotalViews > 100
ORDER BY 
    ua.TotalPosts DESC, ua.TotalViews DESC;
