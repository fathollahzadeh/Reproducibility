
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount, p.Score
),
PostHistoryChanges AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        pht.Name AS ChangeType,
        ph.UserDisplayName,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11, 12)  
),
FinalBenchmarkResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.Tags,
        COUNT(phc.PostId) AS ChangeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryChanges phc ON rp.PostId = phc.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.ViewCount, rp.Score, rp.CommentCount, rp.Tags
)
SELECT 
    *,
    CASE 
        WHEN ChangeCount > 3 THEN 'Highly Edited'
        WHEN ChangeCount > 0 THEN 'Moderately Edited'
        ELSE 'No Changes'
    END AS EditStatus
FROM 
    FinalBenchmarkResults
ORDER BY 
    Score DESC, ViewCount DESC, CreationDate ASC
LIMIT 100;
