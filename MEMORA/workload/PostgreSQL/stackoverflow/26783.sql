
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
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
RecentPosts AS (
    SELECT 
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        P.OwnerUserId, P.Title, P.CreationDate
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UB.TotalBadges,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        COUNT(RP.Title) AS RecentPostCount,
        SUM(RP.CommentCount) AS TotalComments,
        SUM(RP.VoteCount) AS TotalVotes
    FROM 
        UserBadges UB
    LEFT JOIN 
        RecentPosts RP ON UB.UserId = RP.OwnerUserId
    LEFT JOIN 
        Users U ON UB.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, UB.TotalBadges, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalBadges,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    UA.RecentPostCount,
    UA.TotalComments,
    UA.TotalVotes
FROM 
    UserActivity UA
ORDER BY 
    UA.TotalBadges DESC, 
    UA.TotalComments DESC, 
    UA.RecentPostCount DESC
LIMIT 10;
