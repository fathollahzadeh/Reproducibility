WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
HighScorers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        TotalBounties,
        RANK() OVER (ORDER BY PostCount DESC, TotalBounties DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    H.UserId, 
    H.DisplayName, 
    H.Reputation, 
    H.PostCount, 
    H.CommentCount, 
    H.TotalBounties 
FROM 
    HighScorers H
WHERE 
    H.Rank <= 10
ORDER BY 
    H.Rank;
