WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(V.VoteCount, 0) AS UserVoteCount,
        COALESCE(V.UpVotes, 0) AS UserUpVotes,
        COALESCE(V.DownVotes, 0) AS UserDownVotes,
        COALESCE(C.CommentsCount, 0) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        UserVoteCounts V ON P.OwnerUserId = V.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS CommentsCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.UserVoteCount,
    PS.UserUpVotes,
    PS.UserDownVotes,
    PS.CommentCount
FROM 
    PostStats PS
ORDER BY 
    PS.Score DESC, 
    PS.ViewCount DESC
LIMIT 100;