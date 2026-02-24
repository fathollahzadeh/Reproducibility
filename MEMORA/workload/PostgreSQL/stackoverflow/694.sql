WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        P.AcceptedAnswerId,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        OwnerName,
        CommentCount,
        RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank
    FROM 
        PostDetails
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalUpVotes,
    US.TotalDownVotes,
    TP.Title,
    TP.ViewCount,
    TP.CreationDate,
    TP.CommentCount,
    CASE
        WHEN TP.ViewRank <= 10 THEN 'Top View'
        ELSE 'Regular View'
    END AS ViewCategory
FROM 
    UserStats US
LEFT JOIN 
    TopPosts TP ON US.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = TP.PostId)
WHERE 
    US.TotalPosts > 5
ORDER BY 
    US.Rank, TP.ViewCount DESC
LIMIT 50;