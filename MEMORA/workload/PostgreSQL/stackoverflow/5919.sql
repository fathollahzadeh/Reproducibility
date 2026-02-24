
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
        LEFT JOIN Comments c ON c.PostId = p.Id
        LEFT JOIN Votes v ON v.PostId = p.Id
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
        LEFT JOIN (SELECT UNNEST(string_to_array(p.Tags, '<>')) AS TagName) AS t ON TRUE
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.LastActivityDate, p.OwnerUserId, 
        u.DisplayName, pt.Name
),
RankedPosts AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        PostStats
)
SELECT 
    PostId,
    Title,
    Score,
    ViewCount,
    CommentCount,
    UpVotes,
    DownVotes,
    CreationDate,
    LastActivityDate,
    OwnerUserId,
    OwnerDisplayName,
    PostType,
    Tags
FROM 
    RankedPosts
WHERE 
    Rank <= 10
ORDER BY 
    Score DESC, ViewCount DESC;
