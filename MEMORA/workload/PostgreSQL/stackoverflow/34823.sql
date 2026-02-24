WITH RECURSIVE UserPostScores AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        RANK() OVER (ORDER BY SUM(COALESCE(P.Score, 0)) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
CommentStatistics AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        AVG(C.Score) AS AvgCommentScore
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
UserBadgeCount AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.DisplayName,
    UPS.PostCount,
    UPS.TotalScore,
    UPS.UserRank,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    CS.CommentCount,
    CS.AvgCommentScore,
    COALESCE(UBC.BadgeCount, 0) AS BadgeCount
FROM 
    Users U
LEFT JOIN 
    UserPostScores UPS ON U.Id = UPS.UserId
LEFT JOIN 
    RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.RecentRank = 1
LEFT JOIN 
    CommentStatistics CS ON RP.PostId = CS.PostId
LEFT JOIN 
    UserBadgeCount UBC ON U.Id = UBC.UserId
WHERE 
    UPS.TotalScore > 0
ORDER BY 
    UPS.TotalScore DESC,
    UPS.PostCount DESC;