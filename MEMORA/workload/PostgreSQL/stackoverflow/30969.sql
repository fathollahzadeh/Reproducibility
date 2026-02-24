WITH RECURSIVE UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u 
    JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, b.Name
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS RecentPosts,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.LastAccessDate >= cast('2024-10-01' as date) - INTERVAL '60 days'
    GROUP BY 
        u.Id, u.DisplayName
),
FinalReport AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        SUM(ua.RecentPosts) AS TotalRecentPosts,
        SUM(ua.GoldBadges) AS TotalGoldBadges,
        SUM(ua.SilverBadges) AS TotalSilverBadges,
        SUM(ua.BronzeBadges) AS TotalBronzeBadges,
        SUM(ps.TotalComments) AS TotalCommentsOnRecentPosts,
        SUM(ps.TotalUpvotes) AS TotalUpvotesOnRecentPosts,
        SUM(ps.TotalDownvotes) AS TotalDownvotesOnRecentPosts
    FROM 
        RecentActivity ua
    LEFT JOIN 
        PostStatistics ps ON ua.UserId = ps.OwnerUserId
    GROUP BY 
        ua.UserId, ua.DisplayName
)
SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.TotalRecentPosts,
    fr.TotalGoldBadges,
    fr.TotalSilverBadges,
    fr.TotalBronzeBadges,
    fr.TotalCommentsOnRecentPosts,
    fr.TotalUpvotesOnRecentPosts,
    fr.TotalDownvotesOnRecentPosts
FROM 
    FinalReport fr
LEFT JOIN 
    UserBadges ub ON fr.UserId = ub.UserId
WHERE 
    fr.TotalRecentPosts > 0
ORDER BY 
    fr.TotalUpvotesOnRecentPosts DESC, 
    fr.TotalRecentPosts DESC;