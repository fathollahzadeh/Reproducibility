WITH TagFilter AS (
    SELECT DISTINCT
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        p.Id AS PostId
    FROM Posts p
    WHERE PostTypeId = 1 
),
PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(COUNT(DISTINCT a.Id), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId 
        AND a.PostTypeId = 2 
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.ViewCount
),
RankedPosts AS (
    SELECT 
        pm.*,
        ROW_NUMBER() OVER (ORDER BY pm.UpVotes - pm.DownVotes DESC, pm.ViewCount DESC) AS RankPosition
    FROM PostMetrics pm
)
SELECT 
    p.Title,
    p.ViewCount,
    p.CommentCount,
    p.AnswerCount,
    p.UpVotes,
    p.DownVotes,
    tg.TagName
FROM RankedPosts p
JOIN TagFilter tg ON p.PostId = tg.PostId
WHERE p.RankPosition <= 10
ORDER BY p.RankPosition, tg.TagName;