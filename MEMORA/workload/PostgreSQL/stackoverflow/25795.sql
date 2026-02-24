
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Owner,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        AVG(v.VoteTypeId) AS AvgVoteType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),

PostTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),

TopTags AS (
    SELECT 
        Tag,
        COUNT(PostId) AS TagCount
    FROM 
        PostTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 5
)

SELECT 
    rp.Title,
    rp.Body,
    rp.Owner,
    rp.CommentCount,
    tt.Tag AS PopularTag,
    AVG(rp.AvgVoteType) AS AverageVotePerTag
FROM 
    RankedPosts rp
JOIN 
    PostTags pt ON rp.PostId = pt.PostId
JOIN 
    TopTags tt ON pt.Tag = tt.Tag
GROUP BY 
    rp.Title, rp.Body, rp.Owner, rp.CommentCount, tt.Tag
ORDER BY 
    AverageVotePerTag DESC;
