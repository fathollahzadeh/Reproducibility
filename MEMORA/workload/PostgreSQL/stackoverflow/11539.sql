WITH UserPostCounts AS (
    SELECT 
        OwnerUserId, 
        COUNT(Id) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserVoteCounts AS (
    SELECT 
        UserId,
        COUNT(Id) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        UserId
),
UserComments AS (
    SELECT 
        UserId,
        COUNT(Id) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        UserId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UPC.PostCount, 0) AS PostCount,
    COALESCE(UPC.TotalViews, 0) AS TotalViews,
    COALESCE(UPC.TotalScore, 0) AS TotalScore,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UVC.VoteCount, 0) AS VoteCount,
    COALESCE(UC.CommentCount, 0) AS CommentCount
FROM 
    Users U
LEFT JOIN 
    UserPostCounts UPC ON U.Id = UPC.OwnerUserId
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    UserVoteCounts UVC ON U.Id = UVC.UserId
LEFT JOIN 
    UserComments UC ON U.Id = UC.UserId
ORDER BY 
    U.Reputation DESC;