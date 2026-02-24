
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') 
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS PopularityRank
    FROM 
        TagCounts
    WHERE 
        TagCount > 10 
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ActionTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.Reputation,
    pt.Tag AS PopularTag,
    pha.HistoryCount,
    pha.ActionTypes
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.Tag = ANY (string_to_array(SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags) - 2), '><'))
LEFT JOIN 
    PostHistoryAnalysis pha ON pha.PostId = rp.PostId
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.ViewCount DESC, 
    rp.Reputation DESC
LIMIT 50;
