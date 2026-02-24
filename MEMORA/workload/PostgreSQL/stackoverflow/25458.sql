
WITH PostTags AS (
    SELECT 
        p.Id AS PostId, 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
PopularTags AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagUsage
    FROM 
        PostTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalUpvotes DESC
    LIMIT 10
),
TagPostCounts AS (
    SELECT 
        pt.Tag, 
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    GROUP BY 
        pt.Tag
    ORDER BY 
        PostCount DESC
)
SELECT 
    u.DisplayName AS TopUser, 
    u.TotalUpvotes, 
    u.TotalDownvotes, 
    tg.Tag, 
    tg.PostCount
FROM 
    TopUsers u
JOIN 
    TagPostCounts tg ON u.TotalPosts > 1 
WHERE 
    tg.Tag IN (SELECT Tag FROM PopularTags)
ORDER BY 
    u.TotalUpvotes DESC, 
    tg.PostCount DESC;
