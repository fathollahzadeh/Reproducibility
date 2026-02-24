WITH TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users AS U
    JOIN Posts AS P ON U.Id = P.OwnerUserId
    WHERE P.PostTypeId = 1 
    GROUP BY U.Id, U.DisplayName, U.Reputation
    HAVING COUNT(DISTINCT P.Id) > 0
), 
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users AS U
    LEFT JOIN Badges AS B ON U.Id = B.UserId
    GROUP BY U.Id
),
TopQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        string_agg(T.TagName, ', ') AS Tags
    FROM Posts AS P
    JOIN Tags AS T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount
    ORDER BY P.Score DESC, P.CreationDate DESC
    LIMIT 10
)
SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    U.QuestionCount,
    B.BadgeCount,
    B.GoldBadges,
    B.SilverBadges,
    B.BronzeBadges,
    Q.PostId,
    Q.Title AS QuestionTitle,
    Q.CreationDate AS QuestionDate,
    Q.ViewCount,
    Q.Score AS QuestionScore,
    Q.AnswerCount,
    Q.Tags AS QuestionTags
FROM TopUsers AS U
JOIN UserBadges AS B ON U.UserId = B.UserId
JOIN TopQuestions AS Q ON U.QuestionCount > 0 
ORDER BY U.Reputation DESC, B.BadgeCount DESC
LIMIT 5;