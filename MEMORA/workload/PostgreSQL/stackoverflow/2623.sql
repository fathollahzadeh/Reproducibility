
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 2
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate,
        PH.Comment
    FROM 
        Posts P
    INNER JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10
        AND PH.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
RecentQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        COUNT(A.Id) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId = 1
        AND P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    RQ.Title AS RecentQuestionTitle,
    RQ.AnswerCount AS RecentAnswerCount,
    CP.Comment AS CloseComment
FROM 
    UserVoteStats U
FULL OUTER JOIN 
    RecentQuestions RQ ON U.UserId = RQ.QuestionId
LEFT JOIN 
    ClosedPosts CP ON RQ.QuestionId = CP.PostId
WHERE 
    U.VoteRank <= 10
    OR RQ.AnswerCount > 0
ORDER BY 
    COALESCE(U.UpVotes, 0) DESC, 
    COALESCE(RQ.AnswerCount, 0) DESC;
