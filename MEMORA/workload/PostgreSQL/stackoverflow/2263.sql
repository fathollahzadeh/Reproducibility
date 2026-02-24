
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.Score) AS AvgScore,
        SUM(b.Class) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days'
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.PositivePosts,
    us.NegativePosts,
    us.AvgScore,
    us.BadgeCount,
    rp.PostId AS RecentPostId,
    rp.CreationDate AS RecentPostDate,
    pv.Upvotes,
    pv.Downvotes
FROM 
    UserStatistics us
LEFT JOIN 
    RecentPosts rp ON us.UserId = rp.OwnerUserId AND rp.RecentRank = 1
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
WHERE 
    (us.PostCount > 5 OR us.BadgeCount > 2)
    AND us.AvgScore IS NOT NULL
ORDER BY 
    us.DisplayName ASC;
