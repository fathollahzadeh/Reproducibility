
WITH TagUsage AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))
),
CommonTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagUsage
    WHERE 
        TagCount > 1  
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        pu.DisplayName AS OwnerDisplayName,
        pu.Reputation AS OwnerReputation,
        pu.Location,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users pu ON p.OwnerUserId = pu.Id
    WHERE 
        p.PostTypeId = 1  
)
SELECT 
    ct.TagName,
    ct.TagCount,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.AnswerCount,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    pd.Location
FROM 
    CommonTags ct
JOIN 
    PostDetails pd ON pd.Tags LIKE '%' || ct.TagName || '%'
ORDER BY 
    ct.Rank, pd.ViewCount DESC;
