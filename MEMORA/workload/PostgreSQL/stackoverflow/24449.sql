
WITH RecentVotes AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id
),

ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS int) = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10
)

SELECT 
    U.DisplayName,
    P.Title,
    P.ViewCount,
    R.VoteCount,
    R.UpVotes,
    R.DownVotes,
    COALESCE(Closed.CloseReason, 'Not Closed') AS CloseReason,
    ROUND(COALESCE(NULLIF(R.UpVotes, 0), 1.0) / NULLIF(R.VoteCount, 0) * 100, 0) AS UpVotePercentage,
    CASE 
        WHEN P.ViewCount > 1000 THEN 'Hot'
        WHEN P.ViewCount BETWEEN 100 AND 1000 THEN 'Moderate'
        ELSE 'Cold' 
    END AS Popularity,
    COUNT(DISTINCT B.Id) AS BadgeCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    RecentVotes R ON P.Id = R.PostId
LEFT JOIN 
    ClosedPosts Closed ON P.Id = Closed.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    P.CreationDate >= DATE '2023-01-01' AND 
    P.Score > 0
GROUP BY 
    U.DisplayName, P.Title, P.ViewCount, R.VoteCount, R.UpVotes, R.DownVotes, Closed.CloseReason
ORDER BY 
    UpVotePercentage DESC, P.ViewCount DESC
LIMIT 10;
