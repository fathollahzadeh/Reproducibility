
WITH RECURSIVE UserReputation AS (
    SELECT U.Id, U.DisplayName, U.Reputation, 1 AS Level
    FROM Users U
    WHERE U.Reputation > 0

    UNION ALL

    SELECT U.Id, U.DisplayName, U.Reputation, UR.Level + 1
    FROM Users U
    INNER JOIN UserReputation UR ON U.Id = UR.Id
    WHERE U.Reputation > (UR.Reputation + 100) 
),
RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank,
        COUNT(Comments.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments ON P.Id = Comments.PostId
    GROUP BY P.Id, P.Title, P.Score, P.CreationDate, P.ViewCount
),
PopularTags AS (
    SELECT
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 10
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        MAX(CASE WHEN B.Class = 1 THEN B.Name END) AS GoldBadge,
        MAX(CASE WHEN B.Class = 2 THEN B.Name END) AS SilverBadge,
        MAX(CASE WHEN B.Class = 3 THEN B.Name END) AS BronzeBadge
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT
    UR.DisplayName,
    UR.Reputation,
    RP.Title AS PopularPostTitle,
    RP.Score AS PostScore,
    P.TagName AS PopularTag,
    UB.GoldBadge, UB.SilverBadge, UB.BronzeBadge
FROM UserReputation UR
JOIN RankedPosts RP ON UR.Reputation >= 500 AND RP.Rank <= 5
JOIN PopularTags P ON RP.ViewCount > 1000
LEFT JOIN UserBadges UB ON UR.Id = UB.UserId
WHERE UB.GoldBadge IS NOT NULL OR UB.SilverBadge IS NOT NULL OR UB.BronzeBadge IS NOT NULL
ORDER BY UR.Reputation DESC, RP.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
