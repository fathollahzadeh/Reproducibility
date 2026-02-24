
WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(T.Id) AS TagCount,
        STRING_AGG(T.TagName, ', ') AS TagsList
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),
UsersWithBadges AS (
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
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        CURRENT_TIMESTAMP - P.CreationDate AS DaysAgo,
        Y.UserId,
        Y.DisplayName,
        T.TagCount,
        T.TagsList
    FROM 
        Posts P
    JOIN 
        UsersWithBadges Y ON P.OwnerUserId = Y.UserId
    JOIN 
        PostTagCounts T ON P.Id = T.PostId
    WHERE 
        T.TagCount >= 3 
    ORDER BY 
        P.Score DESC, 
        P.ViewCount DESC
    LIMIT 10
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.DaysAgo,
    U.DisplayName,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    TP.TagsList
FROM 
    TopPosts TP
JOIN 
    UsersWithBadges U ON TP.UserId = U.UserId
ORDER BY 
    U.BadgeCount DESC, 
    TP.Score DESC;
