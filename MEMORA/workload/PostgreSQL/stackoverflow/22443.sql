
WITH PostStats AS (
    SELECT p.Id AS PostId,
           p.OwnerUserId,
           COUNT(DISTINCT c.Id) AS CommentCount,
           COUNT(DISTINCT v.Id) AS VoteCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
           MAX(ph.CreationDate) AS LastHistoryDate,
           ARRAY_AGG(DISTINCT t.TagName) AS TagsList
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN UNNEST(string_to_array(p.Tags, ',')) AS t(TagName) ON TRUE
    WHERE p.CreationDate > '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId
),
UserStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COALESCE(MAX(ps.CommentCount), 0) AS TotalComments,
           COALESCE(SUM(ps.UpVoteCount), 0) AS TotalUpVotes,
           COALESCE(SUM(ps.DownVoteCount), 0) AS TotalDownVotes,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 50
    GROUP BY u.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT ps.PostId,
           ps.OwnerUserId,
           ps.LastHistoryDate,
           ps.TagsList,
           ROW_NUMBER() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.CommentCount DESC) AS RankByComments
    FROM PostStats ps
    WHERE ps.VoteCount > 10
),
UserRanked AS (
    SELECT us.UserId,
           us.DisplayName,
           us.TotalComments,
           us.TotalUpVotes,
           us.TotalDownVotes,
           ROW_NUMBER() OVER (ORDER BY us.TotalComments DESC) AS UserRank
    FROM UserStats us
)
SELECT ur.UserId,
       ur.DisplayName,
       ur.TotalComments,
       ur.TotalUpVotes,
       ur.TotalDownVotes,
       fp.PostId,
       fp.TagsList,
       fp.LastHistoryDate
FROM UserRanked ur
LEFT JOIN FilteredPosts fp ON ur.UserId = fp.OwnerUserId
WHERE (ur.TotalComments > 0 OR ur.TotalUpVotes > 0)
  AND (fp.RankByComments <= 5 OR fp.LastHistoryDate IS NULL)
ORDER BY ur.UserRank, fp.LastHistoryDate DESC NULLS LAST;
