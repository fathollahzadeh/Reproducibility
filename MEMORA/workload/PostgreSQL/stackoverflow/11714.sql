WITH UserPostCount AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    WHERE 
        CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        OwnerUserId
),
UserBadgeCount AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserVoteCount AS (
    SELECT 
        UserId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        UserId
)
SELECT 
    U.DisplayName,
    COALESCE(UPC.PostCount, 0) AS PostCount,
    COALESCE(UPC.TotalViews, 0) AS TotalViews,
    COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
    COALESCE(UVC.VoteCount, 0) AS VoteCount,
    U.Reputation,
    U.CreationDate
FROM 
    Users U
LEFT JOIN 
    UserPostCount UPC ON U.Id = UPC.OwnerUserId
LEFT JOIN 
    UserBadgeCount UBC ON U.Id = UBC.UserId
LEFT JOIN 
    UserVoteCount UVC ON U.Id = UVC.UserId
ORDER BY 
    U.Reputation DESC
LIMIT 100;