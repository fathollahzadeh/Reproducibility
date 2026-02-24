
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        TRIM(BOTH '{}' FROM unnest(string_to_array(Tags, '><'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.UpVotes,
    us.DownVotes,
    us.TotalPosts,
    us.TotalComments,
    COALESCE(pt.TagCount, 0) AS PopularTagCount
FROM 
    UserStats us
LEFT JOIN 
    PopularTags pt ON us.TotalPosts > 2 AND us.DisplayName LIKE '%' || pt.TagName || '%'
WHERE 
    us.Reputation > 100
ORDER BY 
    us.TotalPosts DESC,
    us.UpVotes DESC;
