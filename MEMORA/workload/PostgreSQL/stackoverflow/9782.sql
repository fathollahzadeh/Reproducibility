
WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL AND V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.Id IS NOT NULL AND V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COUNT(CASE WHEN PH.Id IS NOT NULL AND PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureHistory
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    LEFT JOIN 
        PostHistory PH ON PH.PostId = P.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName
),
RankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        ClosureHistory,
        ROW_NUMBER() OVER (ORDER BY UpVoteCount DESC, CommentCount DESC, DownVoteCount ASC) AS Rank
    FROM 
        RecentPosts
)
SELECT 
    RP.*,
    COALESCE(PH_N.Users, 0) AS TotalHistoricalEdits,
    CASE 
        WHEN ClosureHistory > 0 THEN 'Closed'
        ELSE 'Open'
    END AS Status
FROM 
    RankedPosts RP
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS Users
    FROM 
        PostHistory
    GROUP BY 
        PostId
) PH_N ON RP.PostId = PH_N.PostId
WHERE 
    RP.Rank <= 10;
