
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalComments, 
        UpVotes, 
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS RN
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 0
)
SELECT 
    U.UserId, 
    U.DisplayName, 
    U.TotalPosts, 
    U.TotalComments, 
    U.UpVotes, 
    U.DownVotes,
    CASE 
        WHEN U.UpVotes + U.DownVotes > 0 THEN ROUND((U.UpVotes * 1.0 / (U.UpVotes + U.DownVotes)) * 100, 2)
        ELSE 0 
    END AS VotePercentage
FROM 
    TopUsers U
WHERE 
    RN <= 10
ORDER BY 
    U.TotalPosts DESC;
