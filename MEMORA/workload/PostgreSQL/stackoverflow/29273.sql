
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
FrequentTags AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        u.DisplayName AS ModeratorDisplayName,
        ph.CreationDate AS CloseDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
)
SELECT 
    rp.OwnerDisplayName,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    rp.ViewCount,
    COUNT(DISTINCT ft.Tag) AS FrequentTagCount,
    COUNT(DISTINCT cp.Id) AS ClosedPostCount,
    ARRAY_AGG(DISTINCT ft.Tag) AS FrequentTags,
    COUNT(DISTINCT cp.ModeratorDisplayName) AS UniqueModerators
FROM 
    RankedPosts rp
LEFT JOIN 
    FrequentTags ft ON ft.Tag = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.Id
GROUP BY 
    rp.OwnerDisplayName, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount
HAVING 
    MAX(rp.PostRank) <= 3 
ORDER BY 
    rp.Score DESC, FrequentTagCount DESC;
