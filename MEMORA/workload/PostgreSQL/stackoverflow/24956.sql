
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalScores AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Owner,
        rp.CreationDate,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(cp.ClosedDate, NULL) AS ClosedDate,
        COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason,
        CASE 
            WHEN COALESCE(cp.ClosedDate, NULL) IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.rn <= 5 
)
SELECT 
    fs.*,
    CASE 
        WHEN fs.CommentCount > 10 THEN 'High Engagement'
        WHEN fs.CommentCount BETWEEN 5 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    FinalScores fs
ORDER BY 
    fs.CreationDate DESC, fs.CommentCount DESC;
