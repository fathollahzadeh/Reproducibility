
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        RANK() OVER (ORDER BY COUNT(B.Id) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS Author,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswer,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostOrder
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName, P.AcceptedAnswerId, P.ViewCount
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseActions,
        STRING_AGG(DISTINCT CRT.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON PH.Comment::INTEGER = CRT.Id
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate AS CreatedDate,
        RP.Author,
        RP.CommentCount,
        RP.UpVotes,
        RP.DownVotes,
        C.CloseActions,
        C.CloseReasons,
        U.BadgeCount
    FROM 
        RecentPosts RP
    LEFT JOIN 
        ClosedPosts C ON RP.PostId = C.PostId
    LEFT JOIN 
        UserBadges U ON RP.Author = U.DisplayName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Author,
    PS.CommentCount,
    PS.UpVotes,
    PS.DownVotes,
    COALESCE(PS.CloseActions, 0) AS CloseSummary,
    COALESCE(PS.CloseReasons, 'No closes') AS CloseReasons,
    PS.BadgeCount,
    CASE 
        WHEN PS.BadgeCount IS NULL THEN 'No Badges'
        WHEN PS.BadgeCount > 0 THEN 'Has Badges'
        ELSE 'Unknown'
    END AS BadgeStatus
FROM 
    PostStatistics PS
WHERE 
    PS.UpVotes > 10 OR PS.DownVotes > 10
ORDER BY 
    PS.UpVotes DESC, PS.CommentCount DESC;
