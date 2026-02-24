WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        COALESCE(NULLIF(p.Tags, ''), '@EMPTY') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostTags AS (
    SELECT 
        p.PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '> <')) AS Tag
    FROM 
        RankedPosts p
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PostTags
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TopRank
    FROM 
        TagCounts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Owner,
    rp.CreationDate,
    rp.Score,
    rp.Tags,
    tt.Tag AS MostUsedTag,
    tt.TagCount AS MostUsedTagCount,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        ELSE 'Other'
    END AS PostType,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = rp.PostId 
        AND v.VoteTypeId = 3) AS DownVotes,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = rp.PostId 
        AND v.VoteTypeId = 2) AS UpVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON tt.TopRank = 1
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;