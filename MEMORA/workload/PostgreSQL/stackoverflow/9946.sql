WITH UserBadges AS (
    SELECT U.Id AS UserId, U.DisplayName, COUNT(B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostDetails AS (
    SELECT P.Id AS PostId, P.Title, P.OwnerUserId, P.PostTypeId, P.CreationDate, P.AcceptedAnswerId,
           COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS UpVotes,
           COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3), 0) AS DownVotes,
           COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
           COALESCE(P.AcceptedAnswerId IS NOT NULL, False) AS HasAcceptedAnswer
    FROM Posts P
)
SELECT U.DisplayName AS UserName, U.Reputation, UB.TotalBadges, 
       PD.Title, PD.UpVotes, PD.DownVotes, PD.CommentCount,
       PD.HasAcceptedAnswer, PD.CreationDate
FROM UserBadges UB
JOIN Users U ON UB.UserId = U.Id
JOIN PostDetails PD ON U.Id = PD.OwnerUserId
WHERE U.Reputation > 1000 AND PD.PostTypeId = 1
ORDER BY UB.TotalBadges DESC, PD.UpVotes - PD.DownVotes DESC
LIMIT 10;
