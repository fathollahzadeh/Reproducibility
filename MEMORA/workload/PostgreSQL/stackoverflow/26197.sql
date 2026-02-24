
WITH TagsSplit AS (
    SELECT 
        Id AS PostId,
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
),

GroupedTags AS (
    SELECT 
        Tag,
        COUNT(PostId) AS PostCount
    FROM 
        TagsSplit
    GROUP BY 
        Tag
    HAVING 
        COUNT(PostId) > 10  
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId 
                  AND p.PostTypeId = 1  
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        QuestionCount DESC
    LIMIT 5  
),

UserTags AS (
    SELECT 
        u.Id AS UserId,
        ts.Tag,
        COUNT(ts.Tag) AS TagCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    JOIN 
        TagsSplit ts ON p.Id = ts.PostId
    GROUP BY 
        u.Id, ts.Tag
)

SELECT 
    u.DisplayName,
    u.QuestionCount,
    u.TotalBounty,
    STRING_AGG(DISTINCT ut.Tag || ' (' || ut.TagCount || ')', ', ') AS PopularTags
FROM 
    TopUsers u
LEFT JOIN 
    UserTags ut ON u.UserId = ut.UserId
LEFT JOIN 
    GroupedTags g ON ut.Tag = g.Tag
GROUP BY 
    u.UserId, u.DisplayName, u.QuestionCount, u.TotalBounty
ORDER BY 
    u.QuestionCount DESC;
