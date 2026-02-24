WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND u.Location IS NOT NULL
        AND u.Reputation > 1000
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10
),
PostTagCount AS (
    SELECT 
        fp.PostId,
        COUNT(*) AS TagCount
    FROM 
        FilteredPosts fp
    CROSS JOIN 
        unnest(string_to_array(substring(fp.Tags, 2, length(fp.Tags)-2), '><')) AS tag
    GROUP BY 
        fp.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.Score,
    fp.OwnerDisplayName,
    fp.CommentCount,
    pt.TagCount
FROM 
    FilteredPosts fp
JOIN 
    PostTagCount pt ON fp.PostId = pt.PostId
ORDER BY 
    pt.TagCount DESC, fp.Score DESC;