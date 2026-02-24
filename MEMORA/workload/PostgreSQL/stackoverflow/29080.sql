WITH UserBadgeStats AS (
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
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        BadgeCount, 
        GoldBadges, 
        SilverBadges, 
        BronzeBadges,
        RANK() OVER (ORDER BY BadgeCount DESC) AS UserRank
    FROM 
        UserBadgeStats
    WHERE 
        BadgeCount > 0
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score
),
TopPosts AS (
    SELECT 
        PD.PostId, 
        PD.Title, 
        PD.CreationDate, 
        PD.Score, 
        PD.CommentCount,
        RANK() OVER (ORDER BY PD.Score DESC) AS PostRank
    FROM 
        PostDetails PD
    WHERE 
        PD.CommentCount > 0
)
SELECT 
    U.DisplayName AS TopUser,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    P.Title AS TopPost,
    P.Score,
    P.CommentCount
FROM 
    TopUsers U
JOIN 
    TopPosts P ON P.CommentCount > 5
WHERE 
    U.UserRank <= 10 AND P.PostRank <= 10
ORDER BY 
    U.BadgeCount DESC, P.Score DESC;