
WITH RankedPosts AS (
    SELECT
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN LATERAL (
        SELECT UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '>')) AS TagName
    ) t ON true
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.Score, u.DisplayName
),
TopQuestions AS (
    SELECT
        p.PostID,
        p.Title,
        p.OwnerDisplayName,
        p.Score,
        p.CommentCount,
        p.Tags
    FROM RankedPosts p
    WHERE p.Rank <= 10  
),
VoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
)
SELECT 
    tq.Title,
    tq.OwnerDisplayName,
    tq.Score,
    tq.CommentCount,
    tq.Tags,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes
FROM TopQuestions tq
LEFT JOIN VoteStats vs ON tq.PostID = vs.PostId
ORDER BY tq.Score DESC;
