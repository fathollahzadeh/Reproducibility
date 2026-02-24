WITH PostCounts AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),

UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),

UserStats AS (
    SELECT 
        Id AS UserId,
        Reputation,
        COALESCE(BadgeCount, 0) AS BadgeCount
    FROM 
        Users
    LEFT JOIN 
        UserBadges ON Users.Id = UserBadges.UserId
)

SELECT 
    p.PostTypeId,
    pc.TotalPosts,
    us.UserId,
    us.Reputation,
    us.BadgeCount
FROM 
    PostCounts pc
JOIN 
    Posts p ON pc.PostTypeId = p.PostTypeId
JOIN 
    UserStats us ON p.OwnerUserId = us.UserId
ORDER BY 
    pc.TotalPosts DESC, us.Reputation DESC;