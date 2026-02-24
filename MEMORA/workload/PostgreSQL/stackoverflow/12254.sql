WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        U.Views,
        U.CreationDate,
        (U.UpVotes - U.DownVotes) AS VoteScore,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN B.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation, U.UpVotes, U.DownVotes, U.Views, U.CreationDate
)

SELECT 
    Us.UserId,
    Us.Reputation,
    Us.VoteScore,
    Us.PostCount,
    Us.CommentCount,
    Us.QuestionCount,
    Us.AnswerCount,
    Us.BadgeCount,
    RANK() OVER (ORDER BY Us.Reputation DESC) AS ReputationRank,
    RANK() OVER (ORDER BY Us.VoteScore DESC) AS VoteScoreRank,
    RANK() OVER (ORDER BY Us.PostCount DESC) AS PostCountRank
FROM 
    UserScores Us
ORDER BY 
    Us.Reputation DESC, Us.VoteScore DESC
LIMIT 100;