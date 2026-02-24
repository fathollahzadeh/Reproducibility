WITH FrequentTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
),
TagUsage AS (
    SELECT 
        Tag, 
        COUNT(*) AS UsageCount
    FROM 
        FrequentTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10  
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        u.Id, u.Reputation
),
CombinedData AS (
    SELECT 
        tr.Tag,
        ur.UserId,
        ur.Reputation,
        ur.PostCount
    FROM 
        TagUsage tr
    CROSS JOIN 
        UserReputation ur
)
SELECT 
    Tag,
    COUNT(DISTINCT UserId) AS UserCount,
    AVG(Reputation) AS AverageReputation,
    SUM(PostCount) AS TotalPosts
FROM 
    CombinedData
GROUP BY 
    Tag
ORDER BY 
    UserCount DESC;