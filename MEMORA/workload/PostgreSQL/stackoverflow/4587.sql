
WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
), RecentPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.OwnerUserId, 
           COALESCE(COUNT(c.Id), 0) AS CommentCount, 
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount, 
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
), AcceptedAnswers AS (
    SELECT p.Id AS AnswerId, p.AcceptedAnswerId, 
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 2
    GROUP BY p.Id, p.AcceptedAnswerId
), PostLinksSummary AS (
    SELECT pl.PostId, 
           COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
           SUM(CASE WHEN lt.Name = 'Duplicate' THEN 1 ELSE 0 END) AS DuplicateCount
    FROM PostLinks pl
    JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY pl.PostId
)
SELECT u.DisplayName, 
       u.Reputation, 
       rp.Title, 
       rp.CreationDate, 
       rp.CommentCount, 
       rp.UpvoteCount, 
       rp.DownvoteCount, 
       aa.TotalUpvotes AS AcceptedAnswerUpvotes,
       pls.RelatedPostCount,
       pls.DuplicateCount
FROM UserReputation u
JOIN RecentPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN AcceptedAnswers aa ON aa.AcceptedAnswerId = rp.PostId
LEFT JOIN PostLinksSummary pls ON pls.PostId = rp.PostId
WHERE u.Reputation > 1000 AND 
      (rp.UpvoteCount - rp.DownvoteCount) > 10
ORDER BY u.Reputation DESC, rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
