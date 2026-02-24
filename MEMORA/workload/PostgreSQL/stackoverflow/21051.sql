
WITH PostVoteSummary AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT V.UserId) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(DISTINCT CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.UserId END) AS UniqueClosers
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
EnhancedPostData AS (
    SELECT 
        P.Id,
        P.Title,
        PS.UpVotes,
        PS.DownVotes,
        PS.TotalVotes,
        COALESCE(CP.CloseCount, 0) AS CloseCount,
        COALESCE(CP.UniqueClosers, 0) AS UniqueClosers,
        UB.BadgeCount,
        UB.BadgeNames
    FROM 
        Posts P
    JOIN 
        PostVoteSummary PS ON P.Id = PS.PostId
    LEFT JOIN 
        ClosedPosts CP ON P.Id = CP.PostId
    LEFT JOIN 
        UserBadges UB ON P.OwnerUserId = UB.UserId
)
SELECT 
    E.Id,
    E.Title,
    E.UpVotes,
    E.DownVotes,
    E.TotalVotes,
    E.CloseCount,
    E.UniqueClosers,
    E.BadgeCount,
    E.BadgeNames,
    CASE 
        WHEN E.BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    (E.UpVotes - E.DownVotes) AS NetVotes,
    CASE 
        WHEN E.CloseCount > 0 AND E.UniqueClosers > 0 THEN 
            'Closed by ' || E.UniqueClosers || ' unique users'
        ELSE 
            'Not Closed'
    END AS CloseStatus
FROM 
    EnhancedPostData E
WHERE 
    E.UpVotes > 0 OR E.CloseCount > 0
ORDER BY 
    NetVotes DESC,
    E.CloseCount DESC
LIMIT 100;
