
WITH UserReputation AS (
    SELECT 
        Users.Id AS UserId, 
        Users.Reputation, 
        COUNT(Badges.Id) AS BadgeCount,
        SUM(CASE WHEN Badges.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        MAX(Posts.CreationDate) AS LastPostDate
    FROM Users
    LEFT JOIN Badges ON Users.Id = Badges.UserId
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY Users.Id, Users.Reputation
),
ActiveUsers AS (
    SELECT 
        UserId,
        Reputation,
        BadgeCount,
        GoldBadges,
        LastPostDate,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserReputation
    WHERE BadgeCount > 0 OR Reputation > 100
),
RecentPosts AS (
    SELECT 
        Posts.Id AS PostId, 
        Posts.Title, 
        Posts.CreationDate, 
        Posts.OwnerUserId,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - Posts.CreationDate)) / 60 AS PostAge,
        COUNT(Comments.Id) AS CommentsCount
    FROM Posts
    LEFT JOIN Comments ON Posts.Id = Comments.PostId
    WHERE Posts.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY Posts.Id, Posts.Title, Posts.CreationDate, Posts.OwnerUserId
    HAVING COUNT(Comments.Id) > 5
)
SELECT 
    U.UserId,
    U.Reputation,
    U.BadgeCount,
    U.GoldBadges,
    RP.Title AS RecentPostTitle,
    RP.PostAge,
    RP.CommentsCount,
    CASE 
        WHEN U.LastPostDate < CURRENT_TIMESTAMP - INTERVAL '6 months' THEN 'Inactive' 
        ELSE 'Active' 
    END AS UserActivityStatus
FROM ActiveUsers U
LEFT JOIN RecentPosts RP ON U.UserId = RP.OwnerUserId
WHERE U.ReputationRank < 11
ORDER BY U.Reputation DESC, RP.PostAge ASC NULLS LAST;
