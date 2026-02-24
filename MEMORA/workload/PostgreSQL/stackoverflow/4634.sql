
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
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
        QuestionCount,
        AnswerCount
    FROM 
        UserStats
    WHERE 
        UserRank <= 50
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.PostTypeId,
        COALESCE((SELECT AVG(V.BountyAmount) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 8), 0) AS AvgBounty,
        COALESCE((SELECT COUNT(C.Id) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(V.Id) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(V.Id) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
PostRanking AS (
    SELECT 
        D.PostId,
        D.Title,
        D.CreationDate,
        D.PostTypeId,
        D.AvgBounty,
        D.CommentCount,
        D.UpVoteCount,
        D.DownVoteCount,
        RANK() OVER (ORDER BY D.UpVoteCount DESC) AS RankByUpVotes
    FROM 
        PostDetails D
)
SELECT 
    U.DisplayName,
    U.Reputation,
    P.Title,
    P.CreationDate,
    P.AvgBounty,
    P.CommentCount,
    P.UpVoteCount,
    P.DownVoteCount,
    CASE 
        WHEN P.UpVoteCount > P.DownVoteCount THEN 'Positive'
        WHEN P.UpVoteCount < P.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    TopUsers U
JOIN 
    PostRanking P ON U.UserId = P.PostId
WHERE 
    P.RankByUpVotes <= 10
ORDER BY 
    U.Reputation DESC, P.UpVoteCount DESC;
