WITH RecursiveUserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.LastAccessDate DESC) AS AccessRank
    FROM 
        Users AS U
),
LatestPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.Title,
        P.Score,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts AS P
),
PostVoteCount AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes AS V
    GROUP BY 
        V.PostId
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges AS B
    GROUP BY 
        B.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(LatestPosts.PostId, 0) AS LatestPostId,
    COALESCE(LatestPosts.Title, 'No Posts') AS LatestPostTitle,
    COALESCE(PostVoteCount.UpVotes, 0) AS TotalUpVotes,
    COALESCE(PostVoteCount.DownVotes, 0) AS TotalDownVotes,
    COALESCE(UserBadges.GoldBadges, 0) AS GoldBadgeCount,
    COALESCE(UserBadges.SilverBadges, 0) AS SilverBadgeCount,
    COALESCE(UserBadges.BronzeBadges, 0) AS BronzeBadgeCount
FROM 
    RecursiveUserStats AS U
LEFT JOIN 
    LatestPosts ON U.UserId = LatestPosts.OwnerUserId AND LatestPosts.PostRank = 1
LEFT JOIN 
    PostVoteCount ON LatestPosts.PostId = PostVoteCount.PostId
LEFT JOIN 
    UserBadges ON U.UserId = UserBadges.UserId
WHERE 
    U.Reputation > 100 
ORDER BY 
    U.Reputation DESC, 
    U.LastAccessDate DESC;