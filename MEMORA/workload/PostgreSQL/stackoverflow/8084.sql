
WITH UserBadges AS (
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
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(P.PostCount, 0) AS PostCount,
        COALESCE(C.CommentCount, 0) AS CommentCount
    FROM 
        Users U
    LEFT JOIN (
        SELECT 
            OwnerUserId AS UserId,
            COUNT(*) AS PostCount
        FROM 
            Posts
        WHERE 
            CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        GROUP BY 
            OwnerUserId
    ) P ON U.Id = P.UserId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        WHERE 
            CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        GROUP BY 
            UserId
    ) C ON U.Id = C.UserId
),
UserActivity AS (
    SELECT 
        B.UserId,
        B.DisplayName,
        B.BadgeCount,
        B.GoldBadges,
        B.SilverBadges,
        B.BronzeBadges,
        A.PostCount,
        A.CommentCount
    FROM 
        UserBadges B
    JOIN 
        ActiveUsers A ON B.UserId = A.UserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    CommentCount
FROM 
    UserActivity
WHERE 
    PostCount > 5 OR BadgeCount > 0
ORDER BY 
    BadgeCount DESC, PostCount DESC, CommentCount DESC
LIMIT 20;
