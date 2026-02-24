WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        CASE 
            WHEN U.Reputation IS NULL THEN 'No reputation'
            WHEN U.Reputation < 1000 THEN 'Novice'
            WHEN U.Reputation < 5000 THEN 'Experienced'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostMetaData AS (
    SELECT 
        RP.PostId,
        UR.ReputationLevel,
        COALESCE(PH2.Comment, 'No Close Reason') AS CloseReason,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = RP.PostId) AS CommentCount,
        MAX(V.CreationDate) AS LastVoteDate,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedLinksCount
    FROM RecentPosts RP
    LEFT JOIN UserReputation UR ON RP.OwnerUserId = UR.UserId
    LEFT JOIN PostHistory PH2 ON RP.PostId = PH2.PostId AND PH2.PostHistoryTypeId IN (10, 11) 
    LEFT JOIN Votes V ON RP.PostId = V.PostId
    LEFT JOIN PostLinks PL ON RP.PostId = PL.PostId
    WHERE RP.PostRank = 1 
    GROUP BY RP.PostId, UR.ReputationLevel, PH2.Comment
),
PostAnalytics AS (
    SELECT 
        PMD.PostId,
        PMD.ReputationLevel,
        PMD.CloseReason,
        PMD.CommentCount,
        PMD.LastVoteDate,
        PMD.VoteCount,
        PMD.RelatedLinksCount,
        CASE 
            WHEN PMD.CloseReason IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus,
        CASE 
            WHEN PMD.CommentCount = 0 THEN 'No comments'
            WHEN PMD.CommentCount BETWEEN 1 AND 5 THEN 'Few comments'
            ELSE 'Many comments'
        END AS CommentStatus,
        CASE 
            WHEN PMD.VoteCount < 0 THEN 'Nega-voted'
            WHEN PMD.VoteCount = 0 THEN 'Neutral'
            WHEN PMD.VoteCount > 0 THEN 'Posi-voted'
        END AS VoteStatus
    FROM PostMetaData PMD
)
SELECT 
    PA.PostId,
    PA.ReputationLevel,
    PA.CloseReason,
    PA.CommentCount,
    PA.LastVoteDate,
    PA.VoteCount,
    PA.RelatedLinksCount,
    PA.PostStatus,
    PA.CommentStatus,
    PA.VoteStatus
FROM PostAnalytics PA
WHERE PA.ReputationLevel <> 'No reputation'
AND PA.PostStatus = 'Active'
AND PA.CommentCount > 2
ORDER BY PA.VoteCount DESC, PA.CommentCount DESC;