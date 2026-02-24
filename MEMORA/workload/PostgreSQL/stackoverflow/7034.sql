WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        U.Views, 
        U.UpVotes, 
        U.DownVotes, 
        COUNT(DISTINCT P.Id) AS PostCount, 
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END) AS QuestionAnswers,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.ViewCount) AS AvgViewsPerPost
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        UpVotes,
        DownVotes,
        PostCount,
        CommentCount,
        QuestionAnswers,
        AnswerCount,
        AvgViewsPerPost,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS RN
    FROM 
        UserStats
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.Views,
    T.UpVotes,
    T.DownVotes,
    T.PostCount,
    T.CommentCount,
    T.QuestionAnswers,
    T.AnswerCount,
    T.AvgViewsPerPost,
    COALESCE(B.BadgeCount, 0) AS BadgeCount
FROM 
    TopUsers T
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(Id) AS BadgeCount 
    FROM 
        Badges 
    GROUP BY 
        UserId
) B ON T.UserId = B.UserId
WHERE 
    T.RN <= 10
ORDER BY 
    T.Reputation DESC;
