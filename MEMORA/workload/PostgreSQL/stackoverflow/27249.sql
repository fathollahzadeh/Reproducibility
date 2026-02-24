WITH UserActiveCounts AS (
    
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBountyAmount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        PT.Name AS PostType,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS TotalComments,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'  
),
TopUsers AS (
    
    SELECT 
        U.DisplayName,
        UC.PostCount,
        UC.CommentCount,
        UC.TotalBountyAmount,
        UC.UpvoteCount,
        UC.DownvoteCount,
        RANK() OVER (ORDER BY UC.PostCount DESC, UC.CommentCount DESC) AS Rank
    FROM 
        UserActiveCounts UC
    JOIN 
        Users U ON UC.UserId = U.Id
    WHERE 
        UC.PostCount > 0  
),
PostRankings AS (
    
    SELECT 
        PS.Title,
        PS.PostId,
        PS.ViewCount,
        PS.Score,
        PS.PostType,
        RANK() OVER (ORDER BY PS.Score DESC, PS.ViewCount DESC) AS Rank
    FROM 
        PostStatistics PS
)

SELECT 
    TU.DisplayName AS TopUser,
    TU.PostCount,
    TU.CommentCount,
    TU.TotalBountyAmount,
    TU.UpvoteCount,
    TU.DownvoteCount,
    PR.Title AS TopPost,
    PR.Score AS PostScore,
    PR.PostType,
    PR.ViewCount AS PostViewCount
FROM 
    TopUsers TU
JOIN 
    PostRankings PR ON TU.Rank = 1  
ORDER BY 
    TU.Rank;