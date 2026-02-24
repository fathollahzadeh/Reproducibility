WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CommentStats AS (
    SELECT 
        C.UserId,
        COUNT(*) AS TotalComments,
        SUM(C.Score) AS TotalCommentScore
    FROM 
        Comments C
    GROUP BY 
        C.UserId
),
CloseReasonCount AS (
    SELECT
        PH.UserId,
        COUNT(*) AS ClosePostCount
    FROM
        PostHistory PH
    WHERE
        PH.PostHistoryTypeId IN (10, 11)  
    GROUP BY
        PH.UserId
),
MergedStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(UB.HighestBadgeClass, 0) AS HighestBadgeClass,
        COALESCE(UB.BadgeNames, 'None') AS BadgeNames,
        COALESCE(CS.TotalComments, 0) AS TotalComments,
        COALESCE(CS.TotalCommentScore, 0) AS TotalCommentScore,
        COALESCE(CRC.ClosePostCount, 0) AS ClosePostCount
    FROM 
        Users U
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        CommentStats CS ON U.Id = CS.UserId
    LEFT JOIN 
        CloseReasonCount CRC ON U.Id = CRC.UserId
)
SELECT 
    M.UserId,
    M.DisplayName,
    M.Reputation,
    M.TotalScore,
    M.TotalPosts,
    M.TotalQuestions,
    M.TotalAnswers,
    M.TotalBadges,
    M.HighestBadgeClass,
    M.BadgeNames,
    M.TotalComments,
    M.TotalCommentScore,
    M.ClosePostCount,
    CASE 
        WHEN M.ClosePostCount > 5 THEN 'Active Closer'
        ELSE 'Non-Active Closer'
    END AS CloserStatus,
    CASE 
        WHEN M.Reputation > 1000 THEN 'High Rep'
        WHEN M.Reputation BETWEEN 500 AND 1000 THEN 'Mid Rep'
        ELSE 'Low Rep'
    END AS ReputationTier,
    ROW_NUMBER() OVER (ORDER BY M.Reputation DESC) AS ReputationRank,
    LEAD(M.TotalPosts) OVER (ORDER BY M.Reputation DESC) AS NextUserTotalPosts
FROM 
    MergedStats M
WHERE 
    M.TotalQuestions > 0
ORDER BY 
    M.Reputation DESC, M.ClosePostCount DESC;