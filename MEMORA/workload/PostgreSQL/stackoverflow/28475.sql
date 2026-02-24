
WITH UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        Users.Reputation,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        COUNT(DISTINCT Posts.Id) AS PostCount
    FROM 
        Users
    LEFT JOIN 
        Votes ON Users.Id = Votes.UserId
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    GROUP BY 
        Users.Id, Users.DisplayName, Users.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        Upvotes,
        Downvotes,
        (Upvotes - Downvotes) AS VoteBalance
    FROM 
        UserReputation
    WHERE 
        PostCount > 0
    ORDER BY 
        VoteBalance DESC
    LIMIT 10
),
PopularPosts AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.ViewCount,
        Posts.CreationDate,
        Users.DisplayName AS OwnerDisplayName,
        Posts.Score,
        (SELECT COUNT(*) FROM Comments WHERE Comments.PostId = Posts.Id) AS CommentCount
    FROM 
        Posts
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.PostTypeId = 1 
    ORDER BY 
        Posts.Score DESC, Posts.ViewCount DESC
    LIMIT 5
),
UserBadges AS (
    SELECT 
        Badges.UserId,
        COUNT(CASE WHEN Badges.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Badges.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Badges.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        Badges.UserId
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    u.VoteBalance,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
    p.Title AS PopularPostTitle,
    p.ViewCount AS PopularPostViewCount,
    p.CreationDate AS PopularPostCreationDate,
    p.OwnerDisplayName AS PopularPostOwner
FROM 
    TopUsers u
LEFT JOIN 
    UserBadges b ON u.UserId = b.UserId
LEFT JOIN 
    PopularPosts p ON u.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE PostTypeId = 1)
ORDER BY 
    u.Reputation DESC;
