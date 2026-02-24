
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN unnest(string_to_array(p.Tags, '><')) AS t(TagName) ON TRUE
    WHERE p.PostTypeId = 1
    AND p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT b.Id) AS BadgesCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        ps.*,
        ur.DisplayName AS OwnerDisplayName,
        ur.TotalScore,
        ur.PostsCount,
        ur.BadgesCount
    FROM PostStats ps
    JOIN UserRankings ur ON ps.PostId = ur.UserId
    ORDER BY ps.Score DESC
    LIMIT 10
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    UpVotes,
    DownVotes,
    Tags,
    OwnerDisplayName,
    TotalScore,
    PostsCount,
    BadgesCount
FROM TopPosts
ORDER BY Score DESC, CreationDate ASC;
