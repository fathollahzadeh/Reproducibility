
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS UserDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Tags, u.DisplayName
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '><'))) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TagFrequency AS (
    SELECT 
        Tag, COUNT(*) AS Frequency
    FROM 
        PopularTags
    GROUP BY 
        Tag
    ORDER BY 
        Frequency DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.UserDisplayName,
    rp.CommentCount,
    rp.VoteCount,
    tf.Tag AS TopTag,
    tf.Frequency AS TagFrequency
FROM 
    RankedPosts rp
LEFT JOIN 
    TagFrequency tf ON rp.Tags LIKE '%' || tf.Tag || '%' 
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
