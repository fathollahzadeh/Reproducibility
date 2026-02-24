WITH UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserVoteCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        UserId
),
UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(UPC.PostCount, 0) AS TotalPosts,
    COALESCE(UVC.VoteCount, 0) AS TotalVotes,
    COALESCE(UBC.BadgeCount, 0) AS TotalBadges
FROM 
    Users U
LEFT JOIN 
    UserPostCounts UPC ON U.Id = UPC.OwnerUserId
LEFT JOIN 
    UserVoteCounts UVC ON U.Id = UVC.UserId
LEFT JOIN 
    UserBadgeCounts UBC ON U.Id = UBC.UserId
ORDER BY 
    U.Reputation DESC
LIMIT 
    100;