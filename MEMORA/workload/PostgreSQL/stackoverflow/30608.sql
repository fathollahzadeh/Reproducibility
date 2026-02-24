WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        0 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
    UNION ALL
    SELECT 
        U.Id,
        U.Reputation,
        U.CreationDate,
        UR.Level + 1
    FROM 
        Users U
    INNER JOIN 
        UserReputation UR ON U.Id = UR.UserId
    WHERE 
        U.Reputation > 1000 + UR.Level * 500
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        AVG(V.BountyAmount) AS AvgBounty
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.OwnerUserId
),
RecentActivity AS (
    SELECT 
        C.UserId,
        COUNT(C.Id) AS TotalComments,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Comments C
    GROUP BY 
        C.UserId
),
CombinedStatistics AS (
    SELECT 
        U.DisplayName AS UserName,
        COALESCE(UR.Reputation, 0) AS UserReputation,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(RA.TotalComments, 0) AS TotalComments,
        COALESCE(RA.LastCommentDate, '1900-01-01') AS LastCommentDate,
        CASE 
            WHEN RA.LastCommentDate IS NULL THEN 'No Comments Yet'
            WHEN RA.LastCommentDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Inactive'
            ELSE 'Active'
        END AS ActivityStatus
    FROM 
        Users U
    LEFT JOIN 
        UserReputation UR ON U.Id = UR.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        RecentActivity RA ON U.Id = RA.UserId
),
RankedUsers AS (
    SELECT 
        UserName, 
        UserReputation, 
        TotalPosts, 
        TotalAnswers, 
        TotalQuestions, 
        TotalComments,
        LastCommentDate,
        ActivityStatus,
        RANK() OVER (ORDER BY UserReputation DESC) AS ReputationRank
    FROM 
        CombinedStatistics
)
SELECT 
    UserName,
    UserReputation,
    TotalPosts,
    TotalAnswers,
    TotalQuestions,
    TotalComments,
    LastCommentDate,
    ActivityStatus,
    ReputationRank 
FROM 
    RankedUsers
WHERE 
    UserReputation > 1500 AND ActivityStatus = 'Active'
ORDER BY 
    ReputationRank;