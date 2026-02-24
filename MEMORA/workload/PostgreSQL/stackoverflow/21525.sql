
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AcceptedAnswerId,
        CASE 
            WHEN P.ViewCount > 1000 THEN 'High'
            WHEN P.ViewCount BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ViewCategory
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= '2023-10-01 12:34:56'::timestamp - INTERVAL '1 YEAR' 
        AND P.ViewCount IS NOT NULL
),
PostStatistics AS (
    SELECT 
        FP.PostId,
        FP.Title,
        FP.ViewCategory,
        PS.Score,
        COALESCE(NULLIF(COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END), 0), 0) AS UpVotes,
        COALESCE(NULLIF(COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END), 0), 0) AS DownVotes,
        COALESCE(NULLIF(FP.AcceptedAnswerId, -1), 0) AS HasAcceptedAnswer
    FROM 
        FilteredPosts FP
    LEFT JOIN 
        Posts PS ON FP.PostId = PS.Id
    LEFT JOIN 
        Votes V ON PS.Id = V.PostId
    GROUP BY 
        FP.PostId, FP.Title, FP.ViewCategory, PS.Score, FP.AcceptedAnswerId
),
PostHistoryAnalyzed AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= '2024-04-01 12:34:56'::timestamp - INTERVAL '6 MONTH'
        AND PH.PostHistoryTypeId IN (10, 11, 12) 
    GROUP BY 
        PH.PostId, PH.UserId, PH.PostHistoryTypeId
),
AggregatedData AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.ViewCategory,
        PS.UpVotes,
        PS.DownVotes,
        PH.UserId AS HistoryUserId,
        SUM(PH.HistoryCount) AS PostHistoryChangeCount
    FROM 
        PostStatistics PS
    LEFT JOIN 
        PostHistoryAnalyzed PH ON PS.PostId = PH.PostId
    GROUP BY 
        PS.PostId, PS.Title, PS.ViewCategory, PS.UpVotes, PS.DownVotes, PH.UserId
)
SELECT 
    RU.DisplayName,
    AD.Title,
    AD.ViewCategory,
    AD.UpVotes,
    AD.DownVotes,
    AD.PostHistoryChangeCount,
    CASE 
        WHEN AD.UpVotes > AD.DownVotes THEN 'Positive'
        WHEN AD.UpVotes < AD.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    RankedUsers RU
JOIN 
    AggregatedData AD ON RU.UserId = AD.HistoryUserId
WHERE 
    RU.ReputationRank <= 100
ORDER BY 
    AD.UpVotes DESC, AD.DownVotes ASC, RU.DisplayName ASC;
