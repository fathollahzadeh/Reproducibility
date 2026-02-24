WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason,
        pt.Name AS PostType
    FROM 
        PostHistory ph 
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        pht.Name = 'Post Closed'
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.RankScore,
        rp.CommentCount,
        rp.TotalBounty,
        cp.CloseDate,
        cp.CloseReason,
        cp.PostType
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    COALESCE(ps.RankScore, 0) AS Rank,
    ps.CommentCount,
    ps.TotalBounty,
    CASE 
        WHEN ps.CloseDate IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS Status,
    CASE 
        WHEN ps.CloseReason IS NULL AND ps.CloseDate IS NOT NULL THEN 'No Reason Provided' 
        ELSE COALESCE(ps.CloseReason, 'N/A') 
    END AS CloseReason
FROM 
    PostSummary ps
WHERE 
    (ps.Score > 20 OR ps.CommentCount > 5)
    AND (ps.CloseDate IS NULL OR ps.CloseDate = (
        SELECT MAX(CloseDate) 
        FROM ClosedPosts 
        WHERE PostId = ps.PostId
    ))
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;