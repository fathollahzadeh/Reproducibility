
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        AVG(COALESCE(P.Score, 0)) AS AvgScore,
        MAX(P.CreationDate) AS LastActivity
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UR.TotalBounties,
    PS.Title,
    PS.CommentCount,
    PS.AnswerCount,
    PS.AvgScore,
    PS.LastActivity
FROM 
    UserReputation UR
JOIN 
    Users U ON U.Id = UR.UserId
JOIN 
    PostStats PS ON PS.PostId IN (
        SELECT 
            P.Id 
        FROM 
            Posts P 
        LEFT JOIN 
            Votes V ON P.Id = V.PostId 
        WHERE 
            V.UserId = U.Id
    )
WHERE 
    UR.ReputationRank <= 10
ORDER BY 
    UR.Reputation DESC
FETCH FIRST 5 ROWS ONLY;
