WITH VotesSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
RecentPostHistory AS (
    SELECT 
        PostId,
        MAX(CreationDate) AS LatestEdit,
        MAX(CASE WHEN PostHistoryTypeId IN (10, 11) THEN Comment END) AS LastCloseOpenReason 
    FROM 
        PostHistory
    WHERE 
        CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(U.DisplayName, 'Community User') AS OwnerDisplayName,
        PH.LastCloseOpenReason,
        PH.LatestEdit,
        COALESCE(VS.Upvotes, 0) - COALESCE(VS.Downvotes, 0) AS NetVotes
    FROM 
        Posts P
        LEFT JOIN Users U ON P.OwnerUserId = U.Id
        LEFT JOIN RecentPostHistory PH ON P.Id = PH.PostId
        LEFT JOIN VotesSummary VS ON P.Id = VS.PostId
    WHERE 
        (P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL)
        OR (P.PostTypeId IN (2, 4) AND P.ViewCount > 100)
        OR (P.PostTypeId IN (1, 3) AND P.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 MONTH')
),
RankedPosts AS (
    SELECT 
        PD.*,
        ROW_NUMBER() OVER (PARTITION BY CAST(PD.CreationDate AS DATE) ORDER BY PD.NetVotes DESC) AS DailyRank,
        RANK() OVER (ORDER BY PD.NetVotes DESC) AS OverallRank
    FROM 
        PostDetails PD
)
SELECT 
    *,
    CASE 
        WHEN DailyRank <= 5 THEN 'Top 5 of the Day'
        ELSE 'Not in Top 5'
    END AS DailyStatus,
    CASE 
        WHEN OverallRank <= 50 THEN 'Trending'
        ELSE 'Normal'
    END AS OverallStatus
FROM 
    RankedPosts
WHERE 
    LatestEdit IS NOT NULL 
ORDER BY 
    OverallRank, DailyRank;