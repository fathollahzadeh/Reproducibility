WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation, 
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON V.PostId = P.Id 
    GROUP BY 
        U.Id, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
),
ActiveQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND P.ClosedDate IS NULL
),
FinalResults AS (
    SELECT 
        U.ReputationRank,
        AQ.PostId,
        AQ.Title,
        AQ.CreationDate,
        AQ.AcceptedAnswerId,
        AQ.CommentCount,
        AQ.UpVoteCount,
        AQ.DownVoteCount,
        U.Reputation,
        CASE 
            WHEN AQ.UpVoteCount > AQ.DownVoteCount THEN 'Positive' 
            ELSE 'Negative' 
        END AS PostSentiment
    FROM 
        ActiveQuestions AQ
    JOIN 
        RankedUsers U ON U.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = AQ.PostId)
)

SELECT 
    FR.ReputationRank,
    FR.Title,
    FR.CreationDate,
    FR.Reputation,
    FR.CommentCount,
    FR.UpVoteCount,
    FR.DownVoteCount,
    FR.PostSentiment
FROM 
    FinalResults FR
WHERE 
    FR.Reputation > 1000
ORDER BY 
    FR.ReputationRank, FR.CreationDate DESC;
