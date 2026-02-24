WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        Id,
        OwnerUserId,
        Title,
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY CreationDate DESC) AS rn
    FROM 
        Posts
),
MostActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalViews,
        ua.UpVotes,
        ua.DownVotes,
        ua.GoldBadges,
        ua.SilverBadges,
        ua.BronzeBadges,
        rp.Title,
        rp.CreationDate
    FROM 
        UserActivity ua
    LEFT JOIN 
        RecentPosts rp ON ua.UserId = rp.OwnerUserId
    WHERE 
        rp.rn = 1 
)
SELECT 
    mau.UserId,
    mau.DisplayName,
    mau.TotalPosts,
    mau.TotalViews,
    mau.UpVotes,
    mau.DownVotes,
    CONCAT(
        'Gold: ', mau.GoldBadges, ', ',
        'Silver: ', mau.SilverBadges, ', ',
        'Bronze: ', mau.BronzeBadges
    ) AS BadgeSummary,
    mau.Title AS RecentPostTitle,
    mau.CreationDate AS RecentPostDate
FROM 
    MostActiveUsers mau
WHERE 
    mau.TotalPosts > 0
ORDER BY 
    mau.TotalViews DESC, 
    mau.UpVotes DESC
LIMIT 10;