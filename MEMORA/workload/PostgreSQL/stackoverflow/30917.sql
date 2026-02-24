WITH RecursiveTopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Location,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
    AND 
        U.Reputation > 0
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        COALESCE(PV.VoteCount, 0) AS VoteCount,
        COALESCE(C.LastCommentCount, 0) AS LastCommentCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId IN (2, 3) 
        GROUP BY 
            PostId
    ) PV ON P.Id = PV.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS LastCommentCount
        FROM 
            Comments
        WHERE 
            CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '60 days'
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        STRING_AGG(PHT.Name, ', ') AS HistoryTypes,
        COUNT(PH.Id) AS TotalHistoryEntries
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName AS TopUser,
    R.Reputation,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS PostCreationDate,
    RP.Score AS PostScore,
    RP.VoteCount AS TotalVotes,
    C.CommentCount AS TotalComments,
    PHS.HistoryTypes,
    PHS.TotalHistoryEntries
FROM 
    RecursiveTopUsers R
JOIN 
    Users U ON R.Id = U.Id
JOIN 
    RecentPosts RP ON RP.OwnerUserId = U.Id
LEFT JOIN 
    (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) C ON RP.PostId = C.PostId
LEFT JOIN 
    PostHistorySummary PHS ON RP.PostId = PHS.PostId
WHERE 
    R.Rank <= 10
ORDER BY 
    R.Reputation DESC, RP.CreationDate DESC;