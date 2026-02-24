
WITH TopUsers AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    WHERE U.Reputation IS NOT NULL
),
PostStatistics AS (
    SELECT P.Id AS PostId,
           P.OwnerUserId,
           P.PostTypeId,
           COUNT(C.Id) AS CommentCount,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
           COUNT(DISTINCT L.RelatedPostId) AS LinkCount,
           MAX(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS IsClosed
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostLinks L ON P.Id = L.PostId
    WHERE P.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
    GROUP BY P.Id, P.OwnerUserId, P.PostTypeId
),
UserPerformance AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           SUM(CASE WHEN P.OwnerUserId = U.Id THEN 1 ELSE 0 END) AS PostsCreated,
           SUM(COALESCE(P.CommentCount, 0)) AS TotalComments,
           SUM(COALESCE(P.Upvotes, 0)) - SUM(COALESCE(P.Downvotes, 0)) AS NetVotes,
           AVG(COALESCE(P.LinkCount, 0)) AS AvgLinksPerPost,
           MAX(COALESCE(P.IsClosed, 0)) AS HasClosedPosts
    FROM Users U
    LEFT JOIN PostStatistics P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
BadgeStats AS (
    SELECT B.UserId,
           COUNT(*) FILTER (WHERE B.Class = 1) AS GoldBadges,
           COUNT(*) FILTER (WHERE B.Class = 2) AS SilverBadges,
           COUNT(*) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
FinalStats AS (
    SELECT UP.UserId,
           UP.DisplayName,
           UP.PostsCreated,
           COALESCE(UP.TotalComments, 0) AS TotalComments,
           COALESCE(UP.NetVotes, 0) AS NetVotes,
           COALESCE(UP.AvgLinksPerPost, 0) AS AvgLinksPerPost,
           COALESCE(BS.GoldBadges, 0) AS GoldBadges,
           COALESCE(BS.SilverBadges, 0) AS SilverBadges,
           COALESCE(BS.BronzeBadges, 0) AS BronzeBadges,
           RANK() OVER (ORDER BY UP.TotalComments DESC, UP.NetVotes DESC) AS UserRank
    FROM UserPerformance UP
    LEFT JOIN BadgeStats BS ON UP.UserId = BS.UserId
    WHERE UP.NetVotes IS NOT NULL OR UP.TotalComments IS NOT NULL
)
SELECT FS.UserId,
       FS.DisplayName,
       FS.PostsCreated,
       FS.TotalComments,
       FS.NetVotes,
       FS.AvgLinksPerPost,
       FS.GoldBadges,
       FS.SilverBadges,
       FS.BronzeBadges,
       FS.UserRank,
       CASE 
           WHEN FS.TotalComments = 0 THEN 'No Comments'
           WHEN FS.UserRank <= 10 THEN 'Top Commenter'
           WHEN FS.PostsCreated > 100 THEN 'Veteran Contributor'
           ELSE 'Regular User'
       END AS UserCategory
FROM FinalStats FS
WHERE FS.UserRank <= 20 OR FS.GoldBadges > 0
ORDER BY FS.UserRank;
