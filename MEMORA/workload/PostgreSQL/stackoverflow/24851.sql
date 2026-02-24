WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        COUNT(V.VoteTypeId) AS TotalVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COALESCE(SUM(CASE WHEN C.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount,
        COALESCE(MAX(PH.CreationDate), NULL) AS LastHistoryDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.OwnerUserId
),
RankedPosts AS (
    SELECT 
        PS.*,
        ROW_NUMBER() OVER (PARTITION BY PS.OwnerUserId ORDER BY PS.CommentCount DESC) AS CommentRank,
        RANK() OVER (ORDER BY PS.RelatedPostCount DESC) AS RelatedRank
    FROM PostStats PS
),
BadgesByUser AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(B.Id) AS BadgeCount
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    UPS.UpvoteCount,
    UPS.DownvoteCount,
    RP.Title,
    RP.CommentCount,
    RP.RelatedPostCount,
    RP.CommentRank,
    RP.RelatedRank,
    COALESCE(BU.BadgeNames, 'No Badges') AS UserBadges,
    CASE 
        WHEN UPS.TotalVotes = 0 THEN 'No votes' 
        ELSE CASE 
            WHEN UPS.UpvoteCount > UPS.DownvoteCount THEN 'Net positive'
            WHEN UPS.UpvoteCount < UPS.DownvoteCount THEN 'Net negative'
            ELSE 'Neutral votes'
        END 
    END AS VoteSummary
FROM Users U
LEFT JOIN UserVoteStats UPS ON U.Id = UPS.UserId
LEFT JOIN RankedPosts RP ON U.Id = RP.OwnerUserId
LEFT JOIN BadgesByUser BU ON U.Id = BU.UserId
WHERE UPS.TotalVotes IS NOT NULL OR RP.CommentCount > 0
ORDER BY RP.CommentCount DESC, U.Id;