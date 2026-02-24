
WITH PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COUNT(CM.Id) AS CommentCount,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT PostId, 
                SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes 
         GROUP BY PostId) V ON P.Id = V.PostId
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    WHERE 
        P.CreationDate >= '2023-01-01'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, V.UpVotes, V.DownVotes
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesEarned,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)

SELECT 
    A.PostId,
    A.Title,
    A.CreationDate,
    A.Score,
    A.ViewCount,
    A.AnswerCount,
    A.CommentCount,
    U.UserId,
    U.DisplayName,
    U.PostsCreated,
    U.BadgesEarned,
    U.TotalViews,
    V.TotalUpVotes,
    V.TotalDownVotes
FROM 
    PostActivity A
JOIN 
    UserEngagement U ON A.PostId = U.PostsCreated
JOIN 
    PostVoteStats V ON A.PostId = V.PostId
ORDER BY 
    A.CreationDate DESC;
