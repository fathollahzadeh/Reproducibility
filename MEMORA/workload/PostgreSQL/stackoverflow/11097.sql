
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT A.Id) AS TotalAnswers,
        SUM(COALESCE(V.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(V.DownVotes, 0)) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id AND P.PostTypeId = 1  
    LEFT JOIN 
        (SELECT UserId, 
                SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
                SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes
         GROUP BY UserId) V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate
),
PostDetail AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        P.OwnerUserId
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  
)
SELECT 
    US.UserId,
    US.Reputation,
    US.CreationDate,
    US.TotalPosts,
    US.TotalAnswers,
    US.TotalUpVotes,
    US.TotalDownVotes,
    PD.PostId,
    PD.Title,
    PD.CreationDate AS PostCreationDate,
    PD.ViewCount,
    PD.Score,
    PD.OwnerDisplayName 
FROM 
    UserStats US
JOIN 
    PostDetail PD ON US.UserId = PD.OwnerUserId
ORDER BY 
    US.Reputation DESC, US.TotalPosts DESC;
