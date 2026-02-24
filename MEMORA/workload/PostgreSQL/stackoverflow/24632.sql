
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(vb.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vb ON p.Id = vb.PostId AND vb.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.Rank,
        rp.CommentCount,
        rp.TotalBounty
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
        AND rp.CommentCount > 0
),
PostWithCloseReasons AS (
    SELECT 
        p.Id AS PostId,
        ph.Comment AS CloseReason,
        COUNT(*) AS CloseReasonCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        p.Id, ph.Comment
)
SELECT 
    fp.Title AS PostTitle,
    fp.Score,
    fp.CommentCount,
    COALESCE(pcr.CloseReason, 'No Close Reason') AS CloseReason,
    fp.TotalBounty
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostWithCloseReasons pcr ON fp.PostId = pcr.PostId
ORDER BY 
    fp.Score DESC,
    fp.PostId
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
