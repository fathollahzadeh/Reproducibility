WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),

UserPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),

ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ub.BadgeCount,
        p.TotalPosts,
        p.Questions,
        p.Answers,
        p.LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        UserPostStats p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 50
),

UserActivity AS (
    SELECT 
        au.Id,
        au.DisplayName,
        au.Reputation,
        au.BadgeCount,
        au.TotalPosts,
        au.Questions,
        au.Answers,
        au.LastPostDate,
        DENSE_RANK() OVER (ORDER BY au.Reputation DESC) AS UserRank
    FROM 
        ActiveUsers au
),

PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS Edits,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPosts
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
)

SELECT 
    ua.Id AS UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.BadgeCount,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.LastPostDate,
    phs.EditCount,
    phs.Edits AS TotalEdits,
    phs.ClosedPosts,
    ua.UserRank
FROM 
    UserActivity ua
LEFT JOIN 
    PostHistoryStats phs ON ua.Id = phs.UserId
WHERE 
    ua.UserRank <= 10 
ORDER BY 
    ua.Reputation DESC, ua.LastPostDate DESC;