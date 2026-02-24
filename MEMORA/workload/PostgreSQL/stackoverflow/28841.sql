WITH TagCounts AS (
    SELECT 
        TRIM(REGEXP_REPLACE(tag, '[<>]', '', 'g')) AS TagName, 
        COUNT(*) AS Count
    FROM (
        SELECT UNNEST(string_to_array(substring(Tags, 2, LENGTH(Tags) - 2), '><')) AS tag
        FROM Posts
        WHERE PostTypeId = 1
    ) AS TagsList
    GROUP BY TagName
), UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
), BadgeSummary AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    UA.UserId, 
    UA.DisplayName,
    UA.PostCount, 
    UA.AnswerCount,
    UA.QuestionCount,
    BS.GoldBadges,
    BS.SilverBadges,
    BS.BronzeBadges,
    TC.TagName,
    TC.Count AS TagUsageCount
FROM UserActivity UA
JOIN BadgeSummary BS ON UA.UserId = BS.UserId
JOIN TagCounts TC ON UA.UserId IN (SELECT OwnerUserId FROM Posts WHERE Tags LIKE '%' || TC.TagName || '%')
ORDER BY UA.PostCount DESC, TagUsageCount DESC
LIMIT 10;
