
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS rn,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownvoteCount,
        COALESCE((P.Score * 1.0 / NULLIF(P.ViewCount, 0)) * 100, 0) AS ScorePerView
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate BETWEEN TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND TIMESTAMP '2024-10-01 12:34:56'
),
PostSummary AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.CreationDate,
        RP.Score,
        RP.UpvoteCount,
        RP.DownvoteCount,
        RP.ScorePerView,
        CASE 
            WHEN RP.UpvoteCount IS NULL OR RP.UpvoteCount = 0 THEN 'No Votes'
            WHEN RP.DownvoteCount > RP.UpvoteCount THEN 'More Downvotes'
            ELSE 'Popular'
        END AS Popularity
    FROM 
        RankedPosts RP
    WHERE 
        RP.rn = 1
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.ViewCount,
    PS.CreationDate,
    PS.Score,
    PS.UpvoteCount,
    PS.DownvoteCount,
    PS.ScorePerView,
    PS.Popularity,
    U.DisplayName AS Owner,
    COALESCE(B.Name, 'No Badge') AS UserBadge,
    PH.Comment AS PostHistoryComment
FROM 
    PostSummary PS
LEFT JOIN 
    Users U ON U.Id = (SELECT OwnerUserId FROM Posts P WHERE P.Id = PS.PostId LIMIT 1)
LEFT JOIN 
    Badges B ON U.Id = B.UserId AND B.Class = 1 
LEFT JOIN 
    PostHistory PH ON PH.PostId = PS.PostId AND PH.PostHistoryTypeId = 24 
WHERE 
    PS.ScorePerView > 0.5
ORDER BY 
    PS.Score DESC, PS.Popularity DESC;
