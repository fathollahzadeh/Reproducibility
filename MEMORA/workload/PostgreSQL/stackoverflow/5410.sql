WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
           ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1
), AnswerStatistics AS (
    SELECT p.Id AS QuestionId, COUNT(a.Id) AS TotalAnswers, 
           COALESCE(SUM(a.Score), 0) AS TotalAnswerScore
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id
), VoteCounts AS (
    SELECT p.Id AS PostId, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId IN (1, 2)
    GROUP BY p.Id
)
SELECT rp.Title, 
       rp.CreationDate, 
       rp.Score, 
       rp.ViewCount, 
       asw.TotalAnswers, 
       asw.TotalAnswerScore, 
       vc.UpvoteCount, 
       vc.DownvoteCount
FROM RankedPosts rp
JOIN AnswerStatistics asw ON rp.Id = asw.QuestionId
JOIN VoteCounts vc ON rp.Id = vc.PostId
WHERE rp.rn = 1
ORDER BY rp.Score DESC, rp.ViewCount DESC;
