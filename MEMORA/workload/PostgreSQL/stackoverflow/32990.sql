
WITH RecursivePostHistory AS (
    SELECT PH.PostId, 
           PH.UserId AS EditorId, 
           PH.CreationDate AS EditDate, 
           PH.Comment, 
           ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EditRank
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6, 10, 11) 
),
UserVoteSummary AS (
    SELECT V.PostId, 
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY V.PostId
),
PostDetails AS (
    SELECT P.Id AS PostId, 
           P.Title, 
           U.DisplayName AS AuthorName, 
           COALESCE(PH.EditCount, 0) AS EditCount,
           COALESCE(VS.UpVotes, 0) AS UpVotes,
           COALESCE(VS.DownVotes, 0) AS DownVotes,
           COUNT(COALESCE(C.Id, 0)) AS CommentCount
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS EditCount
        FROM RecursivePostHistory
        GROUP BY PostId
    ) PH ON P.Id = PH.PostId
    LEFT JOIN UserVoteSummary VS ON P.Id = VS.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year' 
    GROUP BY P.Id, U.DisplayName, PH.EditCount, VS.UpVotes, VS.DownVotes
),
RankedPosts AS (
    SELECT PD.*, 
           RANK() OVER (ORDER BY PD.EditCount DESC, PD.UpVotes - PD.DownVotes DESC) AS PostRank
    FROM PostDetails PD
)
SELECT RP.PostId,
       RP.Title,
       RP.AuthorName,
       RP.EditCount,
       RP.UpVotes,
       RP.DownVotes,
       RP.CommentCount,
       RP.PostRank
FROM RankedPosts RP
WHERE RP.PostRank <= 10 
ORDER BY RP.EditCount DESC, RP.UpVotes - RP.DownVotes DESC;
