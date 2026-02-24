
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(tags, '>')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    GROUP BY 
        unnest(string_to_array(tags, '>'))
    ORDER BY 
        TagCount DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.Score,
    rp.OwnerReputation,
    cp.CloseReason,
    pt.Tag,
    pt.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId AND cp.CloseRank = 1
LEFT JOIN 
    PopularTags pt ON pt.Tag = ANY(string_to_array(rp.Tags, '>'))
WHERE 
    rp.PostRank <= 5
    AND (rp.OwnerReputation IS NULL OR rp.OwnerReputation > 0)
    AND ((rp.Score > 10 OR cp.CloseReason IS NOT NULL)
    OR EXISTS (
        SELECT 1
        FROM Votes v 
        WHERE v.PostId = rp.PostId 
          AND v.UserId IS NULL
    ))
ORDER BY 
    COALESCE(rp.Score, 0) DESC,
    rp.CreationDate ASC;
