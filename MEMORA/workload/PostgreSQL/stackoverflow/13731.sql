
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    WHERE 
        U.Reputation > 100 
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate
)
SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    U.CreationDate AS UserCreationDate,
    UVote.UpVotes,
    UVote.DownVotes,
    PStats.PostId,
    PStats.Title,
    PStats.CreationDate AS PostCreationDate,
    PStats.CommentCount,
    PStats.VoteCount,
    PStats.UpVoteCount,
    PStats.DownVoteCount
FROM 
    UserVoteStats UVote
JOIN 
    Users U ON UVote.UserId = U.Id
JOIN 
    PostStats PStats ON U.Id = PStats.PostId 
ORDER BY 
    U.Reputation DESC, 
    PStats.VoteCount DESC;
