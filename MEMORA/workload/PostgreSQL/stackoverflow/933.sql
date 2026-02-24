WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS UpVotes
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PS.*,
        ROW_NUMBER() OVER (ORDER BY PS.Score DESC, PS.CommentCount DESC) AS Rank
    FROM 
        PostStatistics PS
)
SELECT 
    UM.DisplayName,
    UM.Reputation,
    UM.TotalPosts,
    UM.TotalComments,
    UM.TotalBounty,
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.CommentCount,
    TP.UpVotes,
    TP.CreationDate
FROM 
    UserMetrics UM
JOIN 
    TopPosts TP ON UM.UserId = (
        SELECT P.OwnerUserId 
        FROM Posts P 
        WHERE P.Id = TP.PostId 
        LIMIT 1
    )
WHERE 
    UM.TotalPosts > 5
    AND UM.ReputationRank <= 10
ORDER BY 
    UM.Reputation DESC, 
    TP.Score DESC;