WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '90 days' 
),
TopTags AS (
    SELECT 
        Tags,
        COUNT(*) AS PostCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
    GROUP BY 
        Tags
    ORDER BY 
        PostCount DESC
    LIMIT 10 
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (4, 5, 24)) AS EditCount 
    FROM 
        PostHistory ph
    JOIN 
        RankedPosts rp ON ph.PostId = rp.PostId
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    th.PostCount,
    pha.LastEditDate,
    pha.EditCount
FROM 
    RankedPosts rp
JOIN 
    TopTags th ON rp.Tags = th.Tags
JOIN 
    PostHistoryAggregated pha ON rp.PostId = pha.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    th.PostCount DESC, rp.Score DESC;