WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpvoteCount,  
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownvoteCount 
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(P.ViewCount, 0) AS ViewCount,
        COALESCE(B.Class, 0) AS BadgeCount,
        COALESCE(PH.EditsCount, 0) AS EditsCount,
        COUNT(C.Id) AS CommentCount 
    FROM 
        Posts P
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId AND B.Date > P.CreationDate
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS EditsCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId IN (4, 5, 6) 
        GROUP BY 
            PostId
    ) PH ON P.Id = PH.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, B.Class, PH.EditsCount
),
FilteredPostStatistics AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.ViewCount,
        PS.BadgeCount,
        PS.EditsCount,
        PS.CommentCount,
        CASE 
            WHEN PS.Score > 10 THEN 'Hot'
            WHEN PS.Score BETWEEN 5 AND 10 THEN 'Warm'
            ELSE 'Cold'
        END AS PostHeat
    FROM 
        PostStatistics PS
    WHERE 
        PS.CommentCount > 0 
        AND PS.ViewCount > 0
        AND PS.BadgeCount < 3  
),
RankedPosts AS (
    SELECT 
        FPS.*,
        RANK() OVER (ORDER BY FPS.Score DESC) AS ScoreRank, 
        ROW_NUMBER() OVER (PARTITION BY FPS.PostHeat ORDER BY FPS.ViewCount DESC) AS HeatRank
    FROM 
        FilteredPostStatistics FPS 
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.EditsCount,
    RP.CommentCount,
    RP.PostHeat,
    UVC.UpvoteCount,
    UVC.DownvoteCount
FROM 
    RankedPosts RP
LEFT JOIN 
    UserVoteCounts UVC ON RP.PostId = UVC.UserId 
WHERE 
    RP.ScoreRank <= 10 
    AND (RP.PostHeat = 'Hot' OR RP.PostHeat = 'Warm')
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;