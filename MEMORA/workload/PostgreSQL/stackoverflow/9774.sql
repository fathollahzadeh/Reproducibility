
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersCount,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentsCount,
        COUNT(DISTINCT B.Id) AS BadgesCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END), 0) DESC) AS RankByQuestionScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionsCount,
        AnswersCount,
        CommentsCount,
        BadgesCount,
        UpVotes,
        DownVotes,
        RankByQuestionScore,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS OverallRank
    FROM UserActivity
)

SELECT 
    RU.DisplayName,
    RU.TotalPosts,
    RU.QuestionsCount,
    RU.AnswersCount,
    RU.CommentsCount,
    RU.BadgesCount,
    RU.UpVotes,
    RU.DownVotes,
    RU.RankByQuestionScore,
    RU.OverallRank
FROM RankedUsers RU
WHERE RU.OverallRank <= 10
ORDER BY RU.RankByQuestionScore DESC;
