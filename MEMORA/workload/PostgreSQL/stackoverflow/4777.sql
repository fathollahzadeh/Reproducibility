
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.Score IS NOT NULL
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    us.TotalPosts,
    us.TotalBounties,
    us.AverageScore,
    COUNT(cp.PostId) AS ClosedPostCount,
    MAX(cp.FirstClosedDate) AS RecentClosedDate,
    COUNT(DISTINCT rp.PostId) AS RecentPostCount
FROM 
    Users u
LEFT JOIN 
    UserStatistics us ON u.Id = us.UserId
LEFT JOIN 
    ClosedPosts cp ON u.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.UserPostRank <= 5
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, u.DisplayName, us.TotalPosts, us.TotalBounties, us.AverageScore
HAVING 
    COUNT(DISTINCT cp.PostId) > 0 AND us.AverageScore IS NOT NULL
ORDER BY 
    us.TotalPosts DESC, us.TotalBounties DESC;
