
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (12, 13)) AS DeleteUndeleteCount,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 2) AS InitialBodyEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.VoteCount,
    rp.Tags,
    ph.CloseReopenCount,
    ph.DeleteUndeleteCount,
    ph.InitialBodyEdits
FROM 
    RankedPosts rp
JOIN 
    PostHistoryStats ph ON rp.PostId = ph.PostId
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC,
    rp.CreationDate ASC
LIMIT 100;
