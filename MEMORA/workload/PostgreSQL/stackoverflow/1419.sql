WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(Vs.VoteCount, 0)) AS TotalVotes,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS QuestionScore,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END) AS AnswerScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) Vs ON P.Id = Vs.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, PostCount, TotalVotes, QuestionScore, AnswerScore,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM 
        UserActivity
)
SELECT 
    T.DisplayName,
    T.PostCount,
    T.TotalVotes,
    T.QuestionScore,
    T.AnswerScore,
    CASE 
        WHEN T.VoteRank < 11 THEN 'Top 10 by Votes'
        ELSE 'Not in Top 10 by Votes'
    END AS VoteCategory,
    CASE 
        WHEN T.PostRank < 11 THEN 'Top 10 by Posts'
        ELSE 'Not in Top 10 by Posts'
    END AS PostCategory,
    COALESCE((
        SELECT STRING_AGG(DISTINCT PS.Title, '; ') 
        FROM Posts PS 
        WHERE PS.OwnerUserId = T.UserId 
        AND PS.PostTypeId = 1
    ), 'No Questions') AS SampleQuestions
FROM 
    TopUsers T
WHERE 
    T.TotalVotes > 0
ORDER BY 
    T.TotalVotes DESC, T.PostCount DESC;
