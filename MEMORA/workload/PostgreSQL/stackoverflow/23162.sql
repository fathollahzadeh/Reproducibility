
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COALESCE(NULLIF(p.Body, ''), '[Empty]') AS BodySnippet, 
        STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
    FROM Posts p
    LEFT JOIN Tags t ON t.ExcerptPostId = p.Id
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '365 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), UserVoteInfo AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 6 THEN 1 END) AS CloseVotes
    FROM Votes v
    GROUP BY v.PostId
), UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END), 0) AS ClosedPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostHistory PH ON p.Id = PH.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
)
SELECT
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.BodySnippet,
    rp.ViewCount,
    COALESCE(uvi.UpVotes, 0) AS UpVotes,
    COALESCE(uvi.DownVotes, 0) AS DownVotes,
    COALESCE(uvi.CloseVotes, 0) AS CloseVotes,
    rp.RelatedTags,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.ClosedPosts
FROM RankedPosts rp
JOIN UserPostStats ups ON rp.PostId = ups.UserId 
LEFT JOIN UserVoteInfo uvi ON rp.PostId = uvi.PostId
WHERE (ups.Reputation > 100 OR ups.QuestionCount > 5) 
  AND EXISTS (
      SELECT 1
      FROM Comments c
      WHERE c.PostId = rp.PostId
      AND c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
  )
ORDER BY ups.Reputation DESC, rp.Score DESC;
