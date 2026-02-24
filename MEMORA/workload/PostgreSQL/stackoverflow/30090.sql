WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8  
    GROUP BY 
        U.Id, U.DisplayName
), UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B 
    GROUP BY 
        B.UserId
), PostTypeSummary AS (
    SELECT 
        P.OwnerUserId,
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        P.OwnerUserId, PT.Name
), PostsWithClosure AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        CASE 
            WHEN PH.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN PH.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Other'
        END AS ClosureType
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  
), RankedUserPosts AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.TotalQuestions,
        UPS.TotalAnswers,
        UPS.TotalBounty,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY UPS.TotalPosts DESC) AS Rank
    FROM 
        UserPostStats UPS
    LEFT JOIN 
        UserBadges UB ON UPS.UserId = UB.UserId
)
SELECT 
    R.UserId,
    R.DisplayName,
    R.TotalPosts,
    R.TotalQuestions,
    R.TotalAnswers,
    R.TotalBounty,
    R.GoldBadges,
    R.SilverBadges,
    R.BronzeBadges,
    COALESCE(PTS.PostType, 'No Posts') AS PostType,
    COALESCE(PTS.PostCount, 0) AS PostCount,
    PWC.CreationDate AS ClosureDate,
    PWC.Comment AS ClosureComment,
    PWC.ClosureType
FROM 
    RankedUserPosts R
LEFT JOIN 
    PostTypeSummary PTS ON R.UserId = PTS.OwnerUserId
LEFT JOIN 
    PostsWithClosure PWC ON R.UserId = PWC.UserId
WHERE 
    R.Rank <= 10  
ORDER BY 
    R.TotalPosts DESC, R.DisplayName;