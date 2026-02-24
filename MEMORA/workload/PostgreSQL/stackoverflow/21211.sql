
WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
), UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
), RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.AnswerCount,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId > 0, FALSE) AS HasAcceptedAnswer
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
), PostHistoryAnalysis AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN PH.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN PH.PostHistoryTypeId = 12 THEN PH.CreationDate END) AS LastDeletedDate,
        COUNT(*) FILTER (WHERE PH.UserId IS NOT NULL) * 1.0 / NULLIF(COUNT(*), 0) AS VoteRatio
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
), UserPostDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        P.Title,
        P.CreationDate,
        COALESCE(PH.LastClosedDate, DATE '2099-12-31') AS LastClosedDate,
        COALESCE(PH.LastDeletedDate, DATE '2099-12-31') AS LastDeletedDate,
        PH.VoteRatio,
        COUNT(COALESCE(CM.Id, NULL)) AS CommentCount,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UB.BadgeNames, 'No Badges') AS BadgeNames
    FROM 
        Users U
    JOIN 
        RecentPosts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostHistoryAnalysis PH ON P.PostId = PH.PostId
    LEFT JOIN 
        Comments CM ON P.PostId = CM.PostId
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    GROUP BY 
        U.Id, U.DisplayName, P.Title, P.CreationDate, PH.LastClosedDate, PH.LastDeletedDate, PH.VoteRatio, UB.BadgeCount, UB.BadgeNames
), FinalReport AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Title,
        U.CreationDate,
        U.LastClosedDate,
        U.LastDeletedDate,
        U.VoteRatio,
        U.CommentCount,
        U.BadgeCount,
        U.BadgeNames,
        CASE 
            WHEN U.LastDeletedDate > U.LastClosedDate THEN 'Deleted Recently'
            WHEN U.LastClosedDate IS NOT NULL THEN 'Closed Recently'
            ELSE 'Active'
        END AS PostStatus,
        CASE 
            WHEN U.VoteRatio IS NULL OR U.VoteRatio < 0.5 THEN 'Needs Attention'
            ELSE 'Well Voted'
        END AS VoteStatus
    FROM 
        UserPostDetails U
    WHERE 
        U.CommentCount > 0
)

SELECT *
FROM FinalReport
ORDER BY UserId, CreationDate DESC;
