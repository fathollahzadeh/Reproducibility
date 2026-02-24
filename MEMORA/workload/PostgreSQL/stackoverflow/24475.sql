
WITH PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        PT.Name AS PostType,
        P.CreationDate,
        P.Score,
        COALESCE(P.ViewCount, 0) AS ViewCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        (SELECT
            COUNT(*)
         FROM
            Comments C_sub
         WHERE
            C_sub.PostId = P.Id) AS TotalComments
    FROM
        Posts P
    LEFT JOIN
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    GROUP BY
        P.Id, P.Title, PT.Name, P.CreationDate, P.Score, P.ViewCount
),
PostHistorySummary AS (
    SELECT
        PH.PostId,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes,
        COUNT(*) AS EditCount
    FROM
        PostHistory PH
    JOIN
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE
        PH.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY
        PH.PostId
),
BadgedUsers AS (
    SELECT
        U.Id AS UserId,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        STRING_AGG(DISTINCT B.Name, ', ') AS BadgeNames
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id
),
FinalReport AS (
    SELECT
        PS.PostId,
        PS.Title,
        PS.PostType,
        PS.CreationDate,
        PS.Score,
        PS.ViewCount,
        PS.UpVotes,
        PS.DownVotes,
        PS.CommentCount,
        PS.TotalComments,
        PHS.HistoryTypes,
        PHS.EditCount,
        CASE 
            WHEN BU.BadgeCount > 0 THEN BU.BadgeNames 
            ELSE 'No Badges' 
        END AS UserBadges
    FROM
        PostStats PS
    LEFT JOIN
        PostHistorySummary PHS ON PS.PostId = PHS.PostId
    LEFT JOIN
        Users U ON PS.PostId = U.Id  
    LEFT JOIN
        BadgedUsers BU ON U.Id = BU.UserId
)
SELECT
    PostId,
    Title,
    PostType,
    CreationDate,
    Score,
    ViewCount,
    UpVotes,
    DownVotes,
    CommentCount,
    TotalComments,
    HistoryTypes,
    EditCount,
    UserBadges
FROM
    FinalReport
WHERE
    (Score > 0 OR CommentCount > 0)
    AND (UserBadges IS NOT NULL AND UserBadges <> 'No Badges')
ORDER BY
    Score DESC,
    CreationDate DESC;
