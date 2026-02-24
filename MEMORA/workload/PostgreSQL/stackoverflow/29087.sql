WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN ph.PostHistoryTypeId IS NOT NULL THEN 'Edited'
            ELSE 'Original'
        END AS PostStatus
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate = (
            SELECT MAX(CreationDate) 
            FROM PostHistory 
            WHERE PostId = p.Id
        )
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
      AND p.PostTypeId = 1 
),
TagStats AS (
    SELECT 
        unnest(string_to_array(Trim(both '<>' from Tags), '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    rp.PostStatus,
    tt.TagName,
    tt.TagCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON tt.TagName = ANY (string_to_array(rp.Tags, '>'))
WHERE 
    tt.Rank <= 10 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;