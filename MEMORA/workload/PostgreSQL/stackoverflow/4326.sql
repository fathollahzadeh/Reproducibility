
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        DisplayName, 
        Score, 
        CreationDate, 
        Upvotes, 
        Downvotes, 
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        rn = 1
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),
FinalSelection AS (
    SELECT 
        tp.*,
        cp.CloseDate,
        cp.CloseReason
    FROM 
        TopPosts tp
    LEFT JOIN 
        ClosedPosts cp ON tp.PostId = cp.PostId
)
SELECT 
    F.Title,
    F.DisplayName,
    F.Score,
    F.CreationDate,
    COALESCE(F.CommentCount, 0) AS TotalComments,
    COALESCE(F.Upvotes, 0) AS TotalUpvotes,
    COALESCE(F.Downvotes, 0) AS TotalDownvotes,
    CASE WHEN F.CloseDate IS NOT NULL THEN TRUE ELSE FALSE END AS IsClosed,
    F.CloseReason
FROM 
    FinalSelection F
WHERE 
    F.Score > (SELECT AVG(Score) FROM Posts)
ORDER BY 
    F.Score DESC
LIMIT 10;
