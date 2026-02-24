
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) B ON P.OwnerUserId = B.UserId
    WHERE 
        P.CreationDate >= DATE('2024-10-01') - INTERVAL '30 days'
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalComments,
    UPS.QuestionsCount,
    UPS.AnswersCount,
    UPS.TotalViews,
    UPS.TotalScore,
    UPS.TotalBounty,
    PE.PostId,
    PE.Title,
    PE.CreationDate,
    PE.ViewCount,
    PE.Score,
    PE.CommentCount,
    PE.BadgeCount
FROM 
    UserPostStats UPS
LEFT JOIN 
    PostEngagement PE ON UPS.UserId = PE.OwnerUserId
ORDER BY 
    UPS.TotalScore DESC, UPS.TotalPosts DESC;
