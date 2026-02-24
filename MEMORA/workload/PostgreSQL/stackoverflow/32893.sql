WITH RECURSIVE PostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        PH.Level + 1
    FROM 
        Posts P
    JOIN 
        PostHierarchy PH ON P.ParentId = PH.PostId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS Badges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PopularPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        ROW_NUMBER() OVER (ORDER BY P.ViewCount DESC) AS RN
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
)
SELECT 
    PH.PostId,
    PH.Title AS QuestionTitle,
    U.DisplayName AS OwnerDisplayName,
    UB.BadgeCount,
    UB.Badges,
    PP.ViewCount AS Popularity,
    COALESCE(COUNT(C.Id), 0) AS CommentCount,
    SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
FROM 
    PostHierarchy PH
JOIN 
    Users U ON PH.PostId = U.Id
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    Posts P ON P.Id = PH.PostId
LEFT JOIN 
    Comments C ON C.PostId = PH.PostId
LEFT JOIN 
    Votes V ON V.PostId = PH.PostId AND V.VoteTypeId = 8  
JOIN 
    PopularPosts PP ON P.Id = PP.Id
WHERE 
    P.PostTypeId = 1  
GROUP BY 
    PH.PostId, PH.Title, U.DisplayName, UB.BadgeCount, UB.Badges, PP.ViewCount
ORDER BY 
    Popularity DESC, CommentCount DESC;