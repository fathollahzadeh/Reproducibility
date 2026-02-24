
WITH UserVoteStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
           COUNT(v.Id) AS TotalVotesCount,
           COALESCE((SELECT COUNT(DISTINCT b.Id)
                     FROM Badges b 
                     WHERE b.UserId = u.Id AND b.Class = 1), 0) AS GoldBadges,
           COALESCE((SELECT COUNT(DISTINCT b.Id)
                     FROM Badges b 
                     WHERE b.UserId = u.Id AND b.Class = 2), 0) AS SilverBadges,
           COALESCE((SELECT COUNT(DISTINCT b.Id)
                     FROM Badges b 
                     WHERE b.UserId = u.Id AND b.Class = 3), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostActivityStats AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.OwnerUserId,
           p.Score,
           COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
           COALESCE(MAX(v.CreationDate), DATE '1900-01-01') AS LastVoteDate,
           DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.Score
),
FinalBenchmark AS (
    SELECT uvs.UserId,
           uvs.DisplayName,
           uvs.UpVotesCount,
           uvs.DownVotesCount,
           uvs.TotalVotesCount,
           uvs.GoldBadges,
           uvs.SilverBadges,
           uvs.BronzeBadges,
           pas.PostId,
           pas.Title AS PostTitle,
           pas.Score AS PostScore,
           pas.CommentCount,
           (CASE 
                WHEN pas.LastVoteDate < (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year') THEN 'Inactive'
                WHEN pas.RecentPostRank <= 5 THEN 'Active Top Contributor'
                ELSE 'Occasionally Active'
            END) AS UserPostActivityStatus
    FROM UserVoteStats uvs
    LEFT JOIN PostActivityStats pas ON uvs.UserId = pas.OwnerUserId
    WHERE uvs.TotalVotesCount > 0 
      AND (uvs.GoldBadges + uvs.SilverBadges + uvs.BronzeBadges) > 0
    ORDER BY uvs.UpVotesCount DESC, uvs.TotalVotesCount DESC
)
SELECT *,
       (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
        FROM UNNEST(string_to_array(p.Tags, '><')) AS tag
        LEFT JOIN Tags t ON t.TagName = tag
        WHERE t.IsModeratorOnly IS FALSE) AS RelevantTags
FROM FinalBenchmark fb
JOIN Posts p ON fb.PostId = p.Id
WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
  AND (p.Title IS NOT NULL AND p.Title != '')
  AND (fb.UserPostActivityStatus = 'Active Top Contributor' OR fb.UserPostActivityStatus = 'Occasionally Active')
ORDER BY fb.UserPostActivityStatus, fb.PostScore DESC;
