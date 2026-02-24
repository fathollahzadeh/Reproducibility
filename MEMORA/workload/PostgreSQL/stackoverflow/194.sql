WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges,
        SUM(COALESCE(U.UpVotes, 0) - COALESCE(U.DownVotes, 0)) AS NetVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC, P.ViewCount DESC) AS PopularRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND P.Score > 0
),
UsersWithPopularPosts AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        P.PostId,
        P.Title,
        P.Score
    FROM 
        UserBadgeCounts U
    JOIN 
        PopularPosts P ON U.UserId = P.OwnerUserId
    WHERE 
        P.PopularRank <= 3
)
SELECT 
    U.DisplayName,
    COALESCE(P.Title, 'No Popular Posts') AS PopularPostTitle,
    COALESCE(P.Score, 0) AS PostScore,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    U.NetVotes
FROM 
    UserBadgeCounts U
LEFT JOIN 
    UsersWithPopularPosts P ON U.UserId = P.UserId
ORDER BY 
    U.NetVotes DESC, U.GoldBadges DESC, U.SilverBadges DESC, U.BronzeBadges DESC
LIMIT 10;
