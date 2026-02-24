
WITH RecursiveBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        B.Date,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(PH.Id) AS EditCount,
        COUNT(DISTINCT PH.UserId) AS UniqueEditors
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5) 
    GROUP BY 
        P.Id, P.Title
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(PH.EditCount), 0) AS TotalPostEdits,
        COALESCE(SUM(PH.UniqueEditors), 0) AS TotalUniqueEditors
    FROM 
        Users U
    LEFT JOIN 
        PostHistoryStats PH ON U.Id = (SELECT OwnerUserId FROM Posts WHERE Id = PH.PostId)
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalViews,
    U.TotalBounty,
    B.BadgeName,
    UEng.TotalPostEdits,
    UEng.TotalUniqueEditors
FROM 
    UserPostStats U
LEFT JOIN 
    RecursiveBadges B ON U.UserId = B.UserId AND B.BadgeRank = 1
LEFT JOIN 
    UserEngagement UEng ON U.UserId = UEng.UserId
WHERE 
    U.TotalPosts > 0
ORDER BY 
    U.TotalViews DESC, U.TotalPosts DESC;
