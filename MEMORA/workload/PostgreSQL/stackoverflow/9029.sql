
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopPostsByUser AS (
    SELECT 
        P.OwnerUserId,
        P.Title AS PostTitle,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  
),
UserVoteCounts AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(VoteCounts.VoteCount, 0) AS TotalVotes,
    COALESCE(BadgeCounts.BadgeCount, 0) AS TotalBadges,
    COALESCE(BadgeCounts.GoldBadges, 0) AS TotalGoldBadges,
    COALESCE(BadgeCounts.SilverBadges, 0) AS TotalSilverBadges,
    COALESCE(BadgeCounts.BronzeBadges, 0) AS TotalBronzeBadges,
    COALESCE(TopPosts.PostTitle, 'No Posts Found') AS TopPostTitle,
    COALESCE(TopPosts.Score, 0) AS TopPostScore
FROM 
    Users U
LEFT JOIN 
    UserBadgeCounts BadgeCounts ON U.Id = BadgeCounts.UserId
LEFT JOIN 
    TopPostsByUser TopPosts ON U.Id = TopPosts.OwnerUserId AND TopPosts.PostRank = 1
LEFT JOIN 
    UserVoteCounts VoteCounts ON U.Id = VoteCounts.UserId
ORDER BY 
    U.Reputation DESC, TotalBadges DESC;
