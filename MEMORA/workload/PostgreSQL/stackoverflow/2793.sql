WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT P.Id) AS PostsCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.AnswerCount,
        P.ViewCount,
        COALESCE(AVG(CASE WHEN C.Score IS NOT NULL THEN C.Score ELSE 0 END), 0) AS AvgCommentScore
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.AnswerCount, P.ViewCount
),
TopQuestions AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.AnswerCount,
        PS.ViewCount,
        RANK() OVER (ORDER BY PS.Score DESC) AS RankScore
    FROM 
        PostStatistics PS
    WHERE 
        PS.AnswerCount > 0
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.UpVotesCount,
    U.DownVotesCount,
    U.PostsCount,
    TQ.Title AS TopQuestionTitle,
    TQ.Score AS TopQuestionScore,
    TQ.AnswerCount AS TopQuestionAnswers,
    TQ.ViewCount AS TopQuestionViews
FROM 
    UserVoteStats U
LEFT JOIN 
    TopQuestions TQ ON U.PostsCount > 0 AND TQ.RankScore <= 5
WHERE 
    U.UpVotesCount IS NOT NULL
ORDER BY 
    U.UpVotesCount DESC, U.DisplayName;
