WITH UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(B.Id) AS BadgeCount, 
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
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
        GoldCount, 
        SilverCount, 
        BronzeCount, 
        RANK() OVER (ORDER BY BadgeCount DESC) AS Rank
    FROM 
        UserBadges
    WHERE 
        BadgeCount > 0
),
PostAnalytics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(TU.BadgeCount, 0) AS BadgeCount,
    COALESCE(TU.GoldCount, 0) AS GoldCount,
    COALESCE(TU.SilverCount, 0) AS SilverCount,
    COALESCE(TU.BronzeCount, 0) AS BronzeCount,
    COALESCE(PA.PostCount, 0) AS PostCount,
    COALESCE(PA.UpvotedPosts, 0) AS UpvotedPosts,
    COALESCE(PA.DownvotedPosts, 0) AS DownvotedPosts
FROM 
    Users U
LEFT JOIN 
    TopUsers TU ON U.Id = TU.UserId
LEFT JOIN 
    PostAnalytics PA ON U.Id = PA.OwnerUserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    TU.Rank NULLS LAST, 
    U.DisplayName;
