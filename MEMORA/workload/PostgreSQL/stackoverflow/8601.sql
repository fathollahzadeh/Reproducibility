WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount,
        SUM(V.BountyAmount) AS TotalBountyAmount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.CreationDate >= '2020-01-01'
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostsCount,
        CommentsCount,
        TotalBountyAmount,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY PostsCount DESC) AS PostsRank,
        RANK() OVER (ORDER BY CommentsCount DESC) AS CommentsRank
    FROM 
        UserActivity
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostsCount,
    CommentsCount,
    TotalBountyAmount,
    TotalUpVotes,
    TotalDownVotes,
    CASE 
        WHEN ReputationRank <= 10 THEN 'Top Reputation'
        ELSE 'Normal'
    END AS ReputationCategory,
    CASE 
        WHEN PostsRank <= 5 THEN 'Top Posts'
        ELSE 'Normal'
    END AS PostsCategory,
    CASE 
        WHEN CommentsRank <= 5 THEN 'Top Comments'
        ELSE 'Normal'
    END AS CommentsCategory
FROM 
    TopUsers
WHERE 
    TotalUpVotes > TotalDownVotes
ORDER BY 
    Reputation DESC, PostsCount DESC, CommentsCount DESC;
