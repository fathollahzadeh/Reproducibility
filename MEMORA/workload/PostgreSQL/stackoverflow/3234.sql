WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.Score) AS AvgScore
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.OwnerUserId
),
CloseReasonCounts AS (
    SELECT 
        ph.UserId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVoteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenVoteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
)
SELECT 
    us.DisplayName AS UserName,
    ps.TotalPosts,
    ps.TotalScore,
    ps.AvgScore,
    COALESCE(cr.CloseVoteCount, 0) AS CloseVotes,
    COALESCE(cr.ReopenVoteCount, 0) AS ReopenVotes,
    CASE 
        WHEN ps.AvgScore > 50 THEN 'High Performer'
        WHEN ps.AvgScore BETWEEN 20 AND 50 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS PerformerStatus
FROM 
    PostStatistics ps
JOIN 
    Users us ON ps.OwnerUserId = us.Id
LEFT JOIN 
    CloseReasonCounts cr ON cr.UserId = us.Id
WHERE 
    ps.TotalPosts > 10
ORDER BY 
    ps.TotalScore DESC
LIMIT 100;