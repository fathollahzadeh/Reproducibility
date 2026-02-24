
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE((
            SELECT COUNT(*)
            FROM Comments c
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS MostActivePostForUser
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') 
        AND p.Score >= 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, ', ') AS CloseReasons
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
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    COALESCE(cp.CloseReasons, 'Not Closed') AS CloseReasons,
    CASE 
        WHEN rp.RankByType <= 5 THEN 'Hot Post'
        WHEN rp.MostActivePostForUser = 1 THEN 'User''s Most Active Post'
        ELSE 'Regular Post'
    END AS PostStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(p.Tags, '><')) AS TagName
        FROM 
            Posts p
        WHERE 
            p.Id = rp.PostId
    ) t ON TRUE
WHERE 
    rp.CommentCount > 3 
    OR (cp.CloseReasons IS NOT NULL AND rp.Score < 5)
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, 
    rp.CommentCount, cp.CloseReasons, rp.RankByType, 
    rp.MostActivePostForUser
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
