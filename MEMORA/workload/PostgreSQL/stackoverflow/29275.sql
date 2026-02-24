
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ph.CreationDate AS PostCreationDate,
        ph.RevisionGUID,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY ph.CreationDate DESC) AS LatestRevision
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
FilteredPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.LatestRevision = 1  
),
TagCounts AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR (CHAR_LENGTH(Tags) - 2)), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 1  
)
SELECT 
    t.Tag,
    t.PostCount,
    f.Title,
    f.OwnerDisplayName,
    f.PostCreationDate,
    f.RevisionGUID
FROM 
    TopTags t
JOIN 
    FilteredPosts f ON f.Tags LIKE '%' || t.Tag || '%' 
WHERE 
    t.TagRank <= 5  
ORDER BY 
    t.PostCount DESC, 
    f.PostCreationDate DESC;
