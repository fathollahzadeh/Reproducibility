WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - interval '30 days'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        r.Name AS CloseReason,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes r ON ph.Comment::int = r.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId, ph.CreationDate, r.Name
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title,
    rp.CreationDate,
    tu.DisplayName AS TopUser,
    tu.TotalScore,
    cp.CloseReason,
    cp.CloseCount,
    us.TotalBounties,
    us.TotalViews
FROM 
    RecentPosts rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.Id
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
JOIN 
    UserStatistics us ON rp.OwnerUserId = us.UserId
WHERE 
    rp.Score > (SELECT AVG(Score) FROM Posts) 
ORDER BY 
    rp.CreationDate DESC 
FETCH FIRST 100 ROWS ONLY;