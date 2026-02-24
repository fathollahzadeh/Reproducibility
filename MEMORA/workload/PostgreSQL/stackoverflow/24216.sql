WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
        AND v.VoteTypeId IN (8, 9)  
    WHERE 
        p.PostTypeId IN (1, 2)  
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.CommentCount,
        rp.TotalBounty,
        rp.CreationDate,
        p.OwnerUserId,
        p.Title,
        DENSE_RANK() OVER (ORDER BY rp.CommentCount DESC, rp.TotalBounty DESC) AS Rank
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    WHERE 
        rp.UserPostRank = 1  
        AND rp.CommentCount > 5  
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(DISTINCT ph.UserId) AS UniqueEditors
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    fp.Title,
    u.DisplayName AS Owner,
    fp.CommentCount,
    fp.TotalBounty,
    ph.CloseCount,
    ph.ReopenCount,
    ph.UniqueEditors,
    fp.Rank
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.OwnerUserId = u.Id
LEFT JOIN 
    PostHistoryAggregated ph ON fp.PostId = ph.PostId
WHERE 
    (ph.CloseCount > 1 OR ph.ReopenCount > 1)  
    AND (fp.TotalBounty IS NOT NULL AND fp.TotalBounty > 0)  
    AND u.Reputation >= 1000  
ORDER BY 
    fp.Rank, fp.CommentCount DESC;