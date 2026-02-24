WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        MAX(V.CreationDate) AS LastVoteDate
    FROM 
        Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, P.CreationDate
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.AnswerCount,
    US.UserId,
    US.DisplayName,
    US.PostCount,
    US.TotalUpVotes,
    US.TotalDownVotes,
    PS.LastVoteDate
FROM 
    PostStatistics PS
JOIN 
    UserStatistics US ON PS.PostId = US.PostCount 
ORDER BY 
    PS.ViewCount DESC
LIMIT 100;