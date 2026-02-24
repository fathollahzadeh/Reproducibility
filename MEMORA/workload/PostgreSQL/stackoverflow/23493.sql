WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.CommentCount,
        rp.VoteCount,
        CASE 
            WHEN rp.ViewCount IS NULL THEN 'No Views'
            WHEN rp.ViewCount < 10 THEN 'Low Views'
            WHEN rp.ViewCount < 100 THEN 'Medium Views'
            ELSE 'High Views'
        END AS ViewCategory,
        COALESCE((SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = rp.PostId AND ph.PostHistoryTypeId IN (10, 11)), 0) AS CloseVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rn = 1
),
AggregatePostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgScore,
        SUM(CASE WHEN ViewCategory = 'Low Views' THEN 1 ELSE 0 END) AS LowViewPosts,
        SUM(CASE WHEN CloseVoteCount > 0 THEN 1 ELSE 0 END) AS ClosedPosts
    FROM 
        PostDetails
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.ViewCategory,
    ps.TotalPosts,
    ps.AvgScore,
    ps.LowViewPosts,
    ps.ClosedPosts
FROM 
    PostDetails pd
CROSS JOIN 
    AggregatePostStats ps
WHERE 
    pd.Score >= (SELECT AVG(Score) FROM PostDetails)
ORDER BY 
    pd.Score DESC NULLS LAST
LIMIT 
    100;