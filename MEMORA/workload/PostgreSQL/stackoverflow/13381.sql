
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.Reputation AS OwnerReputation,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, U.Reputation
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCreated,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(P.DownVotes, 0)) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        (SELECT 
            P.Id,
            P.OwnerUserId,
            PS.UpVotes,
            PS.DownVotes,
            P.ViewCount
         FROM 
            Posts P
         LEFT JOIN 
            (SELECT 
                PostId,
                COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
                COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
             FROM 
                Votes
             GROUP BY 
                PostId) PS ON P.Id = PS.PostId) P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.OwnerReputation,
    PS.UpVotes,
    PS.DownVotes,
    UA.UserId,
    UA.DisplayName AS OwnerDisplayName,
    UA.PostsCreated,
    UA.TotalViews,
    UA.TotalUpVotes,
    UA.TotalDownVotes
FROM 
    PostStatistics PS
LEFT JOIN 
    UserActivity UA ON PS.OwnerReputation = UA.UserId
ORDER BY 
    PS.CreationDate DESC;
