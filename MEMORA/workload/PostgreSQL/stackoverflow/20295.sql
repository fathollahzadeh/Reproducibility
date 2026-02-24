
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPosts
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.ViewCount,
        PS.Score,
        (PS.UpvoteCount - PS.DownvoteCount) AS NetScore,
        PS.RecentPosts,
        CASE 
            WHEN PS.Score > 50 THEN 'High Score' 
            WHEN PS.Score >= 20 THEN 'Medium Score' 
            ELSE 'Low Score' 
        END AS ScoreCategory
    FROM 
        PostStats PS
    WHERE 
        PS.RecentPosts <= 5
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(B.BadgeCount, 0) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) B ON U.Id = B.UserId
),
PostWithUserReputation AS (
    SELECT 
        FP.*,
        UR.DisplayName,
        UR.Reputation,
        UR.BadgeCount
    FROM 
        FilteredPosts FP
    LEFT JOIN 
        Users U ON FP.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE OwnerUserId = U.Id)
    JOIN 
        UserReputation UR ON U.Id = UR.UserId
)
SELECT 
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    P.NetScore,
    P.ScoreCategory,
    P.DisplayName,
    CASE 
        WHEN P.BadgeCount IS NULL THEN 'No Badges'
        ELSE CAST(P.BadgeCount AS TEXT) || ' Badges' 
    END AS BadgeSummary,
    CASE 
        WHEN P.NetScore IS NULL THEN 'Score Not Available'
        ELSE CAST(P.NetScore AS TEXT)
    END AS EffectiveNetScore
FROM 
    PostWithUserReputation P
WHERE 
    P.ScoreCategory = 'High Score'
    OR (P.ScoreCategory = 'Medium Score' AND P.ViewCount > 100)
ORDER BY 
    P.CreationDate DESC;
