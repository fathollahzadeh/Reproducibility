WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostRankings AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    WHERE P.Score IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseCount
    FROM PostHistory PH
    GROUP BY PH.PostId, PH.CreationDate
),
FinalOutput AS (
    SELECT 
        U.DisplayName,
        U.BadgeCount,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        P.Title,
        P.Score,
        P.CreationDate,
        COALESCE(CP.CloseCount, 0) AS TotalCloseCount,
        CASE 
            WHEN COALESCE(CP.CloseCount, 0) > 0 THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus,
        P.ScoreRank,
        P.RecentPostRank
    FROM UserBadges U
    JOIN PostRankings P ON U.UserId = P.PostId
    LEFT JOIN ClosedPosts CP ON P.PostId = CP.PostId
)
SELECT 
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    Title,
    Score,
    CreationDate,
    TotalCloseCount,
    PostStatus,
    CASE 
        WHEN ScoreRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    CASE 
        WHEN RecentPostRank <= 10 THEN 'Recent Top 10'
        ELSE 'Older Post'
    END AS RecencyCategory
FROM FinalOutput
WHERE (TotalCloseCount IS NULL OR TotalCloseCount < 2)
ORDER BY Score DESC, CreationDate DESC;
