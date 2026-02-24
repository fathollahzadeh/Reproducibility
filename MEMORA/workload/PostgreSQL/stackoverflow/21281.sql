
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 DAY' 
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
), 
OpenPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.RankByUser,
        rp.CommentCount,
        rp.Score,
        CASE 
            WHEN rp.Score IS NULL THEN 'Score not available' 
            WHEN rp.Score < 0 THEN 'Negative score'
            ELSE 'Score available'
        END AS Score_Status
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByUser = 1
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId AS EditorId,
        u.DisplayName AS EditorName,
        ph.CreationDate AS EditDate,
        CASE 
            WHEN ph.Comment IS NOT NULL THEN ph.Comment
            ELSE 'No comment provided'
        END AS EditComment
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
)

SELECT 
    op.PostId,
    op.Title,
    op.CommentCount,
    op.Score_Status,
    COUNT(DISTINCT phd.EditorId) AS TotalEditors,
    MAX(phd.EditDate) AS LastEditDate,
    STRING_AGG(phd.EditComment, '; ') AS EditorComments
FROM 
    OpenPosts op
LEFT JOIN 
    PostHistoryDetails phd ON op.PostId = phd.PostId
GROUP BY 
    op.PostId, op.Title, op.CommentCount, op.Score_Status
HAVING 
    COUNT(DISTINCT phd.EditorId) > 0
ORDER BY 
    op.CommentCount DESC,
    op.Score_Status DESC;
