
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(V.DownVotes, 0)) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes 
        GROUP BY 
            PostId) V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers,
        COUNT(DISTINCT PH.Id) AS TotalHistoryEntries
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    PS.TotalPosts,
    PS.TotalViews,
    PS.TotalAnswers,
    PS.TotalHistoryEntries,
    US.TotalUpVotes,
    US.TotalDownVotes
FROM 
    UserStats US
LEFT JOIN 
    PostStats PS ON US.UserId = PS.OwnerUserId
WHERE 
    US.Reputation > 1000
ORDER BY 
    US.Reputation DESC, US.PostCount DESC;
