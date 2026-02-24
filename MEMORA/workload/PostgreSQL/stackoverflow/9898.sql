WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostsCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserActivity AS (
    SELECT 
        UserId, 
        COUNT(*) AS CommentsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Comments c
    JOIN 
        Posts p ON c.PostId = p.Id
    GROUP BY 
        UserId
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.PostsCount,
        ur.PopularPostsCount,
        ur.BadgesCount,
        ua.CommentsCount,
        ua.AnswerCount,
        RANK() OVER (ORDER BY ur.Reputation DESC, ur.PostsCount DESC, ua.CommentsCount DESC) AS UserRank
    FROM 
        UserReputation ur
    JOIN 
        UserActivity ua ON ur.UserId = ua.UserId
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    PostsCount, 
    PopularPostsCount, 
    BadgesCount, 
    CommentsCount, 
    AnswerCount, 
    UserRank
FROM 
    TopUsers
WHERE 
    UserRank <= 10
ORDER BY 
    UserRank;
