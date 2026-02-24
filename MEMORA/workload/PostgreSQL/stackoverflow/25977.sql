
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),

TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CreationDate,
        P.OwnerUserId,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM Posts P
    WHERE P.PostTypeId = 1  
),

TagAnalysis AS (
    SELECT 
        unnest(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts P
    WHERE P.PostTypeId = 1
    GROUP BY TagName
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.BadgeCount,
    U.GoldBadgeCount,
    U.SilverBadgeCount,
    U.BronzeBadgeCount,
    TP.PostId,
    TP.Title AS TopPostTitle,
    TP.Score AS TopPostScore,
    TP.ViewCount AS TopPostViewCount,
    TP.AnswerCount AS TopPostAnswerCount,
    TP.CreationDate AS TopPostCreationDate,
    TA.TagName,
    TA.PostCount AS TagPopularity
FROM UserBadgeCounts U
JOIN TopPosts TP ON U.UserId = TP.OwnerUserId
JOIN TagAnalysis TA ON TA.PostCount > 5 
WHERE TP.Rank <= 10 
ORDER BY U.BadgeCount DESC, TP.Score DESC;
