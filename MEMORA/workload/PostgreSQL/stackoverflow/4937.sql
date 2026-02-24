
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        SUM(CASE WHEN V.Id IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        TotalBounties,
        VoteCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserActivity
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT L.RelatedPostId) AS LinkCount
    FROM 
        RecentPosts RP
    LEFT JOIN 
        Comments C ON RP.PostId = C.PostId
    LEFT JOIN 
        PostLinks L ON RP.PostId = L.PostId
    GROUP BY 
        RP.PostId
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.TotalBounties,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    PS.CommentCount,
    PS.LinkCount
FROM 
    TopUsers TU
JOIN 
    RecentPosts RP ON TU.PostCount > 0
JOIN 
    PostStatistics PS ON RP.PostId = PS.PostId
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC, RP.ViewCount DESC;
