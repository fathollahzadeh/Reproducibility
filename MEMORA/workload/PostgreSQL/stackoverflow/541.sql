
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        COALESCE(c.Score, 0) AS CommentsScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT PostId, SUM(Score) AS Score
         FROM Comments
         GROUP BY PostId) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT 'Edited by ' || ph.UserDisplayName || ' on ' || CAST(ph.CreationDate AS DATE), '; ') AS EditHistory
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    rp.Rank,
    COALESCE(rph.EditHistory, 'No edits recorded') AS EditHistory,
    CASE 
        WHEN rp.CommentsScore > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS ActivityStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId
WHERE 
    rp.Rank <= 3 
ORDER BY 
    rp.OwnerDisplayName, rp.Score DESC;
