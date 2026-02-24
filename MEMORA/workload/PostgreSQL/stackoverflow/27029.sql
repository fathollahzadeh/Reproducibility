WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
RecentPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CreationDate
    FROM 
        RankedPosts
    WHERE 
        rn <= 5 
),
TagStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
FrequentTags AS (
    SELECT 
        TagName
    FROM 
        TagStats
    WHERE 
        PostCount > 10 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CreationDate,
    ft.TagName
FROM 
    RecentPosts rp
JOIN 
    FrequentTags ft ON ft.TagName = ANY (string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
ORDER BY 
    rp.CreationDate DESC;