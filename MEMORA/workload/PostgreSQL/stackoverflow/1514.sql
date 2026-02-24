WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
), RecentPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        OwnerUserId,
        ViewCount,
        ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY CreationDate DESC) AS PostOrder
    FROM 
        Posts
    WHERE 
        CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), UserPostStats AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT rp.Id) AS RecentPostCount,
        COALESCE(ubs.BadgeCount, 0) AS BadgeCount,
        COALESCE(ubs.BadgeNames, 'None') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        RecentPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        UserBadges ubs ON u.Id = ubs.UserId
    GROUP BY 
        u.DisplayName, ubs.BadgeCount, ubs.BadgeNames
)
SELECT 
    uvs.UserId,
    uvs.DisplayName,
    uvs.UpVotes,
    uvs.DownVotes,
    ups.RecentPostCount,
    ups.BadgeCount,
    ups.BadgeNames,
    COALESCE(uvs.AvgViews, 0) AS AverageViews,
    CASE 
        WHEN uvs.TotalPosts = 0 THEN 'No Posts'
        ELSE 'Has Posts'
    END AS PostStatus
FROM 
    UserVoteStats uvs
JOIN 
    UserPostStats ups ON uvs.DisplayName = ups.DisplayName
ORDER BY 
    uvs.UpVotes DESC, ups.RecentPostCount DESC
LIMIT 100;