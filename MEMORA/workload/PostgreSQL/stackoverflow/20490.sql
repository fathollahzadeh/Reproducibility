
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND P.ViewCount IS NOT NULL
), PostCloseHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        COALESCE(PH.Text::json ->> 'closeReasonId', 'Not Applicable') AS CloseReason
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
),
ModerationActions AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS ClosureCount,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS ClosureReasons
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        PH.PostId
), UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName
), FinalOutput AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        COALESCE(PCH.CloseReason, 'Open') AS PostCloseReason,
        MA.ClosureCount AS CloseCount,
        UA.UpVoteCount,
        UA.DownVoteCount,
        UA.CommentCount
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostCloseHistory PCH ON RP.PostId = PCH.PostId
    LEFT JOIN 
        ModerationActions MA ON RP.PostId = MA.PostId
    LEFT JOIN 
        UserActivity UA ON RP.PostId = UA.UserId 
    WHERE 
        RP.Rank <= 10  
)
SELECT 
    *,
    CASE 
        WHEN Score IS NULL THEN 'Score is NULL'
        WHEN ViewCount IS NOT NULL AND UpVoteCount > DownVoteCount THEN 'Popular Post'
        ELSE 'Less Engaging' 
    END AS EngagementStatus
FROM 
    FinalOutput
ORDER BY 
    Score DESC, 
    ViewCount DESC;
