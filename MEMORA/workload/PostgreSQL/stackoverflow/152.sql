WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.ViewCount, p.Score
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation, u.DisplayName
    FROM Users u
    WHERE u.Reputation > 1000
),
PostsWithTags AS (
    SELECT p.Id, p.Title, array_length(string_to_array(p.Tags, '>'), 1) AS TagCount
    FROM Posts p
    WHERE p.Tags IS NOT NULL
),
TopAnswers AS (
    SELECT pa.Id AS PostId, COUNT(v.Id) AS VoteCount
    FROM Posts pa
    JOIN Votes v ON pa.Id = v.PostId
    WHERE pa.PostTypeId = 2
    GROUP BY pa.Id
    HAVING COUNT(v.Id) > 5
),
ClosedPosts AS (
    SELECT ph.PostId, COUNT(ph.Id) AS ClosureCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT rp.Title,
       ur.DisplayName AS Owner,
       rp.ViewCount,
       rp.Score,
       pt.TagCount,
       COALESCE(cl.ClosureCount, 0) AS ClosureCount,
       ta.VoteCount AS TopAnswerVoteCount
FROM RecentPosts rp
LEFT JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN PostsWithTags pt ON rp.Id = pt.Id
LEFT JOIN ClosedPosts cl ON rp.Id = cl.PostId
LEFT JOIN TopAnswers ta ON rp.Id = ta.PostId
WHERE (pt.TagCount > 3 OR rp.ViewCount > 100)
  AND (ta.VoteCount IS NOT NULL OR rp.Score > 10)
  AND rp.CreationDate < cast('2024-10-01' as date) - INTERVAL '1 week'
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 100;