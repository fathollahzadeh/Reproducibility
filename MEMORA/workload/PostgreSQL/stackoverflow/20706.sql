WITH UserVoteCounts AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN VoteTypeId IN (2, 3) THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN VoteTypeId = 4 THEN 1 END) AS OffensiveVoteCount,
        COUNT(CASE WHEN VoteTypeId = 10 THEN 1 END) AS DeleteVoteCount
    FROM Votes
    GROUP BY UserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UC.UpVoteCount, 0) AS UpVotes,
        COALESCE(UC.OffensiveVoteCount, 0) AS OffensiveVotes,
        COALESCE(UC.DeleteVoteCount, 0) AS DeleteVotes
    FROM Users U
    LEFT JOIN UserVoteCounts UC ON U.Id = UC.UserId
)
SELECT 
    A.OwnerUserId,
    A.Title AS AnswerTitle,
    A.Id AS AnswerId,
    COALESCE(UP.UpVotes, 0) AS UserUpVotes,
    COALESCE(UP.OffensiveVotes, 0) AS UserOffensiveVotes,
    COALESCE(UP.DeleteVotes, 0) AS UserDeleteVotes,
    T.TagName,
    COUNT(DISTINCT C.Id) AS CommentCount,
    COUNT(DISTINCT PH.Id) AS HistoryChanges
FROM Posts A
JOIN Posts Q ON A.ParentId = Q.Id
LEFT JOIN Comments C ON C.PostId = A.Id
LEFT JOIN PostHistory PH ON PH.PostId = A.Id
JOIN (
    SELECT 
        T.Id, 
        T.TagName, 
        P.Id AS PostId
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
) T ON T.PostId = Q.Id
LEFT JOIN TopUsers UP ON UP.UserId = A.OwnerUserId
WHERE A.PostTypeId = 2 
  AND Q.PostTypeId = 1 
  AND EXISTS (
      SELECT 1
      FROM Votes V
      WHERE V.PostId = Q.Id 
      AND V.VoteTypeId IN (2, 3) 
      HAVING COUNT(*) > 0
  )
GROUP BY 
    A.OwnerUserId, A.Title, A.Id, T.TagName, UP.UpVotes, UP.OffensiveVotes, UP.DeleteVotes
HAVING 
    COUNT(DISTINCT C.Id) > 5
    OR SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) > 2
ORDER BY 
    UserUpVotes DESC,
    CommentCount DESC,
    HistoryChanges DESC;