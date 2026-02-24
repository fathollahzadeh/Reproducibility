WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.PostTypeId, U.DisplayName
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS CloseDate,
        H.Name AS HistoryType,
        U.DisplayName AS UserDisplayName
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes H ON PH.PostHistoryTypeId = H.Id
    JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        H.Name IN ('Post Closed', 'Post Reopened')
),
UserStats AS (
    SELECT 
        U.Id,
        U.Reputation,
        U.DisplayName,
        COALESCE(AVG(P.ViewCount), 0) AS AvgViews,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation, U.DisplayName
),
FinalResult AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.UpVoteCount,
        RP.DownVoteCount,
        C.CloseDate,
        C.HistoryType,
        U.DisplayName AS UserWithStats,
        U.Reputation AS UserReputation,
        U.AvgViews,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges
    FROM 
        RankedPosts RP
    LEFT JOIN 
        ClosedPostHistory C ON RP.PostId = C.PostId
    LEFT JOIN 
        UserStats U ON RP.OwnerDisplayName = U.DisplayName
    WHERE 
        RP.Rank <= 5
)
SELECT 
    *
FROM 
    FinalResult
WHERE 
    (CloseDate IS NULL OR CloseDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
ORDER BY 
    UpVoteCount DESC, DownVoteCount ASC NULLS LAST;