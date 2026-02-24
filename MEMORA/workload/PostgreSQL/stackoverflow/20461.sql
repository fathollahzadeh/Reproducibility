
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
RecentHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) 
            THEN CURRENT_TIMESTAMP - ph.CreationDate 
            ELSE NULL 
        END AS CloseReopenDuration
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
),
PostClosed AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        RecentHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(TRIM(tag), ', ') AS CombinedTags
    FROM 
        Posts p,
        UNNEST(string_to_array(p.Tags, '>')) AS tag
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerReputation,
    COALESCE(pct.CloseCount, 0) AS CloseCount,
    CASE 
        WHEN pct.CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    pwt.CombinedTags,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Votes v 
            WHERE v.PostId = rp.PostId 
              AND v.VoteTypeId = 2 
              AND v.UserId IN (SELECT Id FROM Users WHERE Reputation < 100)
        ) 
        THEN 'High score but downvoted by low-reputation users'
        ELSE 'No unusual downvotes'
    END AS VoteNote
FROM 
    RankedPosts rp
LEFT JOIN 
    PostClosed pct ON rp.PostId = pct.PostId
LEFT JOIN 
    PostsWithTags pwt ON rp.PostId = pwt.PostId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, 
    pwt.CombinedTags ASC;
