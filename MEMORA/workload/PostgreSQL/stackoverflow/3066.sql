
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation > 1000 
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Views
),
PopularPostTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS TagRank
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 5
),
PostHistoryDetail AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        P.Title,
        PH.PostHistoryTypeId,
        COALESCE(PH.Text, 'No change') AS ChangeDescription
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.CommentCount,
    U.Reputation,
    U.ReputationRank,
    PHT.PostId,
    PHT.Title,
    PHT.UserId AS EditorId,
    PHT.CreationDate AS EditDate,
    PHT.ChangeDescription,
    PGT.TagName
FROM UserStats U
JOIN PostHistoryDetail PHT ON U.UserId = PHT.UserId
LEFT JOIN PopularPostTags PGT ON PHT.PostId IN (
    SELECT Id FROM Posts WHERE Tags LIKE CONCAT('%', PGT.TagName, '%')
)
WHERE U.Views > 1000
ORDER BY U.Reputation DESC, PHT.CreationDate DESC
LIMIT 50;
