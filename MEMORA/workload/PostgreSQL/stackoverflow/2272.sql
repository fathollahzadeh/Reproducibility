WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        MAX(P.CreationDate) AS LastPostDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalBounties,
        LastPostDate,
        UserRank
    FROM 
        UserStats
    WHERE 
        UserRank <= 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(C.Count, 0) AS CommentCount,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 
                (SELECT COUNT(*) FROM Posts PA WHERE PA.ParentId = P.Id)
            ELSE 0 
        END AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS Count FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    PD.PostId,
    PD.Title,
    PD.Score,
    PD.ViewCount,
    PD.CommentCount,
    PD.AnswerCount,
    TU.TotalBounties,
    TU.LastPostDate
FROM 
    TopUsers TU
JOIN 
    PostDetails PD ON PD.OwnerDisplayName = TU.DisplayName
ORDER BY 
    TU.UserRank, PD.Score DESC;