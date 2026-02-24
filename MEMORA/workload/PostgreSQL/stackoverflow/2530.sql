WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        COALESCE(cp.CloseReason, 'Open') AS Status,
        rp.CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.Rank = 1 
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.Author,
    tq.CreationDate,
    tq.Score,
    tq.Status,
    tq.CommentCount,
    CASE 
        WHEN tq.Score IS NULL THEN 'No Score'
        WHEN tq.Score > 100 THEN 'High Score'
        ELSE 'Moderate Score'
    END AS ScoreCategory
FROM 
    TopQuestions tq
WHERE 
    tq.CommentCount > 0 OR tq.Status = 'Closed'
ORDER BY 
    tq.Score DESC, tq.CreationDate ASC
LIMIT 50;