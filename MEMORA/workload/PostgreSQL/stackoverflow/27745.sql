
WITH TagFrequency AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS Frequency
    FROM Posts
    WHERE PostTypeId = 1 
    GROUP BY Tag
), UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
), TopTags AS (
    SELECT 
        Tag,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS TagRank
    FROM TagFrequency
), TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY BadgeCount DESC) AS UserRank
    FROM UserBadges
)
SELECT 
    T.Tag, 
    T.Frequency, 
    U.DisplayName AS TopUser, 
    U.BadgeCount, 
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges
FROM TopTags T
JOIN TopUsers U ON U.UserRank = 1
WHERE T.TagRank <= 10 
ORDER BY T.Frequency DESC, U.BadgeCount DESC;
