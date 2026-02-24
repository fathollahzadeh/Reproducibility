
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.LastActivityDate, U.DisplayName, P.PostTypeId, P.Score
),

ClosedPostReasons AS (
    SELECT 
        Ph.PostId,
        STRING_AGG(CASE 
            WHEN Ph.PostHistoryTypeId = 10 THEN CR.Name 
            ELSE 'Other' 
        END, ', ') AS CloseReasons
    FROM 
        PostHistory Ph
    JOIN 
        CloseReasonTypes CR ON CAST(Ph.Comment AS INTEGER) = CR.Id  
    WHERE 
        Ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        Ph.PostId
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.LastActivityDate,
    RP.OwnerDisplayName,
    RP.UpVotes,
    RP.DownVotes,
    COALESCE(CPR.CloseReasons, 'Not Closed') AS CloseReason,
    CASE 
        WHEN RP.PostRank <= 10 THEN 'Top Post'
        WHEN RP.PostRank BETWEEN 11 AND 50 THEN 'Mid Tier Post'
        ELSE 'Low Tier Post' 
    END AS PostTier,
    CASE 
        WHEN RP.UpVotes IS NULL OR RP.UpVotes < 5 THEN 'Needs More Engagement'
        ELSE 'Well Received' 
    END AS EngagementStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPostReasons CPR ON RP.PostId = CPR.PostId
WHERE 
    RP.UpVotes - RP.DownVotes > 2  
ORDER BY 
    RP.LastActivityDate DESC;
