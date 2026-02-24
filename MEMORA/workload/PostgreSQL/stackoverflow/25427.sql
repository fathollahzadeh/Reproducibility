
WITH UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPostCount,
        SUM(COALESCE(C.Score, 0)) AS CommentScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        ClosedPostCount,
        CommentScore,
        RANK() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM UserActivity
),
ActiveUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        ClosedPostCount,
        CommentScore
    FROM TopUsers
    WHERE Rank <= 10
),
UserBadges AS (
    SELECT
        UB.UserId,
        COUNT(UB.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges UB
    JOIN Users U ON UB.UserId = U.Id
    JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS TotalBadges 
        FROM Badges 
        GROUP BY UserId
    ) AS UBCount ON UB.UserId = UBCount.UserId
    JOIN Badges B ON UB.Id = B.Id
    GROUP BY UB.UserId
)
SELECT 
    AU.DisplayName,
    AU.Reputation,
    AU.PostCount,
    AU.QuestionCount,
    AU.AnswerCount,
    AU.ClosedPostCount,
    AU.CommentScore,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.BadgeNames, 'None') AS BadgeNames
FROM ActiveUsers AU
LEFT JOIN UserBadges UB ON AU.UserId = UB.UserId
ORDER BY AU.Reputation DESC, AU.PostCount DESC;
