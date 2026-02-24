WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 0  
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        PostCount, 
        CommentCount, 
        TotalBounties, 
        Upvotes - Downvotes AS NetVotes, 
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM 
        UserActivity
)
SELECT 
    U.UserId, 
    U.DisplayName, 
    U.PostCount,
    U.CommentCount,
    U.TotalBounties,
    U.NetVotes,
    P.Title AS MostActivePostTitle,
    P.CreationDate AS MostActivePostDate
FROM 
    TopUsers U
LEFT JOIN 
    Posts P ON U.UserId = P.OwnerUserId
WHERE 
    U.PostRank <= 10
ORDER BY 
    U.PostCount DESC, 
    U.NetVotes DESC;