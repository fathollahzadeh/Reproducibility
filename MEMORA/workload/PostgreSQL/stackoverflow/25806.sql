
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
PostStats AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    GROUP BY
        P.OwnerUserId
),
UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AvgViewCount, 0) AS AvgViewCount,
        COALESCE(PS.CommentCount, 0) AS CommentCount
    FROM
        Users U
    LEFT JOIN
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.BadgeCount,
    U.PostCount,
    U.TotalScore,
    U.AvgViewCount,
    U.CommentCount,
    RANK() OVER (ORDER BY U.TotalScore DESC) AS ScoreRank,
    RANK() OVER (ORDER BY U.BadgeCount DESC) AS BadgeRank
FROM 
    UserStats U
WHERE 
    U.PostCount > 0
ORDER BY 
    U.TotalScore DESC, U.BadgeCount DESC
LIMIT 10;
