WITH PostCounts AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserReputation AS (
    SELECT 
        AVG(Reputation) AS AvgReputation,
        COUNT(*) AS TotalUsers
    FROM 
        Users
),
PopularTags AS (
    SELECT 
        Tags,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tags
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    p.PostTypeId,
    p.TotalPosts,
    p.AvgViewCount,
    p.AvgScore,
    u.AvgReputation,
    u.TotalUsers,
    t.Tags,
    t.TagCount
FROM 
    PostCounts p,
    UserReputation u,
    PopularTags t;