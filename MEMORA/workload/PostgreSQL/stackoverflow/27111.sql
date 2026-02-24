WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.Tags,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag
    FROM 
        RankedPosts
    WHERE 
        Tags IS NOT NULL
),
PopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        TagStatistics
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    STRING_AGG(DISTINCT pt.Tag, ', ') AS PopularTags
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.Tag = ANY(string_to_array(rp.Tags, '><'))
WHERE 
    rp.PostRank = 1
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.OwnerDisplayName, rp.CreationDate, rp.Score, rp.ViewCount
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;