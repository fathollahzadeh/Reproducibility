WITH UserBadges AS (
    SELECT U.Id AS UserId, U.DisplayName, COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT P.Id AS PostId, P.Title, P.OwnerUserId, P.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostDetails AS (
    SELECT R.PostId, R.Title, U.DisplayName AS OwnerName, 
           R.CreationDate, UB.BadgeCount
    FROM RecentPosts R
    JOIN Users U ON R.OwnerUserId = U.Id
    JOIN UserBadges UB ON U.Id = UB.UserId
    WHERE R.rn = 1
),
PostVoteDetails AS (
    SELECT PD.PostId, PD.Title, PD.OwnerName, PD.CreationDate,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM PostDetails PD
    LEFT JOIN Votes V ON PD.PostId = V.PostId
    GROUP BY PD.PostId, PD.Title, PD.OwnerName, PD.CreationDate
)
SELECT PDT.PostId, PDT.Title, PDT.OwnerName, PDT.CreationDate,
       PDT.UpVotes, PDT.DownVotes, 
       CASE 
           WHEN PDT.UpVotes > PDT.DownVotes THEN 'Positive' 
           WHEN PDT.UpVotes < PDT.DownVotes THEN 'Negative' 
           ELSE 'Neutral' 
       END AS Sentiment,
       (SELECT STRING_AGG(Name, ', ') 
        FROM PostHistory PH 
        JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id 
        WHERE PH.PostId = PDT.PostId) AS HistoryTypes
FROM PostVoteDetails PDT
ORDER BY PDT.CreationDate DESC
LIMIT 50;