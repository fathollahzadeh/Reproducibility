
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COALESCE(U.DisplayName, 'Community User') AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE(PH.CloseReason, 'Not Closed') AS CloseReason
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, 
            STRING_AGG(CASE WHEN Comment IS NOT NULL THEN Comment ELSE '' END, ', ') AS CloseReason
        FROM 
            PostHistory PH
        WHERE 
            PH.PostHistoryTypeId IN (10, 11) 
        GROUP BY 
            PostId
    ) PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.OwnerUserId,
        PS.OwnerDisplayName,
        PS.Score,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        RANK() OVER (PARTITION BY PS.OwnerUserId ORDER BY PS.Score DESC) AS PostRank
    FROM 
        PostStats PS
)
SELECT 
    UPC.UserId,
    UPC.TotalVotes,
    UPC.UpVotes,
    UPC.DownVotes,
    RP.OwnerDisplayName,
    RP.PostId,
    RP.Score,
    RP.ViewCount,
    RP.AnswerCount,
    RP.CommentCount,
    CASE 
        WHEN RP.PostRank IS NOT NULL AND RP.PostRank <= 3 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    UserVoteCounts UPC
LEFT JOIN 
    RankedPosts RP ON UPC.UserId = RP.OwnerUserId
WHERE 
    UPC.TotalVotes > 0
ORDER BY 
    UPC.TotalVotes DESC, 
    RP.Score DESC
LIMIT 50;
