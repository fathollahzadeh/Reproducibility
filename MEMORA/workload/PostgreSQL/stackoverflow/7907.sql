
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN LATERAL unnest(string_to_array(p.Tags, '><')) AS tag_name ON TRUE
    LEFT JOIN Tags t ON tag_name = t.TagName
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, u.DisplayName, pt.Name
),
TopRankedPosts AS (
    SELECT * FROM RankedPosts WHERE Rank <= 5
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    trp.AnswerCount,
    trp.CommentCount,
    trp.FavoriteCount,
    trp.OwnerDisplayName,
    ua.DisplayName AS UserName,
    ua.TotalVotes,
    ua.UpVotes,
    ua.DownVotes,
    trp.Tags
FROM TopRankedPosts trp
JOIN UserActivity ua ON ua.UserId IN (
    SELECT OwnerUserId FROM Posts WHERE Id = trp.PostId
)
ORDER BY trp.Score DESC, trp.CreationDate DESC;
