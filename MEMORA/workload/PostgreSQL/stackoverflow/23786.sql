
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        CASE
            WHEN U.Reputation >= 10000 THEN 'High Reputation'
            WHEN U.Reputation BETWEEN 5000 AND 9999 THEN 'Medium Reputation'
            WHEN U.Reputation BETWEEN 0 AND 4999 THEN 'Low Reputation'
            ELSE 'Negative Reputation'
        END AS ReputationCategory
    FROM Users U
),
QuestionVotes AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.PostTypeId = 1
    GROUP BY P.Id
),
QuestionStatistics AS (
    SELECT 
        Q.PostId,
        Q.UpVotes,
        Q.DownVotes,
        U.DisplayName,
        U.Reputation,
        R.ReputationCategory,
        ROW_NUMBER() OVER (ORDER BY Q.UpVotes DESC) AS Rank,
        MAX(PH.PostHistoryTypeId) AS CloseCount
    FROM QuestionVotes Q
    JOIN Users U ON Q.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id AND P.PostTypeId = 1)
    JOIN UserReputation R ON U.Id = R.UserId
    LEFT JOIN PostHistory PH ON Q.PostId = PH.PostId AND PH.PostHistoryTypeId IN (10, 11)
    GROUP BY Q.PostId, Q.UpVotes, Q.DownVotes, U.DisplayName, U.Reputation, R.ReputationCategory
)
SELECT 
    QS.PostId,
    QS.DisplayName,
    QS.UpVotes,
    QS.DownVotes,
    QS.ReputationCategory,
    CASE 
        WHEN QS.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN QS.ReputationCategory = 'High Reputation' AND QS.UpVotes > 50 THEN 'Prominent Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorStatus
FROM QuestionStatistics QS
WHERE QS.Rank <= 10
ORDER BY QS.UpVotes DESC, QS.Reputation DESC
LIMIT 20;
