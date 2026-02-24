
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerName,
        u.Reputation AS OwnerReputation,
        ph.CreationDate AS PostCreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId IN (1, 2, 4)
    WHERE 
        p.PostTypeId = 1 
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS Tag,
        COUNT(*) AS TagFrequency
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        unnest(string_to_array(Tags, '>'))
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerName,
    rp.OwnerReputation,
    rp.PostCreationDate,
    tc.Tag,
    tc.TagFrequency,
    COALESCE(cp.CloseCount, 0) AS CloseCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TagCounts tc ON rp.Tags LIKE '%' || tc.Tag || '%'
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.rn = 1 
ORDER BY 
    rp.OwnerReputation DESC, 
    CloseCount DESC, 
    rp.PostCreationDate DESC;
