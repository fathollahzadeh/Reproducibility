WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  
    WHERE 
        U.Reputation > 100  
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        TotalBounty,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC, Reputation DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.CommentCount,
    T.TotalBounty,
    T.TotalScore,
    COALESCE(TH.TopUserCount, 0) AS TotalTopUsers,
    (SELECT COUNT(*) FROM Users WHERE Reputation < T.Reputation) AS LowerRankedUsers
FROM 
    TopUsers T
LEFT JOIN 
    (SELECT COUNT(*) AS TopUserCount 
     FROM TopUsers 
     WHERE Rank <= 10) TH ON 1=1
WHERE 
    T.Rank <= 10 
ORDER BY 
    T.TotalScore DESC;