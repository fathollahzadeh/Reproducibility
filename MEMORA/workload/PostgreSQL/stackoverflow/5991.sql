WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),
PostAnalytics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        A.AnswerCount,
        C.CommentCount,
        PH.EditsCount
    FROM
        Posts P
    LEFT JOIN (
        SELECT
            ParentId,
            COUNT(*) AS AnswerCount
        FROM
            Posts
        WHERE
            PostTypeId = 2
        GROUP BY
            ParentId
    ) A ON P.Id = A.ParentId
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS CommentCount
        FROM
            Comments
        GROUP BY
            PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS EditsCount
        FROM
            PostHistory
        GROUP BY
            PostId
    ) PH ON P.Id = PH.PostId
)
SELECT
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    UR.PostCount,
    PA.PostId,
    PA.Title,
    PA.CreationDate,
    PA.ViewCount,
    PA.AnswerCount,
    PA.CommentCount,
    PA.EditsCount,
    RANK() OVER (ORDER BY UR.Reputation DESC) AS ReputationRank
FROM
    UserReputation UR
JOIN
    PostAnalytics PA ON UR.UserId = PA.PostId
WHERE
    UR.Reputation > 1000
ORDER BY
    UR.Reputation DESC, PA.ViewCount DESC;
