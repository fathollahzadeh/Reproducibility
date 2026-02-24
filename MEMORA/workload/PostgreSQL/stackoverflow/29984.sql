WITH RecursiveTagSplits AS (
    SELECT 
        Id AS PostId,
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag
    FROM Posts 
    WHERE Tags IS NOT NULL
), TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount
    FROM RecursiveTagSplits
    GROUP BY Tag
), UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
), BadgeDetails AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    COALESCE(B.GoldBadges, 0) AS GoldBadges,
    COALESCE(B.SilverBadges, 0) AS SilverBadges,
    COALESCE(B.BronzeBadges, 0) AS BronzeBadges,
    T.Tag,
    T.PostCount AS TagPostCount
FROM UserReputation U
LEFT JOIN BadgeDetails B ON U.UserId = B.UserId
JOIN TagCounts T ON U.PostCount > 0
ORDER BY U.Reputation DESC, TagPostCount DESC
LIMIT 10;