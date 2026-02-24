
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PT.Name AS PostType,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        P.OwnerUserId
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes 
        GROUP BY PostId) V ON P.Id = V.PostId
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.TotalScore,
    U.TotalComments,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.PostType,
    P.UpVotes,
    P.DownVotes
FROM 
    UserStats U
JOIN 
    PostDetails P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, 
    U.TotalScore DESC, 
    P.UpVotes DESC;
