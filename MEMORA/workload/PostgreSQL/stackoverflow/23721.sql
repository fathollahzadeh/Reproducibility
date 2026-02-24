WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.PostTypeId,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate ASC) AS RankScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND P.Score IS NOT NULL
)
, HighScoringPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        RP.CreationDate,
        RP.RankScore
    FROM 
        RankedPosts RP
    WHERE 
        RP.RankScore <= 5
)
, UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS TotalComments,
        COALESCE((SELECT COUNT(A.Id) 
                  FROM Posts A 
                  WHERE A.OwnerUserId = U.Id 
                  AND A.PostTypeId = 1), 0) AS QuestionCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id
)
SELECT 
    HSP.PostId,
    HSP.Title,
    HSP.Score,
    U.UserId,
    U.DisplayName,
    U.TotalUpvotes,
    U.TotalDownvotes,
    U.TotalComments,
    U.QuestionCount
FROM 
    HighScoringPosts HSP
LEFT JOIN 
    UserActivity U ON U.UserId = HSP.PostId 
ORDER BY 
    HSP.Score DESC,
    U.TotalUpvotes - U.TotalDownvotes DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;