WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS ViewRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id
),
ClosedAndEditedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS EditCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    R.Title,
    R.ViewCount,
    R.UpVotes,
    R.DownVotes,
    COALESCE(CAE.CloseCount, 0) AS CloseCount,
    COALESCE(CAE.EditCount, 0) AS EditCount
FROM 
    RankedPosts R
JOIN 
    Users U ON R.PostId = U.Id
LEFT JOIN 
    ClosedAndEditedPosts CAE ON R.PostId = CAE.PostId
WHERE 
    R.ViewRank <= 5
    AND R.UpVotes > R.DownVotes
    AND R.ViewCount IS NOT NULL
ORDER BY 
    R.ViewRank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;