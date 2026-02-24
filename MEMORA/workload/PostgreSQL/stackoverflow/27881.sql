WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.ViewCount
),
UserPostStats AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        rp.PostId,
        rp.Title,
        rp.CreationDate AS PostCreationDate,
        rp.ViewCount,
        rp.CommentCount,
        ub.BadgeCount,
        ub.LastBadgeDate
    FROM 
        UserBadges ub
    JOIN 
        RecentPosts rp ON ub.UserId = rp.OwnerUserId
)
SELECT 
    ups.DisplayName,
    ups.BadgeCount,
    ups.LastBadgeDate,
    COUNT(ups.PostId) AS TotalPosts,
    SUM(ups.ViewCount) AS TotalViews,
    SUM(ups.CommentCount) AS TotalComments,
    MAX(ups.PostCreationDate) AS MostRecentPost
FROM 
    UserPostStats ups
GROUP BY 
    ups.DisplayName, ups.BadgeCount, ups.LastBadgeDate
ORDER BY 
    TotalPosts DESC, TotalViews DESC
LIMIT 10;