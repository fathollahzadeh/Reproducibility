WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), UserPosts AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        UserActivity ua
    JOIN 
        Posts p ON ua.UserId = p.OwnerUserId
    GROUP BY 
        ua.UserId, ua.DisplayName, ua.Reputation
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.TotalPosts,
    up.AvgScore,
    up.TotalViews,
    up.LastPostDate,
    COALESCE(ua.PostCount, 0) AS UniquePosts,
    COALESCE(ua.CommentCount, 0) AS CommentsMade,
    COALESCE(ua.BadgeCount, 0) AS Badges,
    ua.UpVotes,
    ua.DownVotes
FROM 
    UserPosts up
LEFT JOIN 
    UserActivity ua ON up.UserId = ua.UserId
ORDER BY 
    up.Reputation DESC, 
    up.TotalPosts DESC 
LIMIT 100;
