
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
PostAverages AS (
    SELECT
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        AVG(AnswerCount) AS AvgAnswerCount,
        AVG(CommentCount) AS AvgCommentCount
    FROM Posts
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
)
SELECT 
    U.DisplayName,
    U.PostsCount,
    U.QuestionsCount,
    U.AnswersCount,
    U.UpVotes,
    U.DownVotes,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    P.AvgViewCount,
    P.AvgScore,
    P.AvgAnswerCount,
    P.AvgCommentCount
FROM UserStats U
CROSS JOIN PostAverages P
LEFT JOIN BadgeCounts B ON U.UserId = B.UserId
ORDER BY U.PostsCount DESC;
