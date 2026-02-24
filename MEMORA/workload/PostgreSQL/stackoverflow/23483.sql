WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COALESCE(u.Reputation, 0) AS Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty 
    FROM
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        MAX(COALESCE(p.ViewCount, 0)) AS MaxViewCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes, 
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes  
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY p.Id, p.Title
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ClosureCount, 
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
UserPostStats AS (
    SELECT 
        ur.UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(pa.AvgScore) AS AvgPostScore,
        MAX(cp.ClosureCount) AS PostClosureCount
    FROM 
        Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    JOIN UserReputation ur ON u.Id = ur.UserId
    LEFT JOIN PostAnalytics pa ON p.Id = pa.PostId
    LEFT JOIN ClosedPostHistory cp ON p.Id = cp.PostId 
    GROUP BY ur.UserId
)
SELECT 
    ups.UserId,
    u.DisplayName,
    ur.Reputation,
    ur.BadgeCount,
    ups.TotalPosts,
    ups.TotalViews,
    ups.AvgPostScore,
    ups.PostClosureCount,
    CASE 
        WHEN ups.TotalPosts > (SELECT AVG(TotalPosts) FROM UserPostStats) 
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS PostPerformance,
    STRING_AGG(DISTINCT pt.Name, ', ') AS TopPostTypes
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
JOIN 
    UserReputation ur ON ups.UserId = ur.UserId
LEFT JOIN 
    Posts p ON p.OwnerUserId = ups.UserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    ups.UserId, u.DisplayName, ur.Reputation, ur.BadgeCount, ups.TotalPosts, ups.TotalViews, ups.AvgPostScore, ups.PostClosureCount
HAVING 
    ups.TotalPosts > 0
ORDER BY 
    ur.Reputation DESC, ups.TotalPosts DESC
LIMIT 10;