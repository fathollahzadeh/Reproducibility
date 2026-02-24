WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = Users.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments WHERE UserId = Users.Id) AS CommentCount
    FROM Users
),
PostStats AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Score, 
        P.ViewCount, 
        P.CreationDate,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate, P.OwnerUserId
),
VotesPerPost AS (
    SELECT 
        PostId, 
        COUNT(*) FILTER (WHERE VoteTypeId = 2) AS UpVotes, 
        COUNT(*) FILTER (WHERE VoteTypeId = 3) AS DownVotes
    FROM Votes
    GROUP BY PostId
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.CommentCount,
    PS.PostId, 
    PS.Title, 
    PS.Score, 
    PS.ViewCount, 
    PS.CreationDate, 
    V.UpVotes,
    V.DownVotes
FROM UserReputation U
JOIN PostStats PS ON U.UserId = PS.OwnerUserId
JOIN VotesPerPost V ON PS.PostId = V.PostId
ORDER BY U.Reputation DESC, PS.Score DESC;