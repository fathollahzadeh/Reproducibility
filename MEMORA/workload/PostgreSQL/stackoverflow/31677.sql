WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS InstancesClosedReopened
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate, ph.UserId
)
SELECT 
    u.DisplayName,
    us.TotalPosts,
    us.PositivePosts,
    us.NegativePosts,
    us.TotalUpVotes,
    us.TotalDownVotes,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    ph.InstancesClosedReopened,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
FROM 
    UserStats us
JOIN 
    Users u ON us.UserId = u.Id
JOIN 
    RankedPosts r ON u.Id = r.OwnerUserId
LEFT JOIN 
    PostHistoryAnalysis ph ON r.PostId = ph.PostId
LEFT JOIN 
    Votes v ON r.PostId = v.PostId AND v.VoteTypeId IN (8, 9) 
WHERE 
    r.PostRank <= 5 
GROUP BY 
    u.DisplayName, us.TotalPosts, us.PositivePosts, us.NegativePosts, 
    us.TotalUpVotes, us.TotalDownVotes, r.PostId, r.Title, 
    r.CreationDate, r.Score, r.ViewCount, ph.InstancesClosedReopened
ORDER BY 
    TotalPosts DESC, SUM(v.BountyAmount) DESC;