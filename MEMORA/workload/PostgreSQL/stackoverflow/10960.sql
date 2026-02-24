WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AnswerCount
),
AggregateData AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        P.PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CommentCount,
        U.TotalVotes,
        U.UpVotes,
        U.DownVotes
    FROM 
        UserVoteStats U
    JOIN 
        PostStats P ON U.UserId = P.PostId
)
SELECT 
    A.UserId,
    A.DisplayName,
    A.PostId,
    A.Title,
    A.Score,
    A.ViewCount,
    A.CommentCount,
    A.TotalVotes,
    A.UpVotes,
    A.DownVotes
FROM 
    AggregateData A
ORDER BY 
    A.Score DESC, A.ViewCount DESC;