
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
PostHistoryLatest AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LatestEdit
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Owner,
    rp.CommentCount,
    PH.LatestEdit,
    CASE 
        WHEN rp.CommentCount > 10 THEN 'Popular'
        WHEN rp.CommentCount BETWEEN 1 AND 10 THEN 'Moderate'
        ELSE 'Unpopular' 
    END AS Popularity,
    COALESCE(
        (SELECT STRING_AGG(t.TagName, ', ') 
         FROM Tags t 
         WHERE t.WikiPostId = rp.PostId),
        'No Tags') AS Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryLatest PH ON rp.PostId = PH.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CreationDate DESC 
LIMIT 50;
