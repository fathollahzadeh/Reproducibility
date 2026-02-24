WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        COALESCE(AboutMe, 'No description provided') AS UserAbout,
        Views,
        UpVotes,
        DownVotes
    FROM 
        Users
    WHERE 
        Reputation > 1000
),
PostSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        MIN(P.CreationDate) AS FirstPostDate,
        MAX(P.LastActivityDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPostAnalytics AS (
    SELECT 
        U.UserId,
        U.Reputation,
        P.TotalPosts,
        P.TotalQuestions,
        P.TotalAnswers,
        P.FirstPostDate,
        P.LastPostDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        UserReputation U
    LEFT JOIN 
        PostSummary P ON U.UserId = P.OwnerUserId
),
ClosedPostAnalytics AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS TotalCloseVotes,
        COUNT(DISTINCT PH.PostId) AS ClosedPosts
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.UserId
)
SELECT 
    UPA.UserId,
    UPA.Reputation,
    UPA.TotalPosts,
    UPA.TotalQuestions,
    UPA.TotalAnswers,
    UPA.FirstPostDate,
    UPA.LastPostDate,
    COALESCE(CPA.TotalCloseVotes, 0) AS TotalCloseVotes,
    COALESCE(CPA.ClosedPosts, 0) AS ClosedPosts,
    CASE 
        WHEN UPA.ReputationRank <= 10 THEN 'Top User'
        WHEN UPA.Reputation >= 5000 THEN 'Expert'
        ELSE 'Novice'
    END AS UserCategory
FROM 
    UserPostAnalytics UPA
LEFT JOIN 
    ClosedPostAnalytics CPA ON UPA.UserId = CPA.UserId
WHERE 
    UPA.TotalPosts IS NOT NULL
ORDER BY 
    UPA.Reputation DESC;
