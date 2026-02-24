
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostID,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS RankScore,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
UserStatistics AS (
    SELECT 
        U.Id AS UserID,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(COALESCE(P.ViewCount, 0)) AS AverageViewCount 
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
FilteredPosts AS (
    SELECT 
        RP.*,
        US.PostCount AS UserPostCount,
        US.BadgeCount,
        CASE 
            WHEN US.Reputation > 1000 THEN 'High Reputation User'
            WHEN US.Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation User'
            ELSE 'Low Reputation User'
        END AS UserReputationCategory
    FROM 
        RankedPosts RP
    LEFT JOIN 
        UserStatistics US ON RP.OwnerUserId = US.UserID
    WHERE 
        RP.RankScore <= 5 
),
InactivityWarning AS (
    SELECT 
        OwnerUserId,
        MAX(LastActivityDate) AS LastActive,
        COUNT(*) AS InactivePosts
    FROM 
        Posts 
    WHERE 
        LastActivityDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '90 days'
    GROUP BY 
        OwnerUserId
)
SELECT 
    FP.Title,
    FP.CreationDate,
    FP.Score,
    FP.UpVoteCount,
    FP.DownVoteCount,
    FP.CommentCount,
    FP.UserReputationCategory,
    US.DisplayName,
    COALESCE(IW.InactivePosts, 0) AS InactivePostCount,
    CASE 
        WHEN IW.LastActive IS NOT NULL THEN 'Inactive User'
        ELSE 'Active User'
    END AS UserActivityStatus
FROM 
    FilteredPosts FP
LEFT JOIN 
    InactivityWarning IW ON FP.OwnerUserId = IW.OwnerUserId
JOIN 
    UserStatistics US ON FP.OwnerUserId = US.UserID
WHERE 
    FP.ViewCount > 50 
ORDER BY 
    FP.Score DESC, 
    FP.CreationDate DESC;
