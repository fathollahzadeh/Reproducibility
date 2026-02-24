
WITH TagCounts AS (
    SELECT 
        TRIM(UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TRIM(UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')))
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        tc.TagName,
        tc.PostCount,
        ROW_NUMBER() OVER (ORDER BY tc.PostCount DESC) AS Rank
    FROM 
        TagCounts tc
    WHERE 
        tc.PostCount > 5  
),
TopUsers AS (
    SELECT 
        au.UserId,
        au.DisplayName,
        au.QuestionCount,
        au.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY au.QuestionCount DESC) AS Rank
    FROM 
        ActiveUsers au
    WHERE 
        au.QuestionCount > 0
)
SELECT 
    t.TagName,
    t.PostCount,
    u.DisplayName AS TopUser,
    u.QuestionCount,
    u.TotalBounty
FROM 
    TopTags t
LEFT JOIN 
    TopUsers u ON u.Rank = 1  
ORDER BY 
    t.PostCount DESC, u.TotalBounty DESC;
