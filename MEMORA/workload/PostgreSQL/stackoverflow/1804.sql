WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
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
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        UpVotes,
        DownVotes,
        ReputationRank
    FROM 
        UserActivity
    WHERE 
        ReputationRank <= 10
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        MAX(P.CreationDate) AS LastPostDate,
        MIN(P.CreationDate) AS FirstPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        H.UserId,
        COUNT(H.PostId) AS TotalClosedPosts
    FROM 
        PostHistory H
    WHERE 
        H.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        H.UserId
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.TotalPosts,
    T.TotalQuestions,
    T.TotalAnswers,
    COALESCE(S.TotalPosts, 0) AS UserPostStatistics,
    COALESCE(S.TotalScore, 0) AS UserTotalScore,
    COALESCE(C.TotalClosedPosts, 0) AS UserTotalClosedPosts,
    CASE 
        WHEN C.TotalClosedPosts > 0 THEN 'Has Closed Posts' 
        ELSE 'No Closed Posts' 
    END AS ClosedPostStatus
FROM 
    TopUsers T
LEFT JOIN 
    PostStatistics S ON T.UserId = S.OwnerUserId
LEFT JOIN 
    ClosedPosts C ON T.UserId = C.UserId
ORDER BY 
    T.Reputation DESC;