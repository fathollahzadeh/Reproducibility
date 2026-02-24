
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName, U.Reputation
), UnclosedQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.PostTypeId = 1 AND P.ClosedDate IS NULL
), TopVotedQuestions AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount
    FROM Votes V
    JOIN Posts P ON V.PostId = P.Id
    WHERE P.PostTypeId = 1
    GROUP BY P.Id
    ORDER BY VoteCount DESC
    LIMIT 10
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.QuestionCount,
    U.AnswerCount,
    U.UpVoteCount,
    U.DownVoteCount,
    UQ.Title AS UnclosedQuestionTitle,
    UQ.Score AS UnclosedQuestionScore,
    UQ.ViewCount AS UnclosedQuestionViewCount,
    TQV.VoteCount AS TopVotedQuestionVotes
FROM UserStats U
LEFT JOIN UnclosedQuestions UQ ON UQ.OwnerDisplayName = U.DisplayName
LEFT JOIN TopVotedQuestions TQV ON UQ.PostId = TQV.PostId
ORDER BY U.Reputation DESC, U.BadgeCount DESC;
