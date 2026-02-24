
WITH RECURSIVE UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COALESCE(SUM(VB.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        (SELECT 
             U.Id AS UserId,
             SUM(V.BountyAmount) AS BountyAmount 
         FROM 
             Votes V 
         JOIN 
             Users U ON V.UserId = U.Id 
         WHERE 
             V.VoteTypeId = 8 
         GROUP BY 
             U.Id) AS VB ON U.Id = VB.UserId
    GROUP BY 
        U.Id, U.DisplayName
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        CommentCount,
        VoteCount,
        TotalBounty,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalBounty DESC) AS Rank
    FROM 
        UserEngagement
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.CommentCount,
    U.VoteCount,
    U.TotalBounty,
    CASE 
        WHEN U.TotalBounty > 100 THEN 'Gold' 
        WHEN U.TotalBounty BETWEEN 50 AND 100 THEN 'Silver' 
        ELSE 'Bronze' 
    END AS EngagementBadge,
    (SELECT MIN(P.Score) 
     FROM Posts P 
     WHERE P.OwnerUserId = U.UserId 
     AND P.Score IS NOT NULL) AS MinPostScore
FROM 
    TopUsers U
WHERE 
    U.Rank <= 10
ORDER BY 
    U.Rank;
