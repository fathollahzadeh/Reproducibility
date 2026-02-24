
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersGiven,
        COUNT(DISTINCT B.Id) AS BadgesEarned
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
QuestionStats AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.CreationDate,
        P.AnswerCount,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        CASE WHEN P.AnswerCount > 0 THEN (SELECT MAX(Score) FROM Posts WHERE ParentId = P.Id) ELSE NULL END AS HighestAnswerScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1
),
VoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    US.QuestionsAsked,
    US.AnswersGiven,
    US.BadgesEarned,
    QS.Title,
    QS.ViewCount,
    QS.CreationDate,
    QS.AnswerCount,
    QS.Score,
    QS.HighestAnswerScore,
    COALESCE(VS.Upvotes, 0) AS TotalUpvotes,
    COALESCE(VS.Downvotes, 0) AS TotalDownvotes,
    CASE 
        WHEN QS.CreationDate <= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' THEN 'Stale' 
        ELSE 'Fresh' 
    END AS QuestionAge,
    RANK() OVER (PARTITION BY U.Id ORDER BY U.Reputation DESC) AS ReputationRank
FROM 
    UserStats US
JOIN 
    QuestionStats QS ON QS.OwnerDisplayName = US.DisplayName
LEFT JOIN 
    VoteSummary VS ON QS.QuestionId = VS.PostId
JOIN 
    Users U ON US.UserId = U.Id
ORDER BY 
    U.Reputation DESC, QS.ViewCount DESC;
