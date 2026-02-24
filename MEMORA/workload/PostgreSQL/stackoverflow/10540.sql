WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
PostHistoryMetrics AS (
    SELECT 
        PH.UserId,
        COUNT(DISTINCT PH.Id) AS EditCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionEdits,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerEdits
    FROM 
        PostHistory PH
    LEFT JOIN 
        Posts P ON PH.PostId = P.Id
    GROUP BY 
        PH.UserId
)
SELECT 
    U.UserId,
    U.Reputation,
    U.Views,
    U.UpVotes,
    U.DownVotes,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.CommentCount,
    COALESCE(PHM.EditCount, 0) AS EditCount,
    COALESCE(PHM.QuestionEdits, 0) AS QuestionEdits,
    COALESCE(PHM.AnswerEdits, 0) AS AnswerEdits
FROM 
    UserMetrics U
LEFT JOIN 
    PostHistoryMetrics PHM ON U.UserId = PHM.UserId
ORDER BY 
    U.Reputation DESC;