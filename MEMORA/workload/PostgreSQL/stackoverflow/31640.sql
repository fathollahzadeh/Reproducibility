
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.ParentId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 

    UNION ALL

    SELECT 
        P.Id, 
        P.Title, 
        P.ParentId, 
        PH.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        PostHierarchy PH ON P.ParentId = PH.PostId
),
PostScoreStats AS (
    SELECT 
        P.Id, 
        P.Score,
        COUNT(CASE WHEN C.Score > 0 THEN 1 END) AS PositiveComments,
        COUNT(CASE WHEN C.Score <= 0 THEN 1 END) AS NegativeComments,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Score, P.OwnerUserId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
FinalStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UPS.TotalPosts,
        UPS.TotalScore,
        UBad.GoldBadges,
        UBad.SilverBadges,
        UBad.BronzeBadges,
        COALESCE(PHS.PositiveComments, 0) AS PositiveComments,
        COALESCE(PHS.NegativeComments, 0) AS NegativeComments,
        COALESCE(PH.Level, 0) AS PostLevel
    FROM 
        Users U
    LEFT JOIN 
        UserPostStats UPS ON U.Id = UPS.UserId
    LEFT JOIN 
        UserBadges UBad ON U.Id = UBad.UserId
    LEFT JOIN 
        PostScoreStats PHS ON U.Id = PHS.OwnerUserId
    LEFT JOIN 
        PostHierarchy PH ON U.Id = PH.PostId
)
SELECT 
    FS.DisplayName,
    FS.TotalPosts,
    FS.TotalScore,
    FS.GoldBadges,
    FS.SilverBadges,
    FS.BronzeBadges,
    SUM(ABS(FS.PositiveComments - FS.NegativeComments)) AS CommentBalance,
    CASE 
        WHEN SUM(FS.TotalScore) > 100 THEN 'Active Contributor'
        WHEN AVG(FS.TotalScore) > 0 THEN 'Contributing'
        ELSE 'Needs Improvement'
    END AS ContributionStatus
FROM 
    FinalStats FS
GROUP BY 
    FS.DisplayName, FS.TotalPosts, FS.TotalScore, FS.GoldBadges, FS.SilverBadges, FS.BronzeBadges
ORDER BY 
    ContributionStatus DESC, FS.TotalScore DESC;
