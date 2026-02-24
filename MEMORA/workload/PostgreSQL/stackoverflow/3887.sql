WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)

SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    ueng.TotalBounty AS UserTotalBounty,
    CASE 
        WHEN p.AnswerCount > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS PostStatus
FROM 
    RankedPosts p
LEFT JOIN 
    UserEngagement ueng ON p.PostId IN (
        SELECT DISTINCT PostId 
        FROM Comments c 
        WHERE c.UserId = ueng.UserId
    )
LEFT JOIN 
    ClosedPosts cp ON p.PostId = cp.PostId
WHERE 
    p.PostRank <= 5
ORDER BY 
    p.Score DESC, 
    p.CreationDate DESC;